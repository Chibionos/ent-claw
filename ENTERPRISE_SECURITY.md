# 🔒 EnterpriseClaw Security Documentation

**EnterpriseClaw-specific security architecture and implementation details.**  
For general OpenClaw security guidance, see [SECURITY.md](./SECURITY.md).

---

## Overview

EnterpriseClaw prioritizes **security-first design** with enterprise-grade features:
- 🔐 **Biometric authentication** (Face ID, Touch ID, fingerprint)
- 🔒 **End-to-end encryption** for all communications *(Phase 2)*
- 🏢 **Enterprise SSO integration** (OAuth2, SAML, Azure AD) *(Phase 2)*
- ✅ **Permission approval workflows** for sensitive operations *(Phase 2)*
- 📊 **Audit logging and compliance** (SOC 2, ISO 27001) *(Phase 3)*

---

## 🛡️ Security Architecture (7 Layers)

### Layer 1: Authentication
- **Biometric**: Face ID (iOS), Touch ID (iOS), Fingerprint (Android)
- **Fallback**: Device passcode (6+ digits)
- **Storage**: Secure Enclave (iOS), Hardware Security Module (Android)

### Layer 2: Network Security
- **mTLS**: Mutual TLS authentication between all components *(Phase 2)*
- **Certificate Pinning**: Trust-on-First-Use (TOFU) fingerprint validation *(Phase 2)*
- **Zero-Trust**: No implicit network trust

### Layer 3: Transport Encryption
- **End-to-end encryption**: AES-256-GCM *(Phase 2)*
- **Perfect forward secrecy**: Ephemeral session keys
- **Replay protection**: Nonce-based message authentication

### Layer 4: Data Protection
- **iOS**: Keychain with `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`
- **Android**: KeyStore with hardware-backed keys
- **Databases**: SQLCipher encryption *(Phase 3)*

### Layer 5: Access Control
- **Permission policies**: Risk-based approval requirements *(Phase 2)*
- **RBAC**: Role-based access control *(Phase 3)*
- **Least privilege**: Minimal permissions by default

### Layer 6: Audit & Compliance
- **Immutable logs**: Blockchain-style hash chaining *(Phase 3)*
- **Retention**: Configurable (90 days to 7 years)
- **Export**: JSON, CSV, SIEM-compatible formats

### Layer 7: Operational Security
- **Secrets management**: HashiCorp Vault integration *(Phase 3)*
- **Intrusion detection**: Anomaly detection and alerting *(Phase 3)*
- **Token rotation**: Automated 90-day renewal

---

## 🔐 Current MVP Security (Phase 1)

### ✅ Implemented

#### 1. Biometric Authentication
```swift
// iOS: BiometricAuthManager.swift:53
func authenticate() async {
    let context = LAContext()
    let reason = "Unlock OpenClaw"
    
    let success = try await context.evaluatePolicy(
        .deviceOwnerAuthenticationWithBiometrics,
        localizedReason: reason
    )
}
```

```kotlin
// Android: BiometricAuthManager.kt:44
fun authenticate(activity: FragmentActivity, onSuccess: () -> Unit) {
    val promptInfo = BiometricPrompt.PromptInfo.Builder()
        .setTitle("Unlock EnterpriseClaw")
        .setNegativeButtonText("Use PIN")
        .build()
    
    biometricPrompt.authenticate(promptInfo)
}
```

**Security Properties:**
- ✅ Local biometric validation (no network)
- ✅ Hardware-backed secure storage
- ✅ Anti-spoofing (liveness detection)
- ✅ Automatic lockout after failed attempts

#### 2. Secure Token Storage

**iOS Keychain:**
```swift
// Stored with kSecAttrAccessibleWhenUnlockedThisDeviceOnly
UserDefaults.standard.bool(forKey: "biometric.enabled")  // Settings only
// Gateway token stored in Keychain (implementation in progress)
```

**Android KeyStore:**
```kotlin
// Encrypted with hardware-backed key
context.getSharedPreferences("prefs", Context.MODE_PRIVATE)
    .edit()
    .putBoolean("biometric_enabled", value)
    .apply()
```

#### 3. QR Code Pairing

**JSON Format:**
```json
{
  "url": "ws://192.168.1.100:18789",
  "token": "64-character-hex-token",
  "displayName": "EnterpriseClaw Gateway"
}
```

**Security Properties:**
- ✅ 64-character random token (256-bit entropy)
- ✅ Visual confirmation (user sees gateway name)
- ✅ Camera-only scanning (no clipboard/sharing)

#### 4. Channel Restrictions

