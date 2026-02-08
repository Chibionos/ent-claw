import SwiftUI

struct BiometricLockScreen: View {
    @Environment(BiometricAuthManager.self) private var authManager: BiometricAuthManager

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                Image(systemName: self.biometricIcon)
                    .font(.system(size: 80))
                    .foregroundStyle(.white)

                VStack(spacing: 8) {
                    Text("OpenClaw")
                        .font(.title)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)

                    Text("Tap to unlock with \(self.authManager.biometricDisplayName)")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }

                if let error = self.authManager.authError {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Spacer()

                Button {
                    Task {
                        await self.authManager.authenticate()
                    }
                } label: {
                    HStack {
                        Image(systemName: self.biometricIcon)
                        Text("Unlock")
                    }
                    .font(.headline)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 60)
            }
        }
        .task {
            await self.authManager.authenticate()
        }
    }

    private var biometricIcon: String {
        switch self.authManager.biometricType {
        case .faceID:
            return "faceid"
        case .touchID:
            return "touchid"
        case .opticID:
            return "opticid"
        case .none:
            return "lock.fill"
        @unknown default:
            return "lock.fill"
        }
    }
}

#Preview {
    BiometricLockScreen()
        .environment(BiometricAuthManager())
}
