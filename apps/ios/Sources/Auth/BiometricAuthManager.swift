import Foundation
import LocalAuthentication
import Observation

@MainActor
@Observable
final class BiometricAuthManager {
    private(set) var isAuthenticated = false
    private(set) var biometricType: LABiometryType = .none
    private(set) var authError: String?

    private let context = LAContext()

    init() {
        self.checkBiometricAvailability()
    }

    var isBiometricEnabled: Bool {
        get {
            UserDefaults.standard.bool(forKey: "biometric.enabled")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "biometric.enabled")
        }
    }

    var biometricDisplayName: String {
        switch self.biometricType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        case .opticID:
            return "Optic ID"
        case .none:
            return "Biometric"
        @unknown default:
            return "Biometric"
        }
    }

    private func checkBiometricAvailability() {
        var error: NSError?
        let canEvaluate = self.context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)

        if canEvaluate {
            self.biometricType = self.context.biometryType
        } else {
            self.biometricType = .none
        }
    }

    func authenticate() async {
        self.authError = nil

        guard self.isBiometricEnabled else {
            self.isAuthenticated = true
            return
        }

        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            if let error {
                self.authError = error.localizedDescription
            }
            await self.fallbackToPasscode()
            return
        }

        let reason = "Unlock OpenClaw"

        do {
            let success = try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)
            if success {
                self.isAuthenticated = true
            }
        } catch let error as LAError {
            switch error.code {
            case .userFallback, .biometryNotAvailable:
                await self.fallbackToPasscode()
            case .userCancel:
                self.authError = "Authentication cancelled"
            default:
                self.authError = error.localizedDescription
            }
        } catch {
            self.authError = error.localizedDescription
        }
    }

    private func fallbackToPasscode() async {
        let context = LAContext()
        let reason = "Unlock OpenClaw with passcode"

        do {
            let success = try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
            if success {
                self.isAuthenticated = true
            }
        } catch {
            self.authError = error.localizedDescription
        }
    }

    func resetAuthentication() {
        self.isAuthenticated = false
        self.authError = nil
    }
}
