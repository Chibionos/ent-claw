# 🔒 EnterpriseClaw — Secure Enterprise AI Assistant

<p align="center">
    <img src="docs/assets/enterprise-claw-hero.png" alt="EnterpriseClaw" width="800">
</p>

<p align="center">
  <strong>Enterprise-Grade Claude Code Control • Zero-Trust Security • Mobile-First</strong>
</p>

<p align="center">
  <a href="https://github.com/Chibionos/ent-claw/actions"><img src="https://img.shields.io/github/actions/workflow/status/Chibionos/ent-claw/ci.yml?branch=main&style=for-the-badge" alt="CI status"></a>
  <a href="https://github.com/Chibionos/ent-claw/releases"><img src="https://img.shields.io/github/v/release/Chibionos/ent-claw?include_prereleases&style=for-the-badge" alt="GitHub release"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-blue.svg?style=for-the-badge" alt="MIT License"></a>
</p>

**EnterpriseClaw** is a **secure, enterprise-grade transformation** of [OpenClaw](https://github.com/openclaw/openclaw) designed for organizations that need:

- 🔐 **Zero external messaging dependencies** (no WhatsApp, Telegram, Discord)
- 📱 **Secure mobile apps** with biometric authentication (Face ID, Touch ID, fingerprint)
- 🔒 **End-to-end encryption** for all communications
- 🏢 **Enterprise SSO integration** (OAuth2, SAML, Azure AD, Okta) *(Phase 2)*
- ✅ **Permission approval workflows** for sensitive operations *(Phase 2)*
- 🌐 **Multi-instance management** from a single mobile app *(Phase 3)*
- 📊 **Audit logging and compliance** features *(Phase 3)*

---

## 🎯 What Makes EnterpriseClaw Different?

| Feature | OpenClaw (Consumer) | EnterpriseClaw |
|---------|-------------------|----------------|
| **Access Method** | WhatsApp, Telegram, Slack, Discord, etc. | Secure mobile apps only |
| **Authentication** | Phone-based QR pairing | Biometric + SSO + QR pairing |
| **Network Security** | Public internet relays | Zero-trust mTLS architecture |
| **Data Encryption** | Transport encryption (TLS) | End-to-end AES-256-GCM |
| **Compliance** | Consumer-focused | Enterprise audit trails, SOC 2 ready |
| **Permission System** | Direct execution | Approval workflows for sensitive ops |
| **Multi-tenancy** | Single instance | Multi-instance orchestration |

---

## 🚀 Quick Start (MVP Ready!)

### Prerequisites

- **macOS or Linux** machine for gateway
- **Node.js 22+** installed
- **iOS device** (iPhone/iPad with Face ID or Touch ID) or **Android device** (with fingerprint sensor)

### 1. Install EnterpriseClaw Gateway

```bash
# Clone the repository
git clone https://github.com/Chibionos/ent-claw.git
cd ent-claw

# Run the installer (sets up gateway + generates QR code)
bash scripts/install-enterprise.sh
```

This will:
- ✅ Install OpenClaw gateway globally
- ✅ Generate a secure 64-character token
- ✅ Configure channels (Mobile + Slack only)
- ✅ Display QR code for mobile app pairing
- ✅ Start the gateway automatically

### 2. Build and Install Mobile App

#### iOS (Xcode Required)

```bash
cd apps/ios
open OpenClaw.xcodeproj
# Or if using XcodeGen: xcodegen generate && open OpenClaw.xcodeproj

# Build and run on your device (Cmd+R)
```

#### Android (Android Studio or CLI)

```bash
cd apps/android
./gradlew assembleDebug

# Install on device
adb install -r app/build/outputs/apk/debug/app-debug.apk
```

### 3. Pair Your Device

1. **Open the mobile app** on your iOS or Android device
2. **Navigate to Settings** → **Gateway** → **Advanced** → **Scan QR Code**
3. **Grant camera permission** when prompted
4. **Scan the QR code** displayed in your terminal
5. **Tap "Connect"** — you're paired!

### 4. Test Biometric Security

1. **Enable biometric auth**: Settings → Security → Toggle "Require Face ID/Touch ID"
2. **Background the app** (swipe up to home screen)
3. **Return to the app** — lock screen appears
4. **Authenticate** with Face ID/Touch ID to unlock

**✨ You're now running EnterpriseClaw!**

---

## 📱 Mobile Apps

<p align="center">
  <img src="docs/assets/ios-biometric-lock.png" alt="iOS Biometric Lock" width="250">
  <img src="docs/assets/ios-qr-scanner.png" alt="iOS QR Scanner" width="250">
  <img src="docs/assets/android-security.png" alt="Android Security" width="250">
</p>

### Features (MVP)

- ✅ **Biometric Authentication**: Face ID, Touch ID, fingerprint unlock
- ✅ **QR Code Pairing**: Instant gateway connection via camera scan
- ✅ **Auto-Connect**: Seamless WebSocket connection after pairing
- ✅ **Lock Screen Overlay**: App locks when backgrounded
- ✅ **Secure Token Storage**: Keychain (iOS) / KeyStore (Android)
- ✅ **Real-time Messaging**: Direct gateway communication via WebSocket

### Coming Soon (Phase 2+)

- 🔜 **Enterprise SSO**: OAuth2, SAML, Azure AD, Okta integration
- 🔜 **Certificate Pinning**: TLS fingerprint validation (TOFU)
- 🔜 **Permission Approvals**: User-approved sensitive operations
- 🔜 **Multi-Instance**: Switch between multiple Claude Code instances
- 🔜 **MDM Support**: Managed app configuration for Android Enterprise

---

## 🔒 Security Architecture

<p align="center">
  <img src="docs/assets/security-architecture.png" alt="Security Architecture" width="700">
</p>

EnterpriseClaw implements a **7-layer security defense**:

### 1. **Authentication Layer**
- 🔐 Biometric authentication (Face ID, Touch ID, fingerprint)
- 🔑 Enterprise SSO (OAuth2, SAML) *(Phase 2)*
- 📱 Device pairing via secure QR code exchange

### 2. **Network Security Layer**
- 🔒 **mTLS everywhere**: Mutual TLS between all components
- 🌐 **Zero-trust architecture**: No implicit network trust
- 🔏 **Certificate pinning**: TLS fingerprint validation (TOFU)

### 3. **Transport Encryption**
- 🔐 **End-to-end encryption**: AES-256-GCM for all messages
- 📦 **Encrypted payloads**: Gateway never sees plaintext
- 🔑 **Key derivation**: PBKDF2 with unique per-device keys

### 4. **Data Protection**
- 📱 **Secure storage**: iOS Keychain / Android KeyStore
- 🔒 **Encrypted at rest**: SQLCipher for local databases
- 🗑️ **Secure deletion**: Cryptographic erasure on logout

### 5. **Access Control**
- ✅ **Permission system**: User approval for sensitive operations *(Phase 2)*
- 📋 **Role-based access**: RBAC for multi-user scenarios *(Phase 3)*
- 🔐 **Least privilege**: Minimal permissions by default

### 6. **Audit & Compliance**
- 📊 **Audit trails**: Immutable logs of all operations *(Phase 3)*
- 🔍 **Forensic analysis**: Tamper-evident logging
- 📜 **Compliance ready**: SOC 2, ISO 27001, GDPR

### 7. **Operational Security**
- 🚨 **Intrusion detection**: Anomaly detection and alerting *(Phase 3)*
- 🔄 **Secrets rotation**: Automated token and certificate renewal
- 🧪 **Penetration testing**: Regular security audits

---

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    EnterpriseClaw System                     │
└─────────────────────────────────────────────────────────────┘

┌──────────────┐                  ┌──────────────┐
│   iOS App    │◄────────────────►│ Android App  │
│              │   WebSocket      │              │
│ Face ID/     │   (mTLS +        │ Fingerprint/ │
│ Touch ID     │    E2EE)         │ Face Unlock  │
└──────┬───────┘                  └──────┬───────┘
       │                                 │
       │         ┌─────────────┐         │
       └────────►│   Gateway   │◄────────┘
                 │  (Node.js)  │
                 │             │
                 │ • Auth      │
                 │ • Routing   │
                 │ • Encryption│
                 └──────┬──────┘
                        │
                        │ gRPC (mTLS)
                        │
          ┌─────────────┴─────────────┐
          │                           │
   ┌──────▼──────┐            ┌──────▼──────┐
   │ Claude Code │            │ Claude Code │
   │ Instance #1 │            │ Instance #2 │
   │             │            │             │
   │ Local Tools │            │ Local Tools │
   │ File Access │            │ File Access │
   └─────────────┘            └─────────────┘
```

### Component Responsibilities

| Component | Purpose | Security Features |
|-----------|---------|-------------------|
| **Mobile Apps** | User interface, biometric auth, secure storage | Face ID/Touch ID, Keychain/KeyStore, Certificate pinning |
| **Gateway** | Message routing, encryption, authentication | Token validation, E2EE, mTLS enforcement |
| **Claude Code Instances** | AI processing, tool execution, file operations | Sandboxed execution, Permission approval *(Phase 2)* |

---

## 📋 Testing Guide

Full testing instructions: **[TESTING_MVP.md](./TESTING_MVP.md)**

Quick test scenarios:
1. ✅ Install gateway + generate QR code
2. ✅ Build iOS/Android app
3. ✅ Test biometric authentication
4. ✅ Test QR code pairing
5. ✅ End-to-end message flow

---

## 🛣️ Roadmap

### ✅ Phase 1: MVP (Completed)
- [x] iOS app with biometric auth
- [x] Android app with biometric auth
- [x] QR code pairing
- [x] Install script with channel restrictions
- [x] Basic WebSocket gateway connection

### 🚧 Phase 2: Enterprise Authentication (6-8 weeks)
- [ ] Enterprise SSO (OAuth2, SAML)
- [ ] Azure AD, Okta, Google Workspace integration
- [ ] Certificate pinning (TLS TOFU)
- [ ] Permission approval workflows
- [ ] End-to-end encryption (AES-256-GCM)

### 🔮 Phase 3: Advanced Features (8-10 weeks)
- [ ] Multi-instance management
- [ ] Instance switching UI
- [ ] Audit logging and compliance
- [ ] MDM support (Android Enterprise)
- [ ] Advanced security policies

### 🌟 Phase 4: Enterprise Integration (10-12 weeks)
- [ ] SIEM integration (Splunk, ELK)
- [ ] Secrets management (HashiCorp Vault)
- [ ] High availability (load balancing)
- [ ] Disaster recovery and backups

---

## 📚 Documentation

- **[Enterprise Architecture](./ENTERPRISE_ARCHITECTURE.md)**: Complete 200+ page architecture document
- **[Transformation Plan](./ENTERPRISE_TRANSFORMATION_PLAN.md)**: Full roadmap, costs, team requirements
- **[Testing Guide](./TESTING_MVP.md)**: Step-by-step MVP testing instructions
- **[Android App Spec](./docs/enterprise/android-app-spec.md)**: Android implementation details

---

## 🤝 Contributing

EnterpriseClaw is built on top of [OpenClaw](https://github.com/openclaw/openclaw). Contributions are welcome!

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'feat: add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📄 License

MIT License - see [LICENSE](./LICENSE) for details.

EnterpriseClaw is a fork of [OpenClaw](https://github.com/openclaw/openclaw) by the OpenClaw team.

---

## 🔗 Links

- **Original OpenClaw**: [github.com/openclaw/openclaw](https://github.com/openclaw/openclaw)
- **OpenClaw Docs**: [docs.openclaw.ai](https://docs.openclaw.ai)
- **EnterpriseClaw Repository**: [github.com/Chibionos/ent-claw](https://github.com/Chibionos/ent-claw)

---

## ⚠️ Security Notice

**🔐 IMPORTANT: Protect Your API Keys**

Never commit API keys, tokens, or credentials to version control. EnterpriseClaw uses:
- ✅ Environment variables (`.env` files in `.gitignore`)
- ✅ Secure storage (Keychain, KeyStore, Vault)
- ✅ Gateway token authentication
- ❌ **NO** hardcoded secrets in code

**If you accidentally expose a key:**
1. ☠️ **Revoke it immediately** in your provider dashboard
2. 🔄 **Generate a new key**
3. 🔒 **Store it securely** (environment variables, vault)

---

<p align="center">
  <strong>Built with 🦞 by the EnterpriseClaw team</strong>
</p>

<p align="center">
  Secure. Enterprise-Ready. Mobile-First.
</p>
