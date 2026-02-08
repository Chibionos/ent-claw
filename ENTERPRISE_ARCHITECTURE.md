# EnterpriseClaw Architecture Design Document

## Executive Summary

This document outlines the architectural transformation of OpenClaw into EnterpriseClaw, a secure, mobile-first enterprise AI assistant platform. The transformation removes all external messaging relays (WhatsApp, Telegram, Discord, etc.) and replaces them with direct, authenticated communication between enterprise mobile applications and Claude Code instances.

## Table of Contents

1. [Current State Analysis](#current-state-analysis)
2. [Architecture Overview](#architecture-overview)
3. [Core Components](#core-components)
4. [Security Architecture](#security-architecture)
5. [Authentication & Authorization](#authentication--authorization)
6. [Communication Protocol](#communication-protocol)
7. [Permission System](#permission-system)
8. [Multi-Instance Management](#multi-instance-management)
9. [Data Flow Diagrams](#data-flow-diagrams)
10. [API Design](#api-design)
11. [Migration Strategy](#migration-strategy)
12. [Deployment Architecture](#deployment-architecture)

---

## 1. Current State Analysis

### Existing OpenClaw Architecture

**Gateway Server (`src/gateway/server.impl.ts`):**
- WebSocket-based control plane running on port 18789
- Supports multiple channels: WhatsApp, Telegram, Discord, Slack, Signal, iMessage, etc.
- Protocol version 3 with typed frames (req/res/event)
- Device pairing with public key authentication
- Role-based access (operator/node)
- Exec approval system for sensitive operations

**Current Mobile Apps:**
- iOS app (`apps/ios/`): Swift/SwiftUI, acts as "node" with capabilities (camera, canvas, screen, location)
- Android app (`apps/android/`): Kotlin, similar node capabilities
- Both use WebSocket protocol to connect to gateway
- Device identity based on keypair fingerprints
- Auto-discovery via Bonjour/mDNS

**Current Authentication:**
- Token-based or password-based gateway auth
- Device pairing with approval workflow
- Optional Tailscale identity headers
- OAuth for model providers (Anthropic, OpenAI)

**Current Security Model:**
- DM policies (pairing/allowlist/open/disabled)
- Group policies with mention requirements
- Sandbox execution for tools
- Exec approval forwarding
- TLS support with certificate pinning

### Key Insights from Analysis

1. **Strong Foundation**: OpenClaw already has a robust WebSocket protocol with device identity, role-based access, and approval workflows
2. **Channel Abstraction**: Well-designed plugin system for channels (`src/channels/plugins/`)
3. **Mobile Integration**: Existing iOS/Android apps demonstrate working node protocol
4. **Security Features**: Comprehensive exec approval system, device pairing, and sandboxing
5. **Protocol Maturity**: TypeBox schemas, version negotiation, structured framing

---

## 2. Architecture Overview

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    Enterprise Identity Provider                  │
│                  (Azure AD / Okta / SAML / OAuth2)              │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            │ SSO Authentication
                            │
┌───────────────────────────▼─────────────────────────────────────┐
│                    EnterpriseClaw Gateway                        │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │            Authentication Service                         │  │
│  │  - Enterprise SSO integration                            │  │
│  │  - JWT token validation                                  │  │
│  │  - Role mapping & permissions                            │  │
│  └──────────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │            Device Management Service                      │  │
│  │  - QR code generation                                    │  │
│  │  - Device registration & pairing                         │  │
│  │  - Certificate management                                │  │
│  │  - Biometric attestation validation                      │  │
│  └──────────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │            Instance Management Service                    │  │
│  │  - Multi-instance routing                                │  │
│  │  - Health monitoring                                     │  │
│  │  - Permission enforcement                                │  │
│  └──────────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │            Approval Service                               │  │
│  │  - Operation approval workflows                          │  │
│  │  - Push notifications                                    │  │
│  │  - Audit logging                                         │  │
│  └──────────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │            WebSocket Gateway (Enhanced)                   │  │
│  │  - gRPC/WebSocket multiplexing                           │  │
│  │  - E2E encryption                                        │  │
│  │  - Connection pooling                                    │  │
│  └──────────────────────────────────────────────────────────┘  │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             │ Secure WebSocket / gRPC
                             │ (TLS 1.3 + E2E encryption)
                             │
         ┌───────────────────┼───────────────────┐
         │                   │                   │
         ▼                   ▼                   ▼
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│  Claude Code    │  │  Claude Code    │  │  Claude Code    │
│   Instance 1    │  │   Instance 2    │  │   Instance N    │
│                 │  │                 │  │                 │
│  - Developer    │  │  - DevOps       │  │  - Security     │
│    machine      │  │    Server       │  │    Workstation  │
│  - Tools        │  │  - Tools        │  │  - Tools        │
│  - Workspace    │  │  - Workspace    │  │  - Workspace    │
└─────────────────┘  └─────────────────┘  └─────────────────┘
         ▲                   ▲                   ▲
         │                   │                   │
         └───────────────────┴───────────────────┘
                             │
                             │ Status updates, approval requests
                             │
┌────────────────────────────▼────────────────────────────────────┐
│                    EnterpriseClaw Mobile App                     │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │            iOS App                                        │  │
│  │  - Face ID / Touch ID authentication                     │  │
│  │  - QR code scanner for onboarding                        │  │
│  │  - Multi-instance dashboard                              │  │
│  │  - Approval UI with context                              │  │
│  │  - Audit log viewer                                      │  │
│  └──────────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │            Android App                                    │  │
│  │  - Biometric authentication                              │  │
│  │  - QR code scanner for onboarding                        │  │
│  │  - Multi-instance dashboard                              │  │
│  │  - Approval UI with context                              │  │
│  │  - Audit log viewer                                      │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

### Key Architectural Changes

1. **Remove Channel Plugins**: Eliminate WhatsApp, Telegram, Discord, Slack, Signal, iMessage integrations
2. **Enterprise Authentication**: Replace token/password auth with enterprise SSO
3. **Direct Mobile Communication**: Mobile apps become the ONLY client interface
4. **Multi-Instance Support**: Gateway manages multiple Claude Code instances
5. **Enhanced Security**: Add biometric authentication, E2E encryption, zero-trust networking

---

## 3. Core Components

### 3.1 Enterprise Gateway

**Location**: `src/gateway/` (enhanced)

**Responsibilities:**
- Enterprise authentication integration
- Device registration and management
- Multi-instance routing and health monitoring
- Approval workflow orchestration
- Audit logging and compliance
- Certificate management

**New Modules:**
```
src/gateway/
├── enterprise/
│   ├── auth/
│   │   ├── sso-provider.ts          # SSO provider abstraction
│   │   ├── azure-ad.ts              # Azure AD integration
│   │   ├── okta.ts                  # Okta integration
│   │   ├── saml.ts                  # SAML integration
│   │   ├── jwt-validator.ts         # JWT token validation
│   │   └── role-mapper.ts           # Enterprise role mapping
│   ├── device/
│   │   ├── qr-generator.ts          # QR code generation for pairing
│   │   ├── device-registry.ts       # Device registration and tracking
│   │   ├── biometric-validator.ts   # Biometric attestation validation
│   │   └── certificate-manager.ts   # Device certificate management
│   ├── instance/
│   │   ├── instance-manager.ts      # Claude Code instance management
│   │   ├── instance-router.ts       # Request routing to instances
│   │   ├── health-monitor.ts        # Instance health monitoring
│   │   └── permission-enforcer.ts   # Permission enforcement
│   └── approval/
│       ├── approval-service.ts      # Approval workflow service
│       ├── push-notifier.ts         # Push notification service
│       └── audit-logger.ts          # Audit logging service
```

### 3.2 Mobile Applications

**Location**: `apps/ios/` and `apps/android/` (enhanced)

**New Features:**
- Enterprise SSO authentication flow
- QR code scanner for device pairing
- Biometric authentication (Face ID, Touch ID, fingerprint)
- Multi-instance dashboard
- Real-time approval UI
- Audit log viewer
- Push notification handling

**New Modules:**
```
apps/ios/Sources/
├── Enterprise/
│   ├── Authentication/
│   │   ├── SSOAuthController.swift      # SSO authentication
│   │   ├── BiometricAuthController.swift # Biometric auth
│   │   └── TokenManager.swift           # Token management
│   ├── Onboarding/
│   │   ├── QRScannerView.swift          # QR code scanner
│   │   ├── DevicePairingView.swift      # Device pairing flow
│   │   └── EnterpriseWelcomeView.swift  # Welcome screen
│   ├── Dashboard/
│   │   ├── InstanceListView.swift       # Instance list
│   │   ├── InstanceDetailView.swift     # Instance details
│   │   └── InstanceStatusCard.swift     # Status card component
│   ├── Approvals/
│   │   ├── ApprovalListView.swift       # Approval queue
│   │   ├── ApprovalDetailView.swift     # Approval details
│   │   └── ApprovalActionView.swift     # Approve/deny UI
│   └── Audit/
│       ├── AuditLogView.swift           # Audit log viewer
│       └── AuditFilterView.swift        # Log filtering
```

### 3.3 Claude Code Instance Adapter

**Location**: `src/enterprise-adapter/` (new)

**Responsibilities:**
- Register with enterprise gateway
- Report health status
- Execute approved operations
- Stream operation results
- Handle connection failures

**Modules:**
```
src/enterprise-adapter/
├── registration.ts        # Instance registration with gateway
├── heartbeat.ts          # Health monitoring and reporting
├── operation-executor.ts # Operation execution with approval
├── result-streamer.ts    # Stream operation results to mobile
└── connection-manager.ts # Connection lifecycle management
```

---

## 4. Security Architecture

### 4.1 Zero-Trust Principles

1. **Never Trust, Always Verify**: Every request authenticated and authorized
2. **Least Privilege Access**: Minimal permissions by default
3. **Assume Breach**: Defense in depth with multiple security layers
4. **Explicit Verification**: Biometric + SSO + device certificate
5. **Encrypted Everything**: E2E encryption for all communications

### 4.2 Security Layers

```
┌─────────────────────────────────────────────────────────────┐
│ Layer 7: Audit & Monitoring                                 │
│ - Comprehensive audit logging                               │
│ - Real-time threat detection                                │
│ - Anomaly detection                                         │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│ Layer 6: Application Security                               │
│ - Input validation                                          │
│ - Output sanitization                                       │
│ - Rate limiting                                             │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│ Layer 5: Authorization                                      │
│ - Role-based access control (RBAC)                         │
│ - Permission enforcement                                    │
│ - Operation approval workflow                               │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│ Layer 4: Authentication                                     │
│ - Enterprise SSO (Azure AD, Okta, SAML)                    │
│ - Biometric authentication                                  │
│ - Device certificate validation                             │
│ - JWT token validation                                      │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│ Layer 3: Encryption                                         │
│ - E2E encryption (AES-256-GCM)                             │
│ - TLS 1.3 for transport                                    │
│ - Key rotation                                              │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│ Layer 2: Network Security                                   │
│ - VPN/Zero-trust network access                            │
│ - Certificate pinning                                       │
│ - mTLS for instance communication                          │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│ Layer 1: Device Security                                    │
│ - Secure enclave (iOS) / Keystore (Android)               │
│ - Device attestation                                        │
│ - Jailbreak/root detection                                 │
└─────────────────────────────────────────────────────────────┘
```

### 4.3 Threat Model

| Threat | Mitigation |
|--------|-----------|
| **Unauthorized Access** | - Multi-factor auth (SSO + biometric + device cert)<br>- Device pairing approval workflow<br>- Session timeout and re-authentication |
| **Man-in-the-Middle** | - TLS 1.3 with certificate pinning<br>- E2E encryption for sensitive operations<br>- mTLS for instance communication |
| **Stolen Device** | - Biometric authentication required<br>- Remote device wipe capability<br>- Device-bound encryption keys |
| **Credential Theft** | - No long-lived passwords<br>- Short-lived JWT tokens<br>- Token rotation<br>- Device attestation |
| **Insider Threat** | - Comprehensive audit logging<br>- Approval workflow for sensitive ops<br>- Principle of least privilege<br>- Anomaly detection |
| **Replay Attacks** | - Nonce-based challenge-response<br>- Timestamp validation<br>- Request signing |
| **Privilege Escalation** | - Strict RBAC enforcement<br>- Operation-level permissions<br>- Approval required for elevated ops |
| **Data Exfiltration** | - Audit logging of all data access<br>- Rate limiting<br>- Anomaly detection<br>- DLP integration |

---

## 5. Authentication & Authorization

### 5.1 Enterprise SSO Integration

**Supported Providers:**
- Azure Active Directory (Microsoft Entra ID)
- Okta
- SAML 2.0 providers
- OAuth 2.0 / OIDC providers

**Authentication Flow:**

```
┌──────────┐                                    ┌──────────────┐
│  Mobile  │                                    │   Gateway    │
│   App    │                                    │              │
└────┬─────┘                                    └──────┬───────┘
     │                                                  │
     │  1. Launch app                                  │
     │────────────────────────────────────────────────▶│
     │                                                  │
     │  2. Redirect to SSO provider                    │
     │◀────────────────────────────────────────────────│
     │                                                  │
┌────▼─────┐                                           │
│   SSO    │                                           │
│ Provider │                                           │
└────┬─────┘                                           │
     │                                                  │
     │  3. User authenticates                          │
     │     (username + password + MFA)                 │
     │                                                  │
     │  4. Authorization code                          │
     │─────────────────────────────────────────────────▶
     │                                                  │
     │  5. Exchange code for tokens                    │
     │─────────────────────────────────────────────────▶
     │                                                  │
     │  6. ID token + access token                     │
     │◀─────────────────────────────────────────────────
     │                                                  │
     │  7. Biometric authentication                    │
     │     (Face ID / Touch ID / Fingerprint)          │
     │                                                  │
     │  8. Generate device key pair                    │
     │     Store private key in secure enclave         │
     │                                                  │
     │  9. Sign nonce with device key                  │
     │     Send: ID token + device cert + signature    │
     │─────────────────────────────────────────────────▶
     │                                                  │
     │                                 10. Validate:    │
     │                                  - ID token JWT  │
     │                                  - Device cert   │
     │                                  - Signature     │
     │                                  - User roles    │
     │                                                  │
     │  11. Issue device token + session token         │
     │◀─────────────────────────────────────────────────
     │                                                  │
     │  12. Store tokens securely                      │
     │                                                  │
```

### 5.2 Biometric Authentication

**iOS Implementation (Face ID / Touch ID):**
```swift
// Existing biometric auth can be enhanced
import LocalAuthentication

class BiometricAuthController {
    func authenticate() async throws -> Bool {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            throw BiometricError.notAvailable
        }

        let reason = "Authenticate to access EnterpriseClaw"
        let result = try await context.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: reason
        )

        return result
    }
}
```

**Android Implementation (Biometric API):**
```kotlin
// Can be added to existing Android app
import androidx.biometric.BiometricPrompt

class BiometricAuthController(private val activity: FragmentActivity) {
    suspend fun authenticate(): Boolean = suspendCancellableCoroutine { continuation ->
        val executor = ContextCompat.getMainExecutor(activity)
        val callback = object : BiometricPrompt.AuthenticationCallback() {
            override fun onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult) {
                continuation.resume(true)
            }

            override fun onAuthenticationFailed() {
                continuation.resume(false)
            }

            override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                continuation.resumeWithException(BiometricException(errString.toString()))
            }
        }

        val promptInfo = BiometricPrompt.PromptInfo.Builder()
            .setTitle("EnterpriseClaw Authentication")
            .setSubtitle("Authenticate to continue")
            .setNegativeButtonText("Cancel")
            .build()

        val biometricPrompt = BiometricPrompt(activity, executor, callback)
        biometricPrompt.authenticate(promptInfo)
    }
}
```

### 5.3 QR Code Onboarding

**QR Code Payload:**
```json
{
  "version": 1,
  "gatewayUrl": "wss://gateway.company.com:18789",
  "gatewayCert": "sha256:...",
  "pairingToken": "temporary-pairing-token-expires-in-5min",
  "organizationId": "org-uuid",
  "instanceId": "instance-uuid-optional",
  "config": {
    "requireBiometric": true,
    "allowOfflineApprovals": false,
    "sessionTimeout": 900
  }
}
```

**QR Code Generation (Gateway):**
```typescript
// src/gateway/enterprise/device/qr-generator.ts
export class QRCodeGenerator {
  async generatePairingQR(
    userId: string,
    organizationId: string,
    instanceId?: string
  ): Promise<QRCodeData> {
    const pairingToken = await this.generatePairingToken({
      userId,
      organizationId,
      instanceId,
      expiresIn: 300, // 5 minutes
    });

    const payload: QRCodePayload = {
      version: 1,
      gatewayUrl: this.config.gatewayUrl,
      gatewayCert: this.config.tlsFingerprint,
      pairingToken,
      organizationId,
      instanceId,
      config: {
        requireBiometric: true,
        allowOfflineApprovals: false,
        sessionTimeout: 900,
      },
    };

    const qrCode = await this.encodeQRCode(payload);

    return {
      qrCode,
      payload,
      expiresAt: Date.now() + 300000,
    };
  }
}
```

**QR Code Scanner (Mobile):**
```swift
// apps/ios/Sources/Enterprise/Onboarding/QRScannerView.swift
struct QRScannerView: View {
    @State private var isScanning = false
    @StateObject private var scanner = QRCodeScanner()

    var body: some View {
        VStack {
            CameraPreview(scanner: scanner)
                .onAppear { scanner.startScanning() }
                .onDisappear { scanner.stopScanning() }

            Text("Scan the QR code from your administrator")
                .padding()
        }
        .onChange(of: scanner.scannedCode) { newValue in
            if let code = newValue {
                handleScannedCode(code)
            }
        }
    }

    private func handleScannedCode(_ code: String) {
        // Parse QR code payload
        // Validate gateway certificate
        // Initiate device pairing
    }
}
```

### 5.4 Role-Based Access Control (RBAC)

**Enterprise Roles:**

| Role | Permissions | Use Case |
|------|------------|----------|
| **Developer** | - Execute code operations<br>- Read/write files<br>- Access development instances<br>- Approve low-risk operations | Individual developers working on their own instances |
| **DevOps Engineer** | - Execute system operations<br>- Manage infrastructure<br>- Access production instances<br>- Approve medium-risk operations | DevOps team managing multiple instances |
| **Security Auditor** | - Read-only access<br>- View audit logs<br>- Monitor operations<br>- Cannot approve operations | Security team auditing activities |
| **Administrator** | - Full access to all instances<br>- User management<br>- Policy configuration<br>- Approve high-risk operations | IT administrators managing the platform |
| **Viewer** | - Read-only dashboard<br>- View instance status<br>- Cannot execute operations<br>- Cannot approve operations | Managers and stakeholders monitoring progress |

**Permission Granularity:**

```typescript
// src/gateway/enterprise/auth/permissions.ts
export enum Permission {
  // Instance Management
  INSTANCE_VIEW = 'instance:view',
  INSTANCE_CONTROL = 'instance:control',
  INSTANCE_CONFIGURE = 'instance:configure',

  // Operation Execution
  OPERATION_EXECUTE_READ = 'operation:execute:read',
  OPERATION_EXECUTE_WRITE = 'operation:execute:write',
  OPERATION_EXECUTE_SYSTEM = 'operation:execute:system',
  OPERATION_EXECUTE_NETWORK = 'operation:execute:network',

  // Approval
  APPROVAL_VIEW = 'approval:view',
  APPROVAL_APPROVE_LOW = 'approval:approve:low',
  APPROVAL_APPROVE_MEDIUM = 'approval:approve:medium',
  APPROVAL_APPROVE_HIGH = 'approval:approve:high',

  // Audit
  AUDIT_VIEW_OWN = 'audit:view:own',
  AUDIT_VIEW_ALL = 'audit:view:all',

  // Administration
  ADMIN_USER_MANAGE = 'admin:user:manage',
  ADMIN_POLICY_CONFIGURE = 'admin:policy:configure',
  ADMIN_INSTANCE_MANAGE = 'admin:instance:manage',
}

export const ROLE_PERMISSIONS: Record<string, Permission[]> = {
  developer: [
    Permission.INSTANCE_VIEW,
    Permission.INSTANCE_CONTROL,
    Permission.OPERATION_EXECUTE_READ,
    Permission.OPERATION_EXECUTE_WRITE,
    Permission.APPROVAL_VIEW,
    Permission.APPROVAL_APPROVE_LOW,
    Permission.AUDIT_VIEW_OWN,
  ],
  devops: [
    Permission.INSTANCE_VIEW,
    Permission.INSTANCE_CONTROL,
    Permission.OPERATION_EXECUTE_READ,
    Permission.OPERATION_EXECUTE_WRITE,
    Permission.OPERATION_EXECUTE_SYSTEM,
    Permission.OPERATION_EXECUTE_NETWORK,
    Permission.APPROVAL_VIEW,
    Permission.APPROVAL_APPROVE_LOW,
    Permission.APPROVAL_APPROVE_MEDIUM,
    Permission.AUDIT_VIEW_OWN,
  ],
  security_auditor: [
    Permission.INSTANCE_VIEW,
    Permission.AUDIT_VIEW_ALL,
  ],
  administrator: [
    ...Object.values(Permission),
  ],
  viewer: [
    Permission.INSTANCE_VIEW,
    Permission.AUDIT_VIEW_OWN,
  ],
};
```

---

## 6. Communication Protocol

### 6.1 Protocol Selection: Enhanced WebSocket + gRPC

**Decision: Hybrid Approach**

1. **WebSocket (Primary)**: Mobile ↔ Gateway
   - Real-time bidirectional communication
   - Low latency for approval workflows
   - Push notifications for events
   - Existing OpenClaw protocol foundation

2. **gRPC (Secondary)**: Gateway ↔ Claude Code Instances
   - Efficient binary protocol (Protocol Buffers)
   - Strong typing and code generation
   - HTTP/2 multiplexing
   - Better for server-to-server communication

**Protocol Stack:**
```
┌─────────────────────────────────────────────────────────┐
│ Application Layer: JSON (Mobile) / Protobuf (Instance) │
├─────────────────────────────────────────────────────────┤
│ E2E Encryption: AES-256-GCM                            │
├─────────────────────────────────────────────────────────┤
│ Protocol: WebSocket / gRPC                              │
├─────────────────────────────────────────────────────────┤
│ Transport: TLS 1.3                                      │
├─────────────────────────────────────────────────────────┤
│ Network: TCP                                            │
└─────────────────────────────────────────────────────────┘
```

### 6.2 Enhanced WebSocket Protocol

**Extend Existing Protocol:**
```typescript
// src/gateway/protocol/schema/enterprise.ts
import { Type } from '@sinclair/typebox';
import { NonEmptyString } from './primitives.js';

// Enhanced connect params with enterprise auth
export const EnterpriseConnectParamsSchema = Type.Object({
  ...ConnectParamsSchema.properties,
  enterprise: Type.Object({
    organizationId: NonEmptyString,
    ssoToken: NonEmptyString,  // JWT from SSO provider
    biometricAttestation: Type.Optional(Type.Object({
      platform: Type.Enum({ iOS: 'ios', Android: 'android' }),
      attestation: NonEmptyString,  // Platform-specific attestation
      timestamp: Type.Integer({ minimum: 0 }),
    })),
  }),
});

// Instance operation request
export const InstanceOperationRequestSchema = Type.Object({
  type: Type.Literal('req'),
  id: NonEmptyString,
  method: Type.Literal('instance.operation'),
  params: Type.Object({
    instanceId: NonEmptyString,
    operation: Type.Object({
      type: Type.Enum({
        BASH: 'bash',
        READ: 'read',
        WRITE: 'write',
        EDIT: 'edit',
      }),
      payload: Type.Unknown(),
    }),
    requireApproval: Type.Boolean(),
    approvalContext: Type.Optional(Type.Object({
      description: NonEmptyString,
      riskLevel: Type.Enum({
        LOW: 'low',
        MEDIUM: 'medium',
        HIGH: 'high',
      }),
      affectedResources: Type.Array(NonEmptyString),
    })),
  }),
});

// Approval request event
export const ApprovalRequestEventSchema = Type.Object({
  type: Type.Literal('event'),
  event: Type.Literal('approval.requested'),
  payload: Type.Object({
    approvalId: NonEmptyString,
    instanceId: NonEmptyString,
    instanceName: NonEmptyString,
    operation: Type.Object({
      type: NonEmptyString,
      description: NonEmptyString,
      payload: Type.Unknown(),
    }),
    riskLevel: Type.Enum({
      LOW: 'low',
      MEDIUM: 'medium',
      HIGH: 'high',
    }),
    context: Type.Object({
      affectedResources: Type.Array(NonEmptyString),
      estimatedImpact: NonEmptyString,
      reversible: Type.Boolean(),
    }),
    requestedBy: Type.Object({
      userId: NonEmptyString,
      userName: NonEmptyString,
      userEmail: NonEmptyString,
    }),
    requestedAt: Type.Integer({ minimum: 0 }),
    expiresAt: Type.Integer({ minimum: 0 }),
  }),
});
```

### 6.3 gRPC Protocol for Instance Communication

**Protocol Buffer Definitions:**
```protobuf
// src/gateway/protocol/enterprise.proto
syntax = "proto3";

package enterpriseclaw.v1;

// Instance registration and health
service InstanceService {
  rpc Register(RegisterRequest) returns (RegisterResponse);
  rpc Heartbeat(HeartbeatRequest) returns (HeartbeatResponse);
  rpc Unregister(UnregisterRequest) returns (UnregisterResponse);
}

message RegisterRequest {
  string instance_id = 1;
  string hostname = 2;
  string platform = 3;
  string version = 4;
  map<string, string> capabilities = 5;
  map<string, string> metadata = 6;
}

message RegisterResponse {
  bool success = 1;
  string session_token = 2;
  int64 token_expires_at = 3;
  ServerConfig config = 4;
}

message ServerConfig {
  int32 heartbeat_interval_seconds = 1;
  int32 operation_timeout_seconds = 2;
  bool require_approval_for_writes = 3;
  bool require_approval_for_system_commands = 4;
}

// Operation execution
service OperationService {
  rpc ExecuteOperation(OperationRequest) returns (stream OperationResponse);
  rpc CancelOperation(CancelOperationRequest) returns (CancelOperationResponse);
}

message OperationRequest {
  string operation_id = 1;
  string instance_id = 2;
  string approval_id = 3;
  OperationType type = 4;
  bytes payload = 5;  // JSON-encoded operation payload
  map<string, string> metadata = 6;
}

enum OperationType {
  OPERATION_TYPE_UNSPECIFIED = 0;
  BASH = 1;
  READ = 2;
  WRITE = 3;
  EDIT = 4;
  APPLY_PATCH = 5;
  GLOB = 6;
  GREP = 7;
}

message OperationResponse {
  string operation_id = 1;
  OperationStatus status = 2;
  oneof payload {
    OperationProgress progress = 3;
    OperationResult result = 4;
    OperationError error = 5;
  }
}

enum OperationStatus {
  OPERATION_STATUS_UNSPECIFIED = 0;
  PENDING = 1;
  RUNNING = 2;
  COMPLETED = 3;
  FAILED = 4;
  CANCELLED = 5;
}

message OperationProgress {
  int32 percent = 1;
  string message = 2;
}

message OperationResult {
  bool success = 1;
  bytes data = 2;  // JSON-encoded result
  map<string, string> metadata = 3;
}

message OperationError {
  string code = 1;
  string message = 2;
  bool retryable = 3;
}
```

### 6.4 End-to-End Encryption

**Encryption Layer:**
```typescript
// src/gateway/enterprise/encryption/e2e-encryption.ts
import { randomBytes, createCipheriv, createDecipheriv } from 'crypto';

export class E2EEncryption {
  private readonly algorithm = 'aes-256-gcm';
  private readonly keyLength = 32;
  private readonly ivLength = 16;
  private readonly tagLength = 16;

  /**
   * Encrypt sensitive operation payloads
   * Key exchange happens during device pairing
   */
  async encrypt(
    plaintext: Buffer,
    sharedKey: Buffer
  ): Promise<EncryptedPayload> {
    const iv = randomBytes(this.ivLength);
    const cipher = createCipheriv(this.algorithm, sharedKey, iv);

    const encrypted = Buffer.concat([
      cipher.update(plaintext),
      cipher.final(),
    ]);

    const tag = cipher.getAuthTag();

    return {
      ciphertext: encrypted.toString('base64'),
      iv: iv.toString('base64'),
      tag: tag.toString('base64'),
    };
  }

  async decrypt(
    encrypted: EncryptedPayload,
    sharedKey: Buffer
  ): Promise<Buffer> {
    const decipher = createDecipheriv(
      this.algorithm,
      sharedKey,
      Buffer.from(encrypted.iv, 'base64')
    );

    decipher.setAuthTag(Buffer.from(encrypted.tag, 'base64'));

    const decrypted = Buffer.concat([
      decipher.update(Buffer.from(encrypted.ciphertext, 'base64')),
      decipher.final(),
    ]);

    return decrypted;
  }
}

interface EncryptedPayload {
  ciphertext: string;
  iv: string;
  tag: string;
}
```

**Key Exchange During Pairing:**
```typescript
// src/gateway/enterprise/device/key-exchange.ts
import { generateKeyPairSync, createDiffieHellman } from 'crypto';

export class DeviceKeyExchange {
  /**
   * ECDH key exchange for E2E encryption
   * Happens during QR code pairing
   */
  async performKeyExchange(
    devicePublicKey: string
  ): Promise<{ sharedKey: Buffer; gatewayPublicKey: string }> {
    // Generate gateway ephemeral key pair
    const { publicKey, privateKey } = generateKeyPairSync('ec', {
      namedCurve: 'secp256k1',
      publicKeyEncoding: { type: 'spki', format: 'pem' },
      privateKeyEncoding: { type: 'pkcs8', format: 'pem' },
    });

    // Perform ECDH
    const sharedKey = this.deriveSharedSecret(
      privateKey,
      devicePublicKey
    );

    // Store shared key associated with device ID
    await this.storeDeviceKey(devicePublicKey, sharedKey);

    return {
      sharedKey,
      gatewayPublicKey: publicKey,
    };
  }
}
```

---

## 7. Permission System

### 7.1 Operation Classification

**Risk-Based Classification:**

```typescript
// src/gateway/enterprise/permissions/operation-classifier.ts
export enum OperationRiskLevel {
  LOW = 'low',
  MEDIUM = 'medium',
  HIGH = 'high',
  CRITICAL = 'critical',
}

export interface OperationClassification {
  riskLevel: OperationRiskLevel;
  requiresApproval: boolean;
  requiredPermissions: Permission[];
  affectedResources: string[];
  reversible: boolean;
  estimatedImpact: string;
}

export class OperationClassifier {
  /**
   * Classify operations based on risk level
   */
  classifyOperation(operation: Operation): OperationClassification {
    switch (operation.type) {
      case 'bash':
        return this.classifyBashOperation(operation);
      case 'read':
        return this.classifyReadOperation(operation);
      case 'write':
        return this.classifyWriteOperation(operation);
      case 'edit':
        return this.classifyEditOperation(operation);
      default:
        return this.classifyUnknownOperation(operation);
    }
  }

  private classifyBashOperation(operation: BashOperation): OperationClassification {
    const command = operation.payload.command;

    // Critical: Commands that can affect system integrity
    if (this.isSystemCommand(command)) {
      return {
        riskLevel: OperationRiskLevel.CRITICAL,
        requiresApproval: true,
        requiredPermissions: [Permission.OPERATION_EXECUTE_SYSTEM],
        affectedResources: ['system'],
        reversible: false,
        estimatedImpact: 'System-level changes',
      };
    }

    // High: Commands that modify data or state
    if (this.isDestructiveCommand(command)) {
      return {
        riskLevel: OperationRiskLevel.HIGH,
        requiresApproval: true,
        requiredPermissions: [Permission.OPERATION_EXECUTE_WRITE],
        affectedResources: this.extractAffectedPaths(command),
        reversible: false,
        estimatedImpact: 'Data modification',
      };
    }

    // Medium: Commands that write data
    if (this.isWriteCommand(command)) {
      return {
        riskLevel: OperationRiskLevel.MEDIUM,
        requiresApproval: true,
        requiredPermissions: [Permission.OPERATION_EXECUTE_WRITE],
        affectedResources: this.extractAffectedPaths(command),
        reversible: true,
        estimatedImpact: 'File creation/modification',
      };
    }

    // Low: Read-only commands
    return {
      riskLevel: OperationRiskLevel.LOW,
      requiresApproval: false,
      requiredPermissions: [Permission.OPERATION_EXECUTE_READ],
      affectedResources: [],
      reversible: true,
      estimatedImpact: 'Read-only',
    };
  }

  private isSystemCommand(command: string): boolean {
    const systemCommands = [
      'sudo', 'su', 'chmod', 'chown',
      'systemctl', 'service', 'reboot', 'shutdown',
      'apt', 'yum', 'brew', 'npm install -g',
    ];
    return systemCommands.some(cmd => command.includes(cmd));
  }

  private isDestructiveCommand(command: string): boolean {
    const destructivePatterns = [
      /rm\s+-rf/,
      /rm\s+.*\*/,
      /mkfs/,
      /dd\s+if=/,
      /format/,
      /> \/dev\//,
    ];
    return destructivePatterns.some(pattern => pattern.test(command));
  }
}
```

### 7.2 Approval Workflow

**Approval State Machine:**

```
┌──────────────┐
│   PENDING    │
│  (created)   │
└──────┬───────┘
       │
       │ User views approval
       │
       ▼
┌──────────────┐
│   REVIEWING  │
│  (opened)    │
└──────┬───────┘
       │
       ├──────────────────┬─────────────────┐
       │                  │                 │
       │ Approve          │ Deny            │ Timeout (5 min)
       │                  │                 │
       ▼                  ▼                 ▼
┌──────────────┐  ┌───────────────┐  ┌───────────────┐
│   APPROVED   │  │    DENIED     │  │    EXPIRED    │
│  (executing) │  │  (rejected)   │  │  (timeout)    │
└──────┬───────┘  └───────────────┘  └───────────────┘
       │
       │ Operation complete
       │
       ▼
┌──────────────┐
│   COMPLETED  │
│  (logged)    │
└──────────────┘
```

**Approval Service Implementation:**

```typescript
// src/gateway/enterprise/approval/approval-service.ts
export class EnterpriseApprovalService {
  private pendingApprovals = new Map<string, ApprovalRequest>();

  /**
   * Request approval for an operation
   */
  async requestApproval(
    operation: ClassifiedOperation,
    instanceId: string,
    userId: string
  ): Promise<ApprovalRequest> {
    const approvalId = randomUUID();

    const approval: ApprovalRequest = {
      id: approvalId,
      instanceId,
      operation,
      requestedBy: userId,
      requestedAt: Date.now(),
      expiresAt: Date.now() + 300000, // 5 minutes
      status: ApprovalStatus.PENDING,
    };

    this.pendingApprovals.set(approvalId, approval);

    // Send push notification to mobile devices
    await this.pushNotifier.sendApprovalRequest(approval);

    // Broadcast to connected operators
    this.gateway.broadcast('approval.requested', approval);

    // Set timeout
    setTimeout(() => {
      this.expireApproval(approvalId);
    }, 300000);

    return approval;
  }

  /**
   * Approve an operation
   */
  async approveOperation(
    approvalId: string,
    userId: string,
    biometricVerified: boolean
  ): Promise<void> {
    const approval = this.pendingApprovals.get(approvalId);

    if (!approval) {
      throw new Error('Approval not found');
    }

    if (approval.status !== ApprovalStatus.PENDING) {
      throw new Error('Approval already processed');
    }

    // Verify user has permission to approve
    await this.verifyApprovalPermission(userId, approval.operation.riskLevel);

    // Require biometric for high-risk operations
    if (approval.operation.riskLevel === OperationRiskLevel.HIGH && !biometricVerified) {
      throw new Error('Biometric verification required');
    }

    approval.status = ApprovalStatus.APPROVED;
    approval.approvedBy = userId;
    approval.approvedAt = Date.now();
    approval.biometricVerified = biometricVerified;

    // Log approval decision
    await this.auditLogger.logApproval(approval);

    // Notify instance to execute operation
    await this.instanceManager.executeOperation(
      approval.instanceId,
      approval.operation,
      approvalId
    );

    // Broadcast approval event
    this.gateway.broadcast('approval.approved', { approvalId });

    this.pendingApprovals.delete(approvalId);
  }

  /**
   * Deny an operation
   */
  async denyOperation(
    approvalId: string,
    userId: string,
    reason: string
  ): Promise<void> {
    const approval = this.pendingApprovals.get(approvalId);

    if (!approval) {
      throw new Error('Approval not found');
    }

    if (approval.status !== ApprovalStatus.PENDING) {
      throw new Error('Approval already processed');
    }

    approval.status = ApprovalStatus.DENIED;
    approval.deniedBy = userId;
    approval.deniedAt = Date.now();
    approval.denialReason = reason;

    // Log denial decision
    await this.auditLogger.logApproval(approval);

    // Notify instance operation was denied
    await this.instanceManager.cancelOperation(
      approval.instanceId,
      approval.operation.id,
      'Denied by user'
    );

    // Broadcast denial event
    this.gateway.broadcast('approval.denied', { approvalId, reason });

    this.pendingApprovals.delete(approvalId);
  }
}
```

### 7.3 Offline Approvals

**Challenge: Mobile app may be offline when approval needed**

**Solution: Pre-approved Operation Templates**

```typescript
// src/gateway/enterprise/approval/offline-approvals.ts
export interface ApprovalTemplate {
  id: string;
  name: string;
  description: string;
  operationPattern: OperationPattern;
  riskLevel: OperationRiskLevel;
  validUntil: number;
  maxUses: number;
  usedCount: number;
}

export class OfflineApprovalManager {
  /**
   * Create pre-approval template for common operations
   * Example: "Allow git operations" or "Allow file reads in project dir"
   */
  async createApprovalTemplate(
    userId: string,
    template: ApprovalTemplateInput
  ): Promise<ApprovalTemplate> {
    // Validate user has permission to create templates
    await this.verifyTemplatePermission(userId, template.riskLevel);

    // Require biometric verification for creating high-risk templates
    if (template.riskLevel === OperationRiskLevel.HIGH) {
      await this.requireBiometric(userId);
    }

    const approvalTemplate: ApprovalTemplate = {
      id: randomUUID(),
      name: template.name,
      description: template.description,
      operationPattern: template.pattern,
      riskLevel: template.riskLevel,
      validUntil: template.expiresAt,
      maxUses: template.maxUses || Infinity,
      usedCount: 0,
    };

    await this.storeTemplate(approvalTemplate);

    return approvalTemplate;
  }

  /**
   * Check if operation matches a pre-approval template
   */
  async checkOfflineApproval(operation: Operation): Promise<boolean> {
    const templates = await this.getActiveTemplates();

    for (const template of templates) {
      if (this.matchesPattern(operation, template.operationPattern)) {
        if (template.usedCount >= template.maxUses) {
          continue;
        }

        if (Date.now() > template.validUntil) {
          continue;
        }

        // Log template usage
        await this.logTemplateUsage(template.id, operation);

        template.usedCount++;
        await this.updateTemplate(template);

        return true;
      }
    }

    return false;
  }
}
```

---

## 8. Multi-Instance Management

### 8.1 Instance Registry

**Instance Metadata:**

```typescript
// src/gateway/enterprise/instance/instance-registry.ts
export interface ClaudeCodeInstance {
  id: string;
  name: string;
  hostname: string;
  platform: string;
  version: string;
  status: InstanceStatus;
  capabilities: InstanceCapabilities;
  metadata: InstanceMetadata;
  health: InstanceHealth;
  registeredAt: number;
  lastSeenAt: number;
  assignedUsers: string[];
  tags: string[];
}

export enum InstanceStatus {
  ONLINE = 'online',
  OFFLINE = 'offline',
  DEGRADED = 'degraded',
  MAINTENANCE = 'maintenance',
}

export interface InstanceCapabilities {
  maxConcurrentOperations: number;
  supportedOperations: OperationType[];
  hasGPU: boolean;
  hasSandbox: boolean;
  workspaceSize: number;
}

export interface InstanceHealth {
  cpuUsage: number;
  memoryUsage: number;
  diskUsage: number;
  activeOperations: number;
  queuedOperations: number;
  lastError: string | null;
}

export class InstanceRegistry {
  private instances = new Map<string, ClaudeCodeInstance>();

  /**
   * Register a new Claude Code instance
   */
  async registerInstance(
    instanceId: string,
    registration: InstanceRegistration
  ): Promise<ClaudeCodeInstance> {
    const instance: ClaudeCodeInstance = {
      id: instanceId,
      name: registration.name || `Instance ${instanceId.slice(0, 8)}`,
      hostname: registration.hostname,
      platform: registration.platform,
      version: registration.version,
      status: InstanceStatus.ONLINE,
      capabilities: registration.capabilities,
      metadata: registration.metadata,
      health: {
        cpuUsage: 0,
        memoryUsage: 0,
        diskUsage: 0,
        activeOperations: 0,
        queuedOperations: 0,
        lastError: null,
      },
      registeredAt: Date.now(),
      lastSeenAt: Date.now(),
      assignedUsers: [],
      tags: [],
    };

    this.instances.set(instanceId, instance);

    // Broadcast instance online event
    this.gateway.broadcast('instance.online', { instanceId });

    return instance;
  }

  /**
   * Update instance health status
   */
  async updateHealth(
    instanceId: string,
    health: Partial<InstanceHealth>
  ): Promise<void> {
    const instance = this.instances.get(instanceId);

    if (!instance) {
      throw new Error('Instance not found');
    }

    instance.health = { ...instance.health, ...health };
    instance.lastSeenAt = Date.now();

    // Check if instance is degraded
    if (this.isInstanceDegraded(instance)) {
      instance.status = InstanceStatus.DEGRADED;
      this.gateway.broadcast('instance.degraded', { instanceId });
    } else if (instance.status === InstanceStatus.DEGRADED) {
      instance.status = InstanceStatus.ONLINE;
      this.gateway.broadcast('instance.recovered', { instanceId });
    }
  }

  /**
   * Get instances accessible to a user
   */
  async getUserInstances(userId: string): Promise<ClaudeCodeInstance[]> {
    const userPermissions = await this.getUserPermissions(userId);

    return Array.from(this.instances.values()).filter(instance => {
      // Admin can see all instances
      if (userPermissions.includes(Permission.ADMIN_INSTANCE_MANAGE)) {
        return true;
      }

      // User can see assigned instances
      if (instance.assignedUsers.includes(userId)) {
        return true;
      }

      // User can see instances with matching tags
      const userTags = await this.getUserTags(userId);
      if (instance.tags.some(tag => userTags.includes(tag))) {
        return true;
      }

      return false;
    });
  }
}
```

### 8.2 Instance Routing

**Load Balancing and Routing:**

```typescript
// src/gateway/enterprise/instance/instance-router.ts
export class InstanceRouter {
  /**
   * Route operation to appropriate instance
   */
  async routeOperation(
    userId: string,
    operation: Operation,
    targetInstanceId?: string
  ): Promise<string> {
    // If target instance specified, validate access
    if (targetInstanceId) {
      await this.validateInstanceAccess(userId, targetInstanceId);
      return targetInstanceId;
    }

    // Get user's accessible instances
    const instances = await this.registry.getUserInstances(userId);

    if (instances.length === 0) {
      throw new Error('No instances available');
    }

    // Filter by capabilities
    const capableInstances = instances.filter(instance =>
      this.instanceSupportsOperation(instance, operation)
    );

    if (capableInstances.length === 0) {
      throw new Error('No capable instances available');
    }

    // Apply routing strategy
    const selectedInstance = await this.selectInstance(
      capableInstances,
      operation
    );

    return selectedInstance.id;
  }

  /**
   * Select best instance using routing strategy
   */
  private async selectInstance(
    instances: ClaudeCodeInstance[],
    operation: Operation
  ): Promise<ClaudeCodeInstance> {
    const strategy = this.config.routingStrategy;

    switch (strategy) {
      case 'least-loaded':
        return this.selectLeastLoaded(instances);
      case 'round-robin':
        return this.selectRoundRobin(instances);
      case 'sticky-session':
        return this.selectStickySession(instances, operation);
      case 'random':
        return this.selectRandom(instances);
      default:
        return this.selectLeastLoaded(instances);
    }
  }

  private selectLeastLoaded(
    instances: ClaudeCodeInstance[]
  ): ClaudeCodeInstance {
    return instances.reduce((best, current) => {
      const bestLoad = best.health.activeOperations / best.capabilities.maxConcurrentOperations;
      const currentLoad = current.health.activeOperations / current.capabilities.maxConcurrentOperations;
      return currentLoad < bestLoad ? current : best;
    });
  }
}
```

### 8.3 Instance Health Monitoring

**Health Check Protocol:**

```typescript
// src/gateway/enterprise/instance/health-monitor.ts
export class InstanceHealthMonitor {
  private readonly HEALTH_CHECK_INTERVAL = 30000; // 30 seconds
  private readonly UNHEALTHY_THRESHOLD = 3; // missed heartbeats

  async startMonitoring(): Promise<void> {
    setInterval(() => this.checkAllInstances(), this.HEALTH_CHECK_INTERVAL);
  }

  private async checkAllInstances(): Promise<void> {
    const instances = await this.registry.getAllInstances();

    for (const instance of instances) {
      await this.checkInstanceHealth(instance);
    }
  }

  private async checkInstanceHealth(
    instance: ClaudeCodeInstance
  ): Promise<void> {
    const now = Date.now();
    const timeSinceLastSeen = now - instance.lastSeenAt;

    // Instance is considered offline if no heartbeat for threshold period
    if (timeSinceLastSeen > this.HEALTH_CHECK_INTERVAL * this.UNHEALTHY_THRESHOLD) {
      if (instance.status !== InstanceStatus.OFFLINE) {
        instance.status = InstanceStatus.OFFLINE;

        // Log offline event
        await this.auditLogger.log({
          event: 'instance.offline',
          instanceId: instance.id,
          timestamp: now,
        });

        // Broadcast offline event
        this.gateway.broadcast('instance.offline', { instanceId: instance.id });

        // Cancel pending operations for offline instance
        await this.instanceManager.cancelPendingOperations(
          instance.id,
          'Instance offline'
        );
      }
    }

    // Check health metrics
    if (instance.health.cpuUsage > 90) {
      this.logger.warn(`High CPU usage on instance ${instance.id}: ${instance.health.cpuUsage}%`);
    }

    if (instance.health.memoryUsage > 90) {
      this.logger.warn(`High memory usage on instance ${instance.id}: ${instance.health.memoryUsage}%`);
    }

    if (instance.health.diskUsage > 90) {
      this.logger.warn(`High disk usage on instance ${instance.id}: ${instance.health.diskUsage}%`);
    }
  }
}
```

---

## 9. Data Flow Diagrams

### 9.1 Authentication Flow

```
┌──────────┐                                      ┌──────────┐
│  Mobile  │                                      │   SSO    │
│   App    │                                      │ Provider │
└─────┬────┘                                      └─────┬────┘
      │                                                 │
      │ 1. Launch app                                  │
      │ ────────────────────────────────────────────▶  │
      │                                                 │
      │ 2. Check for stored credentials                │
      │    (device token from previous session)        │
      │                                                 │
      │ 3. No valid credentials found                  │
      │                                                 │
      │ 4. Redirect to SSO login                       │
      │ ────────────────────────────────────────────▶  │
      │                                                 │
      │ 5. User enters credentials                     │
      │                                                 │
      │ 6. SSO MFA challenge                           │
      │ ◀────────────────────────────────────────────  │
      │                                                 │
      │ 7. User completes MFA                          │
      │ ────────────────────────────────────────────▶  │
      │                                                 │
      │ 8. Authorization code                          │
      │ ◀────────────────────────────────────────────  │
      │                                                 │
┌─────▼────┐                                            │
│ Gateway  │                                            │
└─────┬────┘                                            │
      │                                                 │
      │ 9. Exchange code for tokens                    │
      │ ────────────────────────────────────────────▶  │
      │                                                 │
      │ 10. ID token + access token                    │
      │ ◀────────────────────────────────────────────  │
      │                                                 │
      │ 11. Validate ID token                          │
      │     - Check signature                          │
      │     - Verify issuer                            │
      │     - Check expiration                         │
      │     - Extract user claims                      │
      │                                                 │
      │ 12. Generate challenge nonce                   │
      │ ────────────────────────────────────▶          │
      │                                      │          │
      │                                ┌─────▼────┐    │
      │                                │  Mobile  │    │
      │                                │   App    │    │
      │                                └─────┬────┘    │
      │                                      │          │
      │                   13. Prompt biometric auth    │
      │                                      │          │
      │                   14. Face ID / Touch ID       │
      │                                      │          │
      │                   15. Generate device keypair  │
      │                       (if first time)          │
      │                                      │          │
      │                   16. Sign nonce                │
      │                       with device key          │
      │                                      │          │
      │ 17. Send:                            │          │
      │     - ID token                       │          │
      │     - Device public key              │          │
      │     - Signed nonce                   │          │
      │     - Biometric attestation          │          │
      │ ◀────────────────────────────────────          │
      │                                                 │
      │ 18. Validate:                                  │
      │     - ID token (already validated)             │
      │     - Device signature                         │
      │     - Biometric attestation                    │
      │     - Device not revoked                       │
      │                                                 │
      │ 19. Check if device is paired                  │
      │                                                 │
      │ 20. IF NOT PAIRED:                             │
      │     - Create pairing request                   │
      │     - Store device public key                  │
      │     - Generate QR code (optional)              │
      │     - Wait for admin approval                  │
      │                                                 │
      │ 21. IF PAIRED:                                 │
      │     - Generate device token                    │
      │     - Map enterprise roles to permissions      │
      │     - Create session                           │
      │                                                 │
      │ 22. Return:                                    │
      │     - Device token                             │
      │     - Session info                             │
      │     - User permissions                         │
      │     - Available instances                      │
      │ ────────────────────────────────────▶          │
      │                                      │          │
      │                                ┌─────▼────┐    │
      │                                │  Mobile  │    │
      │                                │   App    │    │
      │                                └─────┬────┘    │
      │                                      │          │
      │                   23. Store device token       │
      │                       in secure enclave        │
      │                                      │          │
      │                   24. Load dashboard           │
      │                                      │          │
```

### 9.2 Operation Execution Flow

```
┌──────────┐         ┌──────────┐         ┌──────────┐         ┌──────────┐
│  Mobile  │         │ Gateway  │         │ Approval │         │ Instance │
│   App    │         │          │         │ Service  │         │          │
└────┬─────┘         └────┬─────┘         └────┬─────┘         └────┬─────┘
     │                    │                     │                     │
     │ 1. User triggers   │                     │                     │
     │    operation       │                     │                     │
     │    (e.g., "run    │                     │                     │
     │     tests")        │                     │                     │
     │                    │                     │                     │
     │ 2. instance.       │                     │                     │
     │    operation       │                     │                     │
     │ ──────────────────▶│                     │                     │
     │                    │                     │                     │
     │                    │ 3. Authenticate &   │                     │
     │                    │    authorize        │                     │
     │                    │    - Validate token │                     │
     │                    │    - Check perms    │                     │
     │                    │                     │                     │
     │                    │ 4. Classify         │                     │
     │                    │    operation        │                     │
     │                    │    - Risk level     │                     │
     │                    │    - Affected res   │                     │
     │                    │    - Reversible?    │                     │
     │                    │                     │                     │
     │                    │ 5. Check approval   │                     │
     │                    │    required?        │                     │
     │                    │    (based on risk)  │                     │
     │                    │                     │                     │
     │                    │ IF APPROVAL NEEDED: │                     │
     │                    │                     │                     │
     │                    │ 6. Create approval  │                     │
     │                    │    request          │                     │
     │                    │ ────────────────────▶                     │
     │                    │                     │                     │
     │                    │                     │ 7. Store approval   │
     │                    │                     │    Generate ID      │
     │                    │                     │                     │
     │ 8. approval.       │                     │                     │
     │    requested       │                     │                     │
     │ ◀──────────────────│◀────────────────────│                     │
     │                    │                     │                     │
     │ 9. Display         │                     │                     │
     │    approval UI     │                     │                     │
     │    - Operation     │                     │                     │
     │    - Risk level    │                     │                     │
     │    - Context       │                     │                     │
     │    - Approve/Deny  │                     │                     │
     │                    │                     │                     │
     │ 10. User reviews   │                     │                     │
     │     and taps       │                     │                     │
     │     "Approve"      │                     │                     │
     │                    │                     │                     │
     │ 11. Biometric      │                     │                     │
     │     auth required  │                     │                     │
     │     (for high risk)│                     │                     │
     │                    │                     │                     │
     │ 12. Face ID /      │                     │                     │
     │     Touch ID       │                     │                     │
     │                    │                     │                     │
     │ 13. approval.      │                     │                     │
     │     approve        │                     │                     │
     │ ──────────────────▶│                     │                     │
     │                    │                     │                     │
     │                    │ 14. Validate:       │                     │
     │                    │     - User has perm │                     │
     │                    │     - Bio verified  │                     │
     │                    │     - Not expired   │                     │
     │                    │                     │                     │
     │                    │ 15. Approve         │                     │
     │                    │     operation       │                     │
     │                    │ ────────────────────▶                     │
     │                    │                     │                     │
     │                    │                     │ 16. Mark approved   │
     │                    │                     │     Log decision    │
     │                    │                     │                     │
     │                    │ 17. Route to        │                     │
     │                    │     instance        │                     │
     │                    │ ───────────────────────────────────────▶  │
     │                    │                     │                     │
     │                    │                     │                     │ 18. Execute
     │                    │                     │                     │     operation
     │                    │                     │                     │     - Bash cmd
     │                    │                     │                     │     - File op
     │                    │                     │                     │     - etc.
     │                    │                     │                     │
     │                    │                     │                     │ 19. Stream
     │                    │                     │                     │     progress
     │                    │ ◀───────────────────────────────────────  │
     │                    │                     │                     │
     │ 20. operation.     │                     │                     │
     │     progress       │                     │                     │
     │ ◀──────────────────│                     │                     │
     │                    │                     │                     │
     │ 21. Update UI      │                     │                     │
     │     with progress  │                     │                     │
     │                    │                     │                     │
     │                    │                     │                     │ 22. Complete
     │                    │ ◀───────────────────────────────────────  │
     │                    │                     │                     │
     │                    │ 23. Log completion  │                     │
     │                    │ ────────────────────▶                     │
     │                    │                     │                     │
     │                    │                     │ 24. Store audit log │
     │                    │                     │                     │
     │ 25. operation.     │                     │                     │
     │     result         │                     │                     │
     │ ◀──────────────────│                     │                     │
     │                    │                     │                     │
     │ 26. Display result │                     │                     │
     │                    │                     │                     │
```

### 9.3 QR Code Pairing Flow

```
┌──────────┐         ┌──────────┐         ┌──────────┐
│  Admin   │         │ Gateway  │         │  Mobile  │
│  Web UI  │         │          │         │   App    │
└────┬─────┘         └────┬─────┘         └────┬─────┘
     │                    │                     │
     │ 1. Admin logs in   │                     │
     │    to web portal   │                     │
     │ ──────────────────▶│                     │
     │                    │                     │
     │ 2. Navigate to     │                     │
     │    "Add Device"    │                     │
     │                    │                     │
     │ 3. Request QR code │                     │
     │ ──────────────────▶│                     │
     │                    │                     │
     │                    │ 4. Generate:        │
     │                    │    - Pairing token  │
     │                    │    - Gateway URL    │
     │                    │    - TLS cert hash  │
     │                    │    - Config         │
     │                    │                     │
     │ 5. QR code data    │                     │
     │ ◀──────────────────│                     │
     │                    │                     │
     │ 6. Display QR      │                     │
     │    code on screen  │                     │
     │                    │                     │
     │                    │                     │ 7. User opens
     │                    │                     │    mobile app
     │                    │                     │
     │                    │                     │ 8. Tap "Pair
     │                    │                     │    Device"
     │                    │                     │
     │                    │                     │ 9. Open camera
     │                    │                     │    scanner
     │                    │                     │
     │                    │                     │ 10. Scan QR code
     │                    │                     │
     │                    │                     │ 11. Parse payload
     │                    │                     │     - Gateway URL
     │                    │                     │     - Pairing token
     │                    │                     │     - Config
     │                    │                     │
     │                    │                     │ 12. Validate
     │                    │                     │     gateway cert
     │                    │                     │
     │                    │                     │ 13. Prompt SSO
     │                    │                     │     login
     │                    │                     │
     │                    │                     │ 14. User
     │                    │                     │     authenticates
     │                    │                     │
     │                    │                     │ 15. Prompt
     │                    │                     │     biometric
     │                    │                     │
     │                    │                     │ 16. Face ID /
     │                    │                     │     Touch ID
     │                    │                     │
     │                    │                     │ 17. Generate
     │                    │                     │     device keypair
     │                    │                     │
     │                    │ 18. device.pair     │
     │                    │     request         │
     │                    │ ◀───────────────────│
     │                    │                     │
     │                    │ 19. Validate:       │
     │                    │     - Pairing token │
     │                    │     - SSO token     │
     │                    │     - Not expired   │
     │                    │                     │
     │                    │ 20. Create pairing  │
     │                    │     record          │
     │                    │                     │
     │ 21. device.pair    │                     │
     │     requested      │                     │
     │ ◀──────────────────│                     │
     │                    │                     │
     │ 22. Display device │                     │
     │     info:          │                     │
     │     - Name         │                     │
     │     - Platform     │                     │
     │     - User         │                     │
     │                    │                     │
     │ 23. Admin reviews  │                     │
     │     and approves   │                     │
     │                    │                     │
     │ 24. device.pair    │                     │
     │     approve        │                     │
     │ ──────────────────▶│                     │
     │                    │                     │
     │                    │ 25. Generate:       │
     │                    │     - Device token  │
     │                    │     - Shared key    │
     │                    │     - Permissions   │
     │                    │                     │
     │                    │ 26. device.pair     │
     │                    │     approved        │
     │                    │ ────────────────────▶
     │                    │                     │
     │                    │                     │ 27. Store:
     │                    │                     │     - Device token
     │                    │                     │     - Shared key
     │                    │                     │     - Gateway URL
     │                    │                     │
     │                    │                     │ 28. Establish
     │                    │                     │     WebSocket
     │                    │                     │     connection
     │                    │                     │
     │                    │ ◀───────────────────│
     │                    │                     │
     │                    │ 29. Complete        │
     │                    │     handshake       │
     │                    │ ────────────────────▶
     │                    │                     │
     │                    │                     │ 30. Load dashboard
     │                    │                     │     - Instances
     │                    │                     │     - Status
     │                    │                     │
```

---

## 10. API Design

### 10.1 Mobile API (WebSocket)

**Enhanced Protocol Methods:**

```typescript
// Device pairing (QR code flow)
interface DevicePairRequestParams {
  pairingToken: string;
  ssoToken: string;
  deviceInfo: {
    id: string;
    publicKey: string;
    signature: string;
    platform: 'ios' | 'android';
    platformVersion: string;
    appVersion: string;
    biometricCapabilities: string[];
  };
}

interface DevicePairApprovedPayload {
  deviceToken: string;
  sharedKey: string;
  permissions: Permission[];
  sessionConfig: {
    timeout: number;
    refreshInterval: number;
  };
}

// Instance management
interface InstanceListParams {
  includeOffline?: boolean;
  tags?: string[];
}

interface InstanceListResponse {
  instances: ClaudeCodeInstance[];
}

interface InstanceOperationParams {
  instanceId: string;
  operation: {
    type: OperationType;
    payload: unknown;
  };
  requireApproval?: boolean;
  approvalContext?: {
    description: string;
    riskLevel: OperationRiskLevel;
    affectedResources: string[];
  };
}

interface InstanceOperationResponse {
  operationId: string;
  status: 'pending_approval' | 'executing' | 'completed';
  approvalId?: string;
}

// Approval management
interface ApprovalListParams {
  status?: ApprovalStatus;
  instanceId?: string;
  limit?: number;
}

interface ApprovalListResponse {
  approvals: ApprovalRequest[];
}

interface ApprovalActionParams {
  approvalId: string;
  action: 'approve' | 'deny';
  biometricVerified: boolean;
  reason?: string;
}

interface ApprovalActionResponse {
  success: boolean;
  operationId?: string;
}

// Audit log
interface AuditLogQueryParams {
  startTime?: number;
  endTime?: number;
  instanceId?: string;
  operationType?: OperationType;
  userId?: string;
  limit?: number;
  offset?: number;
}

interface AuditLogResponse {
  logs: AuditLogEntry[];
  total: number;
  hasMore: boolean;
}
```

### 10.2 Instance API (gRPC)

**Enhanced gRPC Services:**

```protobuf
// Authentication service
service AuthService {
  rpc Authenticate(AuthRequest) returns (AuthResponse);
  rpc RefreshToken(RefreshTokenRequest) returns (RefreshTokenResponse);
  rpc Revoke(RevokeRequest) returns (RevokeResponse);
}

message AuthRequest {
  string instance_id = 1;
  string shared_secret = 2;
  string certificate = 3;
}

message AuthResponse {
  bool success = 1;
  string session_token = 2;
  int64 expires_at = 3;
  ServerPolicy policy = 4;
}

message ServerPolicy {
  int32 heartbeat_interval_seconds = 1;
  int32 operation_timeout_seconds = 2;
  bool require_approval_for_writes = 3;
  bool require_approval_for_system_commands = 4;
  repeated string allowed_operations = 5;
}

// Enhanced operation service
service OperationService {
  rpc ExecuteOperation(OperationRequest) returns (stream OperationResponse);
  rpc CancelOperation(CancelOperationRequest) returns (CancelOperationResponse);
  rpc GetOperationStatus(GetOperationStatusRequest) returns (OperationStatusResponse);
  rpc ListOperations(ListOperationsRequest) returns (ListOperationsResponse);
}

message OperationRequest {
  string operation_id = 1;
  string instance_id = 2;
  string approval_id = 3;  // Required if operation needs approval
  OperationType type = 4;
  bytes payload = 5;  // Encrypted with shared key
  map<string, string> metadata = 6;
}

message OperationResponse {
  string operation_id = 1;
  OperationStatus status = 2;
  oneof payload {
    OperationProgress progress = 3;
    OperationResult result = 4;
    OperationError error = 5;
  }
  int64 timestamp = 6;
}

message OperationProgress {
  int32 percent = 1;
  string message = 2;
  map<string, string> details = 3;
}

message OperationResult {
  bool success = 1;
  bytes data = 2;  // Encrypted with shared key
  map<string, string> metadata = 3;
  int64 duration_ms = 4;
}

message OperationError {
  string code = 1;
  string message = 2;
  bool retryable = 3;
  map<string, string> details = 4;
}

// Health monitoring service
service HealthService {
  rpc ReportHealth(HealthReport) returns (HealthAck);
  rpc GetHealthHistory(GetHealthHistoryRequest) returns (GetHealthHistoryResponse);
}

message HealthReport {
  string instance_id = 1;
  SystemMetrics system = 2;
  OperationMetrics operations = 3;
  int64 timestamp = 4;
}

message SystemMetrics {
  float cpu_usage_percent = 1;
  float memory_usage_percent = 2;
  float disk_usage_percent = 3;
  int64 uptime_seconds = 4;
}

message OperationMetrics {
  int32 active_operations = 1;
  int32 queued_operations = 2;
  int32 completed_last_hour = 3;
  int32 failed_last_hour = 4;
  float avg_duration_ms = 5;
}

// Notification service
service NotificationService {
  rpc SendNotification(NotificationRequest) returns (NotificationResponse);
  rpc SubscribeToNotifications(NotificationSubscription) returns (stream Notification);
}

message NotificationRequest {
  string instance_id = 1;
  NotificationType type = 2;
  string title = 3;
  string body = 4;
  map<string, string> data = 5;
  repeated string user_ids = 6;
}

enum NotificationType {
  NOTIFICATION_TYPE_UNSPECIFIED = 0;
  APPROVAL_REQUIRED = 1;
  OPERATION_COMPLETED = 2;
  OPERATION_FAILED = 3;
  INSTANCE_DEGRADED = 4;
  INSTANCE_OFFLINE = 5;
}
```

---

## 11. Migration Strategy

### 11.1 Migration Phases

**Phase 1: Foundation (Weeks 1-4)**
- Implement enterprise authentication layer
- Add biometric authentication to mobile apps
- Create QR code pairing flow
- Set up device registry

**Phase 2: Protocol Enhancement (Weeks 5-8)**
- Extend WebSocket protocol with enterprise features
- Implement gRPC protocol for instances
- Add E2E encryption layer
- Build approval service

**Phase 3: Multi-Instance Support (Weeks 9-12)**
- Implement instance registry
- Build instance router
- Add health monitoring
- Create mobile dashboard

**Phase 4: Channel Deprecation (Weeks 13-16)**
- Mark old channels as deprecated
- Migrate existing users to mobile app
- Remove channel plugin dependencies
- Clean up codebase

**Phase 5: Security Hardening (Weeks 17-20)**
- Security audit
- Penetration testing
- Compliance validation
- Performance optimization

**Phase 6: Production Rollout (Weeks 21-24)**
- Pilot deployment
- User training
- Full production deployment
- Post-deployment monitoring

### 11.2 Backwards Compatibility

**Maintain Compatibility During Migration:**

1. **Dual-Protocol Support**: Gateway supports both old and new protocols
2. **Gradual Channel Removal**: Deprecated channels remain functional but hidden
3. **Migration Tools**: Scripts to help users transition
4. **Documentation**: Clear migration guides

**Example: Feature Flags**

```typescript
// src/gateway/enterprise/feature-flags.ts
export const FEATURE_FLAGS = {
  // Enterprise features
  ENTERPRISE_SSO: process.env.ENTERPRISE_SSO_ENABLED === 'true',
  BIOMETRIC_AUTH: process.env.BIOMETRIC_AUTH_ENABLED === 'true',
  MULTI_INSTANCE: process.env.MULTI_INSTANCE_ENABLED === 'true',

  // Legacy features
  LEGACY_CHANNELS: process.env.LEGACY_CHANNELS_ENABLED !== 'false', // Default true
  LEGACY_PAIRING: process.env.LEGACY_PAIRING_ENABLED !== 'false',   // Default true
};

export function isEnterpriseMode(): boolean {
  return FEATURE_FLAGS.ENTERPRISE_SSO && FEATURE_FLAGS.BIOMETRIC_AUTH;
}

export function shouldEnableLegacyChannels(): boolean {
  return FEATURE_FLAGS.LEGACY_CHANNELS && !isEnterpriseMode();
}
```

### 11.3 Data Migration

**User Data Migration:**

1. **Device Pairing**: Migrate existing device pairings to new format
2. **Permissions**: Map old allowlists to new RBAC roles
3. **Audit Logs**: Convert old logs to new audit format
4. **Sessions**: Preserve session history

**Migration Script Example:**

```typescript
// scripts/migrate-to-enterprise.ts
export async function migrateToEnterprise() {
  console.log('Starting enterprise migration...');

  // 1. Migrate device pairings
  await migrateDevicePairings();

  // 2. Convert channel allowlists to RBAC
  await migratePermissions();

  // 3. Migrate audit logs
  await migrateAuditLogs();

  // 4. Update configuration
  await updateConfiguration();

  console.log('Migration completed successfully!');
}

async function migrateDevicePairings() {
  const oldPairings = await loadLegacyPairings();

  for (const pairing of oldPairings) {
    const newPairing: DevicePairing = {
      id: pairing.id,
      deviceId: pairing.device.id,
      publicKey: pairing.device.publicKey,
      userId: pairing.userId,
      role: 'developer', // Default role
      permissions: ROLE_PERMISSIONS.developer,
      pairedAt: pairing.createdAt,
      lastSeenAt: pairing.lastUsedAt,
      status: 'active',
    };

    await storeDevicePairing(newPairing);
  }
}

async function migratePermissions() {
  const channels = ['whatsapp', 'telegram', 'discord', 'slack'];

  for (const channel of channels) {
    const allowlist = await loadChannelAllowlist(channel);

    for (const userId of allowlist) {
      await grantPermission(userId, Permission.INSTANCE_VIEW);
      await grantPermission(userId, Permission.INSTANCE_CONTROL);
      await grantPermission(userId, Permission.OPERATION_EXECUTE_READ);
      await grantPermission(userId, Permission.OPERATION_EXECUTE_WRITE);
      await grantPermission(userId, Permission.APPROVAL_APPROVE_LOW);
    }
  }
}
```

---

## 12. Deployment Architecture

### 12.1 Production Deployment

**Infrastructure Components:**

```
┌─────────────────────────────────────────────────────────┐
│                    Load Balancer (TLS)                  │
│                     (Azure Front Door)                  │
└────────────────────────┬────────────────────────────────┘
                         │
                         │ HTTPS
                         │
┌────────────────────────▼────────────────────────────────┐
│                 Enterprise Gateway Cluster              │
│               (Azure Kubernetes Service)                │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐             │
│  │ Gateway  │  │ Gateway  │  │ Gateway  │             │
│  │  Pod 1   │  │  Pod 2   │  │  Pod N   │             │
│  └──────────┘  └──────────┘  └──────────┘             │
└────────────────────────┬────────────────────────────────┘
                         │
         ┌───────────────┼────────────────┐
         │               │                │
         ▼               ▼                ▼
┌─────────────┐  ┌─────────────┐  ┌─────────────┐
│  Redis      │  │  PostgreSQL │  │  Azure      │
│  (Sessions) │  │  (Metadata) │  │  Key Vault  │
└─────────────┘  └─────────────┘  └─────────────┘
         │               │                │
         └───────────────┼────────────────┘
                         │
                         │ Secure connection
                         │
┌────────────────────────▼────────────────────────────────┐
│              Azure Active Directory                     │
│              (Enterprise SSO)                           │
└─────────────────────────────────────────────────────────┘
```

**High Availability:**
- Multiple gateway pods behind load balancer
- Redis cluster for session state
- PostgreSQL with replication for metadata
- Azure Key Vault for secrets management

### 12.2 Security Infrastructure

**Network Security:**
- Virtual Network with private subnets
- Network Security Groups (NSGs)
- Azure Firewall for egress filtering
- Private endpoints for Azure services
- DDoS protection

**Secrets Management:**
- Azure Key Vault for certificates and keys
- Managed identities for service authentication
- Regular key rotation
- Hardware Security Module (HSM) for key storage

**Monitoring & Logging:**
- Azure Monitor for metrics
- Log Analytics for log aggregation
- Application Insights for tracing
- Azure Sentinel for security monitoring

### 12.3 Disaster Recovery

**Backup Strategy:**
- Automated database backups (daily)
- Configuration backup to Azure Blob Storage
- Point-in-time recovery capability
- Cross-region replication

**Recovery Objectives:**
- Recovery Time Objective (RTO): 1 hour
- Recovery Point Objective (RPO): 15 minutes
- Automated failover to secondary region
- Regular DR testing (quarterly)

---

## 13. Compliance & Governance

### 13.1 Compliance Requirements

**Data Protection:**
- GDPR compliance for EU users
- CCPA compliance for California users
- SOC 2 Type II certification
- ISO 27001 certification

**Audit Requirements:**
- Comprehensive audit logging
- Tamper-proof audit trail
- 90-day audit retention (configurable)
- Audit log encryption at rest

**Access Controls:**
- Role-based access control (RBAC)
- Principle of least privilege
- Just-in-time (JIT) access
- Regular access reviews

### 13.2 Governance Policies

**Data Governance:**
- Data classification (public, internal, confidential, restricted)
- Data retention policies
- Data deletion procedures
- Cross-border data transfer controls

**Operational Governance:**
- Change management process
- Incident response plan
- Security review process
- Regular security audits

---

## 14. Conclusion

This architecture transformation converts OpenClaw from a personal AI assistant with multiple messaging channels into EnterpriseClaw, a secure, mobile-first enterprise platform. The key achievements:

1. **Zero External Dependencies**: All communication flows through enterprise-controlled channels
2. **Military-Grade Security**: Multi-layer security with SSO, biometric auth, E2E encryption, and device attestation
3. **Enterprise-Ready**: RBAC, approval workflows, audit logging, and compliance controls
4. **Scalable Architecture**: Multi-instance support with health monitoring and load balancing
5. **Smooth Migration**: Phased migration strategy with backwards compatibility

The architecture leverages OpenClaw's existing strengths (WebSocket protocol, device pairing, approval system) while adding enterprise-grade security and management capabilities. The result is a platform that IT administrators can trust and developers will love to use.

---

## Appendix A: Technology Stack

**Backend:**
- Node.js 22+ (TypeScript)
- WebSocket (existing protocol)
- gRPC (new instance protocol)
- Redis (session state)
- PostgreSQL (metadata)
- Protocol Buffers (gRPC)

**Mobile:**
- iOS: Swift, SwiftUI
- Android: Kotlin, Jetpack Compose
- Platform Security: Keychain (iOS), Keystore (Android)

**Infrastructure:**
- Azure Kubernetes Service (AKS)
- Azure Active Directory
- Azure Key Vault
- Azure Front Door
- Azure Monitor

**Security:**
- TLS 1.3
- AES-256-GCM encryption
- JWT tokens
- mTLS for instance communication
- Certificate pinning

---

## Appendix B: Open Questions

1. **SSO Provider Priority**: Which SSO provider should we support first? (Recommendation: Azure AD, then Okta)
2. **Mobile Platform Priority**: iOS first or Android first? (Recommendation: iOS for enterprise, parallelize if possible)
3. **On-Premise Gateway**: Should we support on-premise gateway deployment? (Recommendation: Yes, add to Phase 5)
4. **Offline Mode**: How long can mobile app work offline? (Recommendation: 24 hours with cached approvals)
5. **Instance Limits**: Maximum instances per user? (Recommendation: 10 for developers, unlimited for admins)

---

## Appendix C: Performance Targets

**Latency:**
- Authentication: < 2 seconds
- QR code pairing: < 5 seconds
- Operation submission: < 500ms
- Operation execution: Depends on operation (baseline: < 10s for simple operations)
- Approval workflow: < 30 seconds (user-dependent)

**Scalability:**
- Support 10,000+ concurrent mobile connections
- Support 1,000+ Claude Code instances
- Handle 100+ operations per second
- Store 1TB+ audit logs

**Reliability:**
- 99.9% uptime SLA
- < 0.1% error rate
- Automatic failover < 60 seconds
- Zero data loss

---

**Document Version:** 1.0
**Last Updated:** 2026-02-07
**Authors:** Enterprise Architect
**Status:** Draft for Review
