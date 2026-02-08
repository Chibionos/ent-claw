import AVFoundation
import SwiftUI
import UIKit

struct QRScannerView: View {
    @Environment(GatewayConnectionController.self) private var gatewayController: GatewayConnectionController
    @Environment(\.dismiss) private var dismiss
    @State private var scannerController = QRScannerController()
    @State private var scannedConfig: GatewayQRConfig?
    @State private var scanError: String?
    @State private var isConnecting = false

    var body: some View {
        ZStack {
            QRScannerViewRepresentable(controller: self.scannerController)
                .ignoresSafeArea()

            VStack {
                HStack {
                    Button {
                        self.dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.white)
                            .shadow(radius: 4)
                    }
                    .padding()

                    Spacer()
                }

                Spacer()

                VStack(spacing: 16) {
                    Text("Scan Gateway QR Code")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .shadow(radius: 4)

                    if let error = self.scanError {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .padding()
                            .background(Color.black.opacity(0.6))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    if self.isConnecting {
                        HStack {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                            Text("Connecting...")
                                .foregroundStyle(.white)
                        }
                        .padding()
                        .background(Color.black.opacity(0.6))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding(.bottom, 100)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            Task { await self.scannerController.startScanning() }
        }
        .onDisappear {
            self.scannerController.stopScanning()
        }
        .onChange(of: self.scannerController.scannedCode) { _, newValue in
            if let code = newValue {
                self.handleScannedCode(code)
            }
        }
    }

    private func handleScannedCode(_ code: String) {
        self.scannerController.stopScanning()
        self.scanError = nil

        guard let data = code.data(using: .utf8) else {
            self.scanError = "Invalid QR code format"
            Task {
                try? await Task.sleep(for: .seconds(2))
                await self.scannerController.startScanning()
            }
            return
        }

        do {
            let config = try JSONDecoder().decode(GatewayQRConfig.self, from: data)
            self.scannedConfig = config
            Task { await self.connectToGateway(config) }
        } catch {
            self.scanError = "Invalid gateway configuration: \(error.localizedDescription)"
            Task {
                try? await Task.sleep(for: .seconds(2))
                await self.scannerController.startScanning()
            }
        }
    }

    private func connectToGateway(_ config: GatewayQRConfig) async {
        self.isConnecting = true
        defer { self.isConnecting = false }

        guard let url = URL(string: config.url) else {
            self.scanError = "Invalid gateway URL"
            return
        }

        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        guard let host = components?.host, let port = components?.port else {
            self.scanError = "Could not parse host and port from URL"
            return
        }

        let useTLS = components?.scheme == "wss"

        UserDefaults.standard.set(true, forKey: "gateway.manual.enabled")
        UserDefaults.standard.set(host, forKey: "gateway.manual.host")
        UserDefaults.standard.set(port, forKey: "gateway.manual.port")
        UserDefaults.standard.set(useTLS, forKey: "gateway.manual.tls")

        if let token = config.token {
            let instanceId = UserDefaults.standard.string(forKey: "node.instanceId")?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if !instanceId.isEmpty {
                GatewaySettingsStore.saveGatewayToken(token, instanceId: instanceId)
            }
        }

        await self.gatewayController.connectManual(host: host, port: port, useTLS: useTLS)

        try? await Task.sleep(for: .seconds(1))
        self.dismiss()
    }
}

struct GatewayQRConfig: Codable {
    let url: String
    let token: String?
    let displayName: String?
}

@MainActor
@Observable
final class QRScannerController: NSObject, AVCaptureMetadataOutputObjectsDelegate {
    private(set) var scannedCode: String?
    private(set) var permissionDenied = false

    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?

    func startScanning() async {
        self.scannedCode = nil
        self.permissionDenied = false

        let status = AVCaptureDevice.authorizationStatus(for: .video)
        if status == .denied || status == .restricted {
            self.permissionDenied = true
            return
        }

        if status == .notDetermined {
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            if !granted {
                self.permissionDenied = true
                return
            }
        }

        guard let device = AVCaptureDevice.default(for: .video) else { return }

        let session = AVCaptureSession()
        self.captureSession = session

        do {
            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input) {
                session.addInput(input)
            }

            let output = AVCaptureMetadataOutput()
            if session.canAddOutput(output) {
                session.addOutput(output)
                output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                output.metadataObjectTypes = [.qr]
            }

            Task.detached { [weak session] in
                session?.startRunning()
            }
        } catch {
            return
        }
    }

    func stopScanning() {
        Task.detached { [weak captureSession] in
            captureSession?.stopRunning()
        }
    }

    nonisolated func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection)
    {
        guard let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let stringValue = metadataObject.stringValue
        else { return }

        Task { @MainActor in
            self.scannedCode = stringValue
        }
    }

    func getPreviewLayer() -> AVCaptureVideoPreviewLayer? {
        guard let session = self.captureSession else { return nil }
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        self.previewLayer = layer
        return layer
    }
}

struct QRScannerViewRepresentable: UIViewRepresentable {
    let controller: QRScannerController

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black

        if let previewLayer = self.controller.getPreviewLayer() {
            previewLayer.frame = view.bounds
            view.layer.addSublayer(previewLayer)
        }

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if let previewLayer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            previewLayer.frame = uiView.bounds
        }
    }
}

#Preview {
    QRScannerView()
        .environment(GatewayConnectionController(appModel: NodeAppModel(), startDiscovery: false))
}
