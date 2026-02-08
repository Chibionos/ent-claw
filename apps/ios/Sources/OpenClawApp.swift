import SwiftUI

@main
struct OpenClawApp: App {
    @State private var appModel: NodeAppModel
    @State private var gatewayController: GatewayConnectionController
    @State private var biometricAuthManager = BiometricAuthManager()
    @Environment(\.scenePhase) private var scenePhase

    init() {
        GatewaySettingsStore.bootstrapPersistence()
        let appModel = NodeAppModel()
        _appModel = State(initialValue: appModel)
        _gatewayController = State(initialValue: GatewayConnectionController(appModel: appModel))
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                RootCanvas()
                    .environment(self.appModel)
                    .environment(self.appModel.voiceWake)
                    .environment(self.gatewayController)
                    .environment(self.biometricAuthManager)
                    .onOpenURL { url in
                        Task { await self.appModel.handleDeepLink(url: url) }
                    }
                    .onChange(of: self.scenePhase) { _, newValue in
                        self.appModel.setScenePhase(newValue)
                        self.gatewayController.setScenePhase(newValue)

                        if newValue == .active && self.biometricAuthManager.isBiometricEnabled {
                            self.biometricAuthManager.resetAuthentication()
                        }
                    }

                if !self.biometricAuthManager.isAuthenticated && self.biometricAuthManager.isBiometricEnabled {
                    BiometricLockScreen()
                        .environment(self.biometricAuthManager)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut, value: self.biometricAuthManager.isAuthenticated)
        }
    }
}