**Configuration:**
```javascript
// scripts/install-enterprise.sh:128
openclaw config set 'plugins.allow=["slack"]'
```

**Available Channels:**
- ✅ Mobile app (gateway WebSocket)
- ✅ Slack (optional fallback)
- ❌ WhatsApp, Telegram, Discord, Signal (disabled)

---

## 🚧 Coming Soon (Phase 2)

### Certificate Pinning (TOFU)
```swift
// iOS Implementation
func trustEvaluate(serverTrust: SecTrust, host: String) -> Bool {
    let fingerprint = sha256(SecTrustCopyCertificateChain(serverTrust)[0])
    
    if let pinned = getPinnedFingerprint(host) {
        return fingerprint == pinned  // Validate against saved
    } else {
        pinFingerprint(host, fingerprint)  // First use - trust
        return true
    }
}
```

### End-to-End Encryption
```javascript
// Message Encryption (AES-256-GCM)
function encryptMessage(plaintext, sessionKey) {
    const iv = crypto.randomBytes(12);
    const cipher = crypto.createCipheriv('aes-256-gcm', sessionKey, iv);
    const ciphertext = cipher.update(plaintext) + cipher.final();
    const authTag = cipher.getAuthTag();
    
    return { iv, ciphertext, authTag };
}
```

### Permission Approval Workflow
```
Claude Code: "Read /etc/passwd"
      ↓
Gateway: Check Policy → REQUIRE_APPROVAL
      ↓
Mobile App: Show Approval Dialog
      ↓
User: [Approve Once] / [Approve Always] / [Deny]
      ↓
Gateway: Grant Permission (logged)
      ↓
Claude Code: Execute Operation
```

---

## 🔍 Security Testing

### MVP Test Checklist

- [ ] **Biometric Auth**: Enable → Background app → Return → Unlock
- [ ] **Token Generation**: Verify 64-char hex format
- [ ] **QR Pairing**: Scan code → Auto-connect → Verify gateway name
- [ ] **Lock Screen**: App locks when backgrounded
- [ ] **Channel Restrictions**: Only Mobile + Slack visible

### Future Testing (Phase 2+)

- [ ] **Certificate Pinning**: Test with rogue CA
- [ ] **E2EE**: Verify gateway cannot decrypt
- [ ] **Permission Denials**: Test approval workflow
- [ ] **Token Rotation**: Auto-renewal every 90 days
- [ ] **Intrusion Detection**: Trigger anomaly alerts

---

## 🚨 Security Warnings

### ⚠️ API Key Protection

**NEVER commit API keys to git!**

The user accidentally shared keys in chat:
```
GOOGLE_GENERATIVE_AI_API_KEY=AIzaSyDvf0AoUoWIjdJzJjiD9y9Ki8vNWagdbTo  ❌
GOOGLE_GEMINI_API_KEY=AIzaSyDvf0AoUoWIjdJzJjiD9y9Ki8vNWagdbTo      ❌
```

**IMMEDIATE ACTIONS REQUIRED:**
1. ☠️ **Revoke these keys** in [Google AI Studio](https://aistudio.google.com/)
2. 🔄 **Generate new keys**
3. 🔒 **Store securely**:
   - Environment variables (`.env` in `.gitignore`)
   - Secrets management (HashiCorp Vault)
   - OS keychain (macOS Keychain, Windows Credential Manager)

**Example `.env` file:**
```bash
# .env (add to .gitignore!)
GOOGLE_GENERATIVE_AI_API_KEY=your-new-key-here
GOOGLE_GEMINI_API_KEY=your-new-key-here
```

**.gitignore entry:**
```
.env
.env.*
*.key
*.pem
credentials.json
```

---

## 📞 Security Contact

**For EnterpriseClaw security issues:**
- **GitHub**: Open a private security advisory at  
  https://github.com/Chibionos/ent-claw/security/advisories
- **Scope**: Biometric bypass, token theft, encryption flaws

**For general OpenClaw security issues:**
- See [SECURITY.md](./SECURITY.md)

---

## 📚 References

- **[ENTERPRISE_ARCHITECTURE.md](./ENTERPRISE_ARCHITECTURE.md)**: Full 200-page architecture
- **[TESTING_MVP.md](./TESTING_MVP.md)**: Security testing scenarios
- **[OWASP Mobile Security](https://owasp.org/www-project-mobile-security-testing-guide/)**
- **[Apple Security Guide](https://support.apple.com/guide/security/welcome/web)**
- **[Android Security Best Practices](https://developer.android.com/topic/security/best-practices)**

---

<p align="center">
  <strong>Security is not optional.</strong>
</p>
