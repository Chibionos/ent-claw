# EnterpriseClaw Android Application Specification

## Executive Summary

This document specifies the Android application for EnterpriseClaw, an enterprise-focused deployment of OpenClaw (Claude Code) with enhanced security, biometric authentication, SSO integration, and comprehensive device management capabilities. The app builds upon the existing OpenClaw Android codebase while adding enterprise-grade security and compliance features.

**Target Users:** Enterprise employees, IT administrators, developers, and technical teams requiring secure mobile access to Claude Code instances.

**Core Value Proposition:** Secure, compliant, mobile-first access to Claude Code with enterprise authentication, biometric security, and multi-instance management.

---

## 1. Feature List

### 1.1 Core Features (Existing Foundation)
- **Gateway Discovery**: Local (mDNS/Bonjour) and wide-area (DNS-SD) discovery of Claude Code gateways
- **Secure WebSocket Connection**: TLS with certificate pinning and device authentication
- **Canvas Host**: WebView-based interactive canvas with A2UI protocol support
- **Node Capabilities**: Camera, screen recording, location, SMS, voice wake, talk mode
- **Chat Interface**: Multi-session chat with streaming responses, tool call visibility
- **Settings Management**: Device configuration, manual gateway connection, capability toggles
- **Persistent Identity**: Device-specific ED25519 key pair for gateway authentication

### 1.2 New Enterprise Features

#### Authentication & Security
- **Biometric Authentication**
  - Face unlock (Android BiometricPrompt API)
  - Fingerprint authentication
  - PIN/pattern fallback
  - Configurable authentication timeout (1m/5m/15m/30m/1h)
  - Authentication required on app launch and resume after timeout

- **Enterprise SSO Integration**
  - OAuth2/OIDC support (Azure AD, Okta, Ping Identity, Google Workspace)
  - SAML 2.0 support
  - Token refresh and session management
  - Device compliance validation
  - Conditional access policy enforcement

- **Certificate Management**
  - Enhanced TLS certificate pinning
  - Enterprise root CA trust store
  - Per-gateway certificate validation
  - Certificate rotation handling
  - Certificate expiry warnings

#### Onboarding & Pairing
- **QR Code Onboarding**
  - Scan QR code from gateway web UI
  - Extract gateway endpoint, TLS fingerprint, pairing token
  - One-tap pairing flow
  - Support for pre-configured enterprise QR codes
  - Bulk enrollment support via EMM/MDM

- **Capability Showcase**
  - Interactive onboarding tutorial
  - Demo mode showing node capabilities (camera, screen, location, etc.)
  - Permission education and rationale
  - First-time user guidance
  - Progressive permission requests

#### Multi-Instance Management
- **Instance Switching**
  - Multiple Claude Code instance profiles
  - Quick-switch UI (dropdown or side panel)
  - Per-instance settings (display name, icon, connection params)
  - Instance health monitoring
  - Favorite/pinned instances

- **Instance Discovery**
  - Automatic discovery of available gateways
  - Manual instance addition via IP/hostname/QR
  - Instance grouping by organization/team
  - Recent/frequently used instances

#### Permission & Approval System
- **Permission Request UI**
  - Real-time approval prompts for sensitive operations
  - Context-aware permission details (what, why, who requested)
  - Approve/deny with reason
  - Temporary vs. permanent approval options
  - Permission history log

- **Approval Types**
  - Camera access
  - Screen recording
  - Location (precise/approximate)
  - SMS send
  - File/photo access
  - Contacts/calendar access (future)

#### Enterprise Management
- **Android Enterprise Integration**
  - Managed app configuration (AppConfig)
  - Work profile support
  - Fully managed device mode
  - Device compliance policies
  - Remote wipe/lock capabilities

- **MDM Support**
  - Intune, VMware Workspace ONE, MobileIron
  - Managed app config schema
  - App configuration via EMM
  - Certificate deployment via MDM
  - Policy enforcement (screen lock, encryption, etc.)

#### Monitoring & Diagnostics
- **Real-time Status**
  - Gateway connection health
  - WebSocket status
  - Network diagnostics
  - Battery impact monitoring
  - Data usage tracking

- **Activity Feed**
  - Recent operations log
  - Permission grant/deny history
  - Error and warning messages
  - Session history
  - Audit trail export

#### Offline Capability
- **Graceful Degradation**
  - Offline mode indicator
  - Cached canvas content (read-only)
  - Message queue for pending operations
  - Automatic reconnection on network restore
  - Local diagnostic tools

---

## 2. Screen Flows

### 2.1 First-Time Onboarding Flow

```
Launch App
  ├─> Splash Screen (brand identity)
  ├─> Welcome Screen
  │     - "Welcome to EnterpriseClaw"
  │     - Brief value proposition
  │     - "Get Started" CTA
  ├─> Permission Education
  │     - Why we need permissions
  │     - What we protect
  │     - How we use device capabilities
  │     - "Continue" CTA
  ├─> SSO Login (if configured)
  │     - OAuth2/SAML redirect
  │     - External browser or WebView
  │     - Token acquisition
  │     - User profile fetch
  ├─> Biometric Setup
  │     - "Secure your access"
  │     - Enable Face/Fingerprint auth
  │     - Set PIN fallback
  │     - "Skip" or "Enable"
  ├─> Gateway Pairing
  │     ├─> Scan QR Code
  │     │     - Camera permission request
  │     │     - QR scanner overlay
  │     │     - Validate QR payload
  │     │     - Extract endpoint, token, TLS fingerprint
  │     ├─> Manual Entry (alternative)
  │     │     - Hostname/IP input
  │     │     - Port (default 18789)
  │     │     - TLS toggle
  │     │     - Token/password input
  │     ├─> Auto-Discovery (alternative)
  │     │     - Show discovered gateways
  │     │     - Select from list
  │     └─> Pairing Confirmation
  │           - Gateway name
  │           - Connection details
  │           - "Connect" CTA
  ├─> Connecting Screen
  │     - Animated connection indicator
  │     - Status messages
  │     - "Connecting to gateway..."
  ├─> Capability Showcase
  │     - Interactive tutorial (optional)
  │     - Demo node capabilities
  │     - Permission requests explained
  │     - "Try It" or "Skip"
  └─> Main Screen (Canvas)
```

### 2.2 Subsequent Launch Flow

```
Launch App
  ├─> Biometric Prompt (if enabled)
  │     - Face/Fingerprint authentication
  │     - PIN fallback option
  │     - Max 3 attempts, then lock
  ├─> Session Validation
  │     - Check SSO token validity
  │     - Refresh if expired
  │     - Fallback to login if refresh fails
  ├─> Auto-Reconnect
  │     - Connect to last-used gateway
  │     - Show connection status
  └─> Main Screen (Canvas)
```

### 2.3 Main Screen (Canvas) Layout

```
┌─────────────────────────────────────────┐
│ [Status Pill]          [Chat] [Talk] [⚙]│ <- Top overlay
├─────────────────────────────────────────┤
│                                         │
│                                         │
│           WebView Canvas                │
│        (interactive content)            │
│                                         │
│                                         │
│                                         │
│                                         │
└─────────────────────────────────────────┘

Status Pill (top-left):
  - Gateway connection indicator (green/yellow/red/gray)
  - Active instance name
  - Activity indicators (camera, screen recording, etc.)
  - Tap to open Settings

Top-right buttons:
  - Chat button: Open chat sheet
  - Talk button: Toggle talk mode (voice interaction)
  - Settings button: Open settings sheet
```

### 2.4 Settings Sheet Flow

```
Settings Sheet (Bottom sheet)
  ├─> Instance Management
  │     - Current instance name/icon
  │     - "Switch Instance" dropdown
  │     - Add new instance
  │     - Edit/remove instances
  ├─> Connection Settings
  │     - Gateway endpoint (read-only if discovered)
  │     - Manual connection toggle
  │     - Manual host/port/TLS
  │     - Reconnect button
  ├─> Node Capabilities
  │     - Display name
  │     - Camera enable/disable
  │     - Location mode (off/approximate/precise)
  │     - Screen sleep prevention
  │     - Voice wake mode
  │     - Talk mode toggle
  ├─> Security Settings
  │     - Biometric authentication toggle
  │     - Authentication timeout
  │     - View TLS fingerprint
  │     - Clear device token
  ├─> Permissions & Approvals
  │     - Permission history
  │     - Default approval policies
  │     - Approval timeout settings
  ├─> Account & SSO
  │     - Current user info
  │     - Sign out
  │     - Re-authenticate
  ├─> Diagnostics
  │     - Gateway status
  │     - Network info
  │     - Activity log
  │     - Export diagnostics
  └─> About
        - App version
        - Build info
        - Privacy policy
        - Terms of service
```

### 2.5 Chat Sheet Flow

```
Chat Sheet (Bottom sheet)
  ├─> Message List
  │     - User/assistant messages
  │     - Tool calls (expandable)
  │     - Streaming responses
  │     - Scroll to bottom
  ├─> Composer (bottom)
  │     - Text input
  │     - Attachment picker (photo, file)
  │     - Thinking level selector
  │     - Send button
  ├─> Session Management
  │     - Current session key/name
  │     - Switch session dropdown
  │     - New session
  │     - Session list/history
  └─> Chat Controls
        - Abort current response
        - Refresh chat
        - Clear conversation (with confirmation)
```

### 2.6 Permission Approval Flow

```
Permission Request (Dialog/Bottom sheet)
  ├─> Request Header
  │     - Icon (camera/location/screen/etc.)
  │     - Title: "Claude Code requests [permission]"
  ├─> Request Details
  │     - What: "Take a photo"
  │     - Why: "To analyze the image you're viewing"
  │     - Who: "Gateway: office-macbook"
  │     - When: "Just now"
  ├─> Context Preview (if applicable)
  │     - Camera preview
  │     - Location map
  │     - Screen preview
  ├─> Approval Options
  │     ├─> "Allow Once" (default)
  │     ├─> "Allow for Session"
  │     ├─> "Always Allow" (requires confirmation)
  │     └─> "Deny"
  ├─> Additional Options
  │     - "Don't ask again for this gateway"
  │     - "Remember my choice"
  └─> Action Buttons
        - "Deny" (secondary)
        - "Approve" (primary)
```

### 2.7 Instance Switching Flow

```
Instance Switcher (Dropdown or Sheet)
  ├─> Current Instance (highlighted)
  │     - Name, icon
  │     - Connection status
  ├─> Recent Instances
  │     - Last 3-5 used
  │     - Quick-switch
  ├─> All Instances (grouped)
  │     ├─> Favorites
  │     ├─> By Organization
  │     └─> Offline/Unavailable
  ├─> Add Instance
  │     - Scan QR
  │     - Manual entry
  │     - Discover gateways
  └─> Manage Instances
        - Edit instance details
        - Remove instance
        - Set default
```

### 2.8 QR Code Pairing Flow

```
QR Code Scanner
  ├─> Camera Preview
  │     - Overlay with scan frame
  │     - "Point camera at QR code"
  ├─> QR Detected
  │     - Parse QR payload
  │     - Validate schema
  │     - Extract: endpoint, token, TLS fingerprint, display name
  ├─> Pairing Preview
  │     - Show gateway details
  │     - "This will connect to:"
  │     - Name: "Office MacBook"
  │     - Host: office-mac.tailnet.ts.net
  │     - TLS: ✓ Enabled
  ├─> Security Confirmation
  │     - "Trust this gateway?"
  │     - Show TLS fingerprint (last 8 chars)
  │     - "Cancel" or "Trust & Connect"
  ├─> Connecting
  │     - Connection progress
  │     - Device authentication
  │     - Token exchange
  └─> Success or Error
        - Success: Switch to main screen
        - Error: Show error message, retry option
```

---

## 3. Technical Architecture

### 3.1 Technology Stack

**Language & Framework:**
- Kotlin 2.0+
- Android SDK 31+ (Android 12+)
- Target SDK 36 (Android 15)
- Jetpack Compose for UI (Material3)

**Architecture Pattern:**
- MVVM (Model-View-ViewModel)
- Single Activity + Compose Navigation
- StateFlow for reactive state management
- Kotlin Coroutines for concurrency

**Key Libraries:**
- **Networking**: OkHttp 5.x (WebSocket, HTTP), Retrofit 2.x (REST)
- **Serialization**: kotlinx-serialization-json
- **Security**: AndroidX Security Crypto (EncryptedSharedPreferences), Biometric API
- **Camera**: AndroidX CameraX 1.5+
- **QR Scanning**: ML Kit Barcode Scanning or ZXing
- **SSO/OAuth**: AppAuth-Android library
- **DI**: Koin or Dagger Hilt (optional, current app uses manual DI)
- **Logging**: Timber
- **Testing**: JUnit 5, Kotest, MockK, Robolectric, Espresso

### 3.2 Architecture Layers

```
┌─────────────────────────────────────────────────────────┐
│                    UI Layer (Compose)                   │
│  ┌─────────────┐  ┌──────────────┐  ┌───────────────┐  │
│  │ MainActivity│  │ RootScreen   │  │ Bottom Sheets │  │
│  │             │  │ (Canvas+HUD) │  │ (Chat/Settings)│  │
│  └──────┬──────┘  └──────┬───────┘  └───────┬───────┘  │
│         └────────────────┼──────────────────┘           │
└──────────────────────────┼──────────────────────────────┘
                           │
┌──────────────────────────┼──────────────────────────────┐
│                   ViewModel Layer                        │
│  ┌────────────────┐  ┌──────────────┐  ┌─────────────┐ │
│  │  MainViewModel │  │ AuthViewModel│  │ InstViewModel│ │
│  │  (StateFlow)   │  │              │  │             │ │
│  └────────┬───────┘  └──────┬───────┘  └──────┬──────┘ │
│           └──────────────────┼──────────────────┘        │
└──────────────────────────────┼──────────────────────────┘
                               │
┌──────────────────────────────┼──────────────────────────┐
│                     Domain Layer                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │ Use Cases (Interactors)                          │   │
│  │ - ConnectToGatewayUseCase                       │   │
│  │ - AuthenticateUserUseCase                       │   │
│  │ - HandlePermissionRequestUseCase                │   │
│  │ - SwitchInstanceUseCase                         │   │
│  └───────────────────────────┬─────────────────────┘   │
└──────────────────────────────┼──────────────────────────┘
                               │
┌──────────────────────────────┼──────────────────────────┐
│                     Data Layer                           │
│  ┌─────────────┐  ┌────────────┐  ┌──────────────────┐ │
│  │ Repositories│  │ Data Sources│ │ Local Storage    │ │
│  │ - Gateway   │  │ - Remote    │ │ - EncryptedPrefs │ │
│  │ - Auth      │  │ - Local     │ │ - Room DB        │ │
│  │ - Instances │  │             │ │ - KeyStore       │ │
│  └──────┬──────┘  └──────┬─────┘  └────────┬─────────┘ │
│         └─────────────────┼──────────────────┘           │
└──────────────────────────┼──────────────────────────────┘
                           │
┌──────────────────────────┼──────────────────────────────┐
│              Infrastructure Layer                        │
│  ┌──────────────┐  ┌───────────┐  ┌─────────────────┐  │
│  │ Network      │  │ Security  │  │ Platform        │  │
│  │ - OkHttp     │  │ - TLS     │  │ - Biometric API │  │
│  │ - WebSocket  │  │ - Crypto  │  │ - CameraX       │  │
│  │ - Retrofit   │  │ - KeyStore│  │ - WorkManager   │  │
│  └──────────────┘  └───────────┘  └─────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

### 3.3 Module Structure

```
app/
├── src/main/java/ai/openclaw/android/
│   ├── ui/                          # Compose UI components
│   │   ├── theme/                   # Material3 theme
│   │   ├── screens/                 # Screen-level composables
│   │   │   ├── main/                # Main canvas screen
│   │   │   ├── onboarding/          # Onboarding flow
│   │   │   ├── auth/                # SSO/biometric screens
│   │   │   └── settings/            # Settings screens
│   │   ├── components/              # Reusable components
│   │   │   ├── StatusPill.kt
│   │   │   ├── PermissionDialog.kt
│   │   │   ├── InstanceSwitcher.kt
│   │   │   └── QRScanner.kt
│   │   └── sheets/                  # Bottom sheets
│   │       ├── ChatSheet.kt
│   │       └── SettingsSheet.kt
│   ├── viewmodel/                   # ViewModels
│   │   ├── MainViewModel.kt
│   │   ├── AuthViewModel.kt
│   │   ├── InstanceViewModel.kt
│   │   └── PermissionViewModel.kt
│   ├── domain/                      # Business logic
│   │   ├── model/                   # Domain models
│   │   ├── repository/              # Repository interfaces
│   │   └── usecase/                 # Use cases
│   ├── data/                        # Data layer
│   │   ├── repository/              # Repository implementations
│   │   ├── source/                  # Data sources
│   │   │   ├── remote/              # Network sources
│   │   │   └── local/               # Local sources
│   │   ├── model/                   # Data models (DTOs)
│   │   └── db/                      # Room database
│   ├── gateway/                     # Gateway protocol (existing)
│   │   ├── GatewaySession.kt
│   │   ├── GatewayDiscovery.kt
│   │   ├── GatewayProtocol.kt
│   │   ├── DeviceIdentityStore.kt
│   │   └── DeviceAuthStore.kt
│   ├── security/                    # Security utilities
│   │   ├── BiometricManager.kt
│   │   ├── CertificatePinner.kt
│   │   ├── EncryptionHelper.kt
│   │   └── KeyStoreManager.kt
│   ├── auth/                        # Authentication
│   │   ├── SsoManager.kt
│   │   ├── OAuthHandler.kt
│   │   └── TokenManager.kt
│   ├── instance/                    # Instance management
│   │   ├── InstanceManager.kt
│   │   ├── InstanceStore.kt
│   │   └── InstanceSwitcher.kt
│   ├── permission/                  # Permission system
│   │   ├── PermissionManager.kt
│   │   ├── PermissionStore.kt
│   │   └── ApprovalHandler.kt
│   ├── node/                        # Node capabilities (existing)
│   │   ├── CameraCaptureManager.kt
│   │   ├── ScreenRecordManager.kt
│   │   ├── LocationCaptureManager.kt
│   │   ├── SmsManager.kt
│   │   └── CanvasController.kt
│   ├── mdm/                         # MDM integration
│   │   ├── ManagedConfigReceiver.kt
│   │   ├── ConfigSchema.kt
│   │   └── ComplianceChecker.kt
│   ├── util/                        # Utilities
│   │   ├── QRCodeParser.kt
│   │   ├── NetworkMonitor.kt
│   │   ├── Logger.kt
│   │   └── Extensions.kt
│   └── MainActivity.kt
└── src/test/                        # Unit tests
```

### 3.4 Data Models

**Instance:**
```kotlin
data class Instance(
    val id: String,                    // UUID
    val name: String,                  // Display name
    val iconUrl: String?,              // Optional custom icon
    val endpoint: GatewayEndpoint,     // Connection details
    val isFavorite: Boolean = false,
    val organization: String?,         // Grouping
    val ssoRequired: Boolean = false,
    val lastConnected: Long?,          // Timestamp
    val isDefault: Boolean = false
)
```

**GatewayEndpoint (existing, enhanced):**
```kotlin
data class GatewayEndpoint(
    val stableId: String,
    val name: String,
    val host: String,
    val port: Int,
    val lanHost: String?,
    val tailnetDns: String?,
    val gatewayPort: Int?,
    val canvasPort: Int?,
    val tlsEnabled: Boolean,
    val tlsFingerprintSha256: String?,
    // New fields:
    val requiresSso: Boolean = false,
    val ssoProvider: String? = null,   // "azure", "okta", "google"
    val discoveryMethod: DiscoveryMethod = DiscoveryMethod.LOCAL
)

enum class DiscoveryMethod {
    LOCAL,      // mDNS/Bonjour
    WIDE_AREA,  // DNS-SD
    QR_CODE,    // Scanned QR
    MANUAL      // User-entered
}
```

**PermissionRequest:**
```kotlin
data class PermissionRequest(
    val id: String,                    // Request ID
    val gatewayId: String,             // Source gateway
    val permission: PermissionType,
    val reason: String?,               // Why this is needed
    val context: String?,              // Additional context
    val timestamp: Long,
    val expiresAt: Long?,              // Request expiry
    val status: ApprovalStatus = ApprovalStatus.PENDING
)

enum class PermissionType {
    CAMERA_PHOTO,
    CAMERA_VIDEO,
    SCREEN_RECORD,
    LOCATION_PRECISE,
    LOCATION_APPROXIMATE,
    SMS_SEND,
    FILE_READ,
    FILE_WRITE
}

enum class ApprovalStatus {
    PENDING,
    APPROVED,
    DENIED,
    EXPIRED
}
```

**BiometricConfig:**
```kotlin
data class BiometricConfig(
    val enabled: Boolean,
    val allowedAuthenticators: Int,    // BIOMETRIC_STRONG, BIOMETRIC_WEAK, DEVICE_CREDENTIAL
    val timeoutMinutes: Int = 5,       // Re-auth timeout
    val maxAttempts: Int = 3
)
```

**SsoConfig:**
```kotlin
data class SsoConfig(
    val provider: SsoProvider,
    val clientId: String,
    val redirectUri: String,
    val scopes: List<String>,
    val discoveryUri: String?,         // OIDC discovery
    val authEndpoint: String?,
    val tokenEndpoint: String?,
    val issuer: String?
)

enum class SsoProvider {
    AZURE_AD,
    OKTA,
    GOOGLE,
    PING_IDENTITY,
    GENERIC_OIDC,
    SAML
}
```

---

## 4. Security Implementation

### 4.1 Biometric Authentication

**Implementation:**
- Use AndroidX Biometric library (`androidx.biometric:biometric:1.2.0`)
- `BiometricPrompt` API for unified face/fingerprint/PIN
- Cryptographic key management via Android KeyStore
- Class 3 (Strong) biometric requirement for production

**Flow:**
```kotlin
class BiometricManager(private val context: Context) {
    private val executor = ContextCompat.getMainExecutor(context)

    suspend fun authenticate(
        title: String,
        subtitle: String,
        allowDeviceCredential: Boolean = true
    ): BiometricResult = suspendCancellableCoroutine { cont ->
        val promptInfo = BiometricPrompt.PromptInfo.Builder()
            .setTitle(title)
            .setSubtitle(subtitle)
            .setAllowedAuthenticators(
                if (allowDeviceCredential) {
                    BIOMETRIC_STRONG or DEVICE_CREDENTIAL
                } else {
                    BIOMETRIC_STRONG
                }
            )
            .build()

        val biometricPrompt = BiometricPrompt(
            activity,
            executor,
            object : BiometricPrompt.AuthenticationCallback() {
                override fun onAuthenticationSucceeded(
                    result: BiometricPrompt.AuthenticationResult
                ) {
                    cont.resume(BiometricResult.Success)
                }

                override fun onAuthenticationFailed() {
                    // Don't resume; allow retry
                }

                override fun onAuthenticationError(
                    errorCode: Int,
                    errString: CharSequence
                ) {
                    cont.resume(BiometricResult.Error(errorCode, errString.toString()))
                }
            }
        )

        biometricPrompt.authenticate(promptInfo)
    }
}
```

**Key Storage:**
- Use Android KeyStore for biometric-protected keys
- Generate encryption keys with `setUserAuthenticationRequired(true)`
- Keys invalidated on biometric enrollment change

### 4.2 SSO Integration

**OAuth2/OIDC Implementation:**
- Use AppAuth library for OAuth2 flows
- Support Authorization Code flow with PKCE
- Handle token refresh automatically
- Secure token storage in EncryptedSharedPreferences

**AppAuth Flow:**
```kotlin
class SsoManager(
    private val context: Context,
    private val config: SsoConfig
) {
    private val authService = AuthorizationService(context)

    suspend fun authenticate(): AuthResult {
        val serviceConfig = AuthorizationServiceConfiguration(
            Uri.parse(config.authEndpoint),
            Uri.parse(config.tokenEndpoint)
        )

        val authRequest = AuthorizationRequest.Builder(
            serviceConfig,
            config.clientId,
            ResponseTypeValues.CODE,
            Uri.parse(config.redirectUri)
        )
            .setScopes(config.scopes)
            .setCodeVerifier(generateCodeVerifier())
            .build()

        // Launch browser for auth
        val intent = authService.getAuthorizationRequestIntent(authRequest)
        // ... handle redirect via Activity result
    }

    suspend fun refreshToken(refreshToken: String): TokenResponse? {
        // Token refresh logic
    }
}
```

**SAML Support:**
- Use WebView for SAML flow (no native library)
- Intercept redirect URL to extract SAML response
- Parse and validate SAML assertion
- Convert to session token

### 4.3 Certificate Pinning

**Enhanced TLS Implementation:**
- Pin gateway certificates by SHA-256 fingerprint
- Support multiple fingerprints per gateway (rotation)
- Trust enterprise root CA when deployed via MDM
- Fallback to system trust store for non-pinned hosts

**OkHttp Certificate Pinner:**
```kotlin
class CertificatePinner(
    private val pinnedFingerprints: Map<String, List<String>>,
    private val enterpriseCaCerts: List<X509Certificate>?
) {
    fun buildOkHttpClient(): OkHttpClient {
        val trustManager = buildTrustManager()
        val sslContext = SSLContext.getInstance("TLS")
        sslContext.init(null, arrayOf(trustManager), null)

        return OkHttpClient.Builder()
            .sslSocketFactory(sslContext.socketFactory, trustManager)
            .hostnameVerifier { hostname, session ->
                // Custom hostname verification
                verifyFingerprint(hostname, session.peerCertificates)
            }
            .build()
    }

    private fun verifyFingerprint(
        hostname: String,
        certs: Array<Certificate>
    ): Boolean {
        val expectedFingerprints = pinnedFingerprints[hostname] ?: return true
        val actualFingerprint = calculateSha256(certs[0].encoded)
        return expectedFingerprints.any { it.equals(actualFingerprint, ignoreCase = true) }
    }

    private fun calculateSha256(bytes: ByteArray): String {
        val digest = MessageDigest.getInstance("SHA-256")
        return digest.digest(bytes).joinToString("") {
            "%02x".format(it)
        }
    }
}
```

### 4.4 Data Encryption

**EncryptedSharedPreferences:**
- Use for sensitive data (tokens, passwords, keys)
- AES256-GCM encryption via Security Crypto library
- Automatic key generation and management

**Room Database Encryption:**
- SQLCipher for encrypted Room database
- Store instance configs, permission history, audit logs
- Key derived from biometric-protected KeyStore key

### 4.5 Secure Communication

**WebSocket Security:**
- TLS 1.2+ required
- Certificate pinning enforced
- Device authentication via ED25519 signatures (existing)
- Token-based authorization (existing)
- Nonce-based challenge-response for non-loopback (existing)

**Anti-Tampering:**
- Detect rooted devices (SafetyNet/Play Integrity API)
- Warn on debuggable builds
- Detect hook frameworks (Xposed, Frida)
- Certificate transparency checks

---

## 5. SSO Integration Plan

### 5.1 Supported Providers

**Priority 1 (MVP):**
- Azure AD / Microsoft Entra ID (OAuth2/OIDC)
- Google Workspace (OAuth2/OIDC)
- Okta (OAuth2/OIDC)

**Priority 2 (Post-MVP):**
- Ping Identity (OIDC)
- Auth0 (OIDC)
- Generic SAML 2.0

### 5.2 OAuth2/OIDC Flow

**Authorization Code + PKCE:**
1. App generates code verifier and challenge
2. User redirected to provider's auth endpoint
3. User authenticates with provider (browser or WebView)
4. Provider redirects to app with authorization code
5. App exchanges code for access/refresh tokens
6. App validates ID token (JWT signature, issuer, audience)
7. App stores tokens securely
8. App uses access token for gateway authentication

**Token Lifecycle:**
- Access token: Short-lived (15-60 minutes)
- Refresh token: Long-lived (days/weeks)
- Auto-refresh before expiry
- Revoke on sign-out

### 5.3 SAML Flow

**SAML 2.0 SP-Initiated:**
1. App constructs SAML AuthnRequest
2. User redirected to IdP's SSO endpoint (WebView)
3. User authenticates with IdP
4. IdP posts SAML response to app redirect URL
5. App validates SAML assertion (signature, conditions)
6. App extracts user attributes and session token
7. App stores session token securely

**Challenges:**
- No native SAML library for Android
- WebView required for IdP interaction
- Complex XML parsing and validation
- Certificate management for assertion validation

### 5.4 Token Management

**Secure Storage:**
- Access token: EncryptedSharedPreferences
- Refresh token: EncryptedSharedPreferences (biometric-protected)
- ID token: EncryptedSharedPreferences

**Refresh Strategy:**
- Proactive refresh 5 minutes before expiry
- Reactive refresh on 401 errors
- Retry with exponential backoff
- Fallback to re-authentication on refresh failure

### 5.5 Device Compliance

**Conditional Access:**
- Report device compliance state to provider (Azure AD)
- Enforce device compliance policies (Intune)
- Block access on non-compliant devices
- Trigger re-authentication on compliance change

**Compliance Checks:**
- Device encryption enabled
- Screen lock configured
- Biometric enrollment (if required)
- Device not rooted
- App version up-to-date

---

## 6. QR Onboarding Flow

### 6.1 QR Code Schema

**JSON Payload (Base64-encoded):**
```json
{
  "version": 1,
  "gateway": {
    "name": "Office MacBook",
    "host": "office-mac.tailnet.ts.net",
    "port": 18789,
    "tls": {
      "enabled": true,
      "fingerprint": "a3b5c7d9e1f3a5b7c9d1e3f5a7b9c1d3e5f7a9b1c3d5e7f9a1b3c5d7e9f1a3b5"
    },
    "canvas_port": 18793
  },
  "auth": {
    "token": "gw_abc123def456...",
    "expires_at": 1704067200
  },
  "sso": {
    "required": false
  }
}
```

**QR Format:**
- Prefix: `openclaw://pair?data=`
- Base64-encoded JSON payload
- Max size: ~1KB (QR version 10)

### 6.2 Scanning Implementation

**ML Kit Barcode Scanning:**
```kotlin
class QRScanner(private val context: Context) {
    private val scanner = BarcodeScanning.getClient()

    fun scanQR(
        imageProxy: ImageProxy,
        onSuccess: (PairingData) -> Unit,
        onError: (String) -> Unit
    ) {
        val mediaImage = imageProxy.image ?: return
        val inputImage = InputImage.fromMediaImage(
            mediaImage,
            imageProxy.imageInfo.rotationDegrees
        )

        scanner.process(inputImage)
            .addOnSuccessListener { barcodes ->
                barcodes.firstOrNull()?.rawValue?.let { raw ->
                    parseQRPayload(raw, onSuccess, onError)
                }
            }
            .addOnFailureListener { e ->
                onError("Scan failed: ${e.message}")
            }
            .addOnCompleteListener {
                imageProxy.close()
            }
    }

    private fun parseQRPayload(
        raw: String,
        onSuccess: (PairingData) -> Unit,
        onError: (String) -> Unit
    ) {
        if (!raw.startsWith("openclaw://pair?data=")) {
            onError("Invalid QR code")
            return
        }

        val base64Data = raw.removePrefix("openclaw://pair?data=")
        val jsonData = String(Base64.decode(base64Data, Base64.DEFAULT))

        try {
            val payload = Json.decodeFromString<PairingPayload>(jsonData)
            onSuccess(payload.toPairingData())
        } catch (e: Exception) {
            onError("Invalid QR data: ${e.message}")
        }
    }
}
```

### 6.3 Security Considerations

**QR Validation:**
- Verify schema version
- Validate gateway host/port
- Check token expiry
- Require user confirmation before connecting

**Token Expiry:**
- Pairing tokens expire after 15 minutes (configurable)
- Single-use tokens preferred
- Gateway validates token on connect

**User Confirmation:**
- Show gateway details before pairing
- Display TLS fingerprint (last 8 chars)
- Require explicit "Trust & Connect" action

### 6.4 Bulk Enrollment

**Enterprise QR Codes:**
- Pre-provisioned QR codes for fleet deployment
- Reusable tokens for same-org devices
- MDM-pushed QR data via managed app config
- Silent pairing with admin approval

---

## 7. Permission Approval UI

### 7.1 Permission Types & Contexts

**Camera:**
- Context: "Take a photo", "Record video"
- Preview: Live camera preview in dialog
- Options: Allow once, Allow for session, Always allow

**Screen Recording:**
- Context: "Share your screen", "Record screen activity"
- Preview: Current screen thumbnail
- Warning: "Claude Code will see everything on your screen"

**Location:**
- Context: "Get your location", "Find nearby places"
- Preview: Map with current location pin
- Granularity: Precise vs. Approximate

**SMS:**
- Context: "Send SMS to [number]"
- Preview: Message content
- Warning: "This will send a real SMS and may incur charges"

**File Access:**
- Context: "Read file [name]", "Save file [name]"
- Preview: File path, type, size
- Options: Allow once, Allow for folder

### 7.2 Approval Dialog Design

**Layout:**
```
┌─────────────────────────────────────────┐
│ [Icon]   Claude Code requests           │
│          Camera Access                  │
├─────────────────────────────────────────┤
│                                         │
│ [Camera Preview or Icon]                │
│                                         │
│ What: Take a photo                      │
│ Why: To analyze the image you're viewing│
│ Gateway: Office MacBook                 │
│ Time: Just now                          │
│                                         │
├─────────────────────────────────────────┤
│ ☐ Remember my choice                   │
├─────────────────────────────────────────┤
│                  [Deny]     [Approve]   │
└─────────────────────────────────────────┘
```

**Approval Modes:**
- **Allow Once**: Approved for this single operation
- **Allow for Session**: Approved until gateway disconnect
- **Always Allow**: Approved permanently (requires confirmation)
- **Deny**: Rejected; gateway notified

### 7.3 Permission History

**Audit Log:**
- All permission requests logged
- Includes: timestamp, gateway, permission type, decision, reason
- Exportable to CSV/JSON
- Filterable by gateway, type, date

**Log Entry:**
```kotlin
data class PermissionLogEntry(
    val id: String,
    val timestamp: Long,
    val gatewayId: String,
    val gatewayName: String,
    val permissionType: PermissionType,
    val context: String?,
    val decision: ApprovalStatus,
    val approvalMode: ApprovalMode?,
    val userReason: String?
)

enum class ApprovalMode {
    ONCE,
    SESSION,
    ALWAYS
}
```

### 7.4 Default Policies

**Admin-Configurable:**
- Auto-approve camera for trusted gateways
- Auto-deny SMS for all gateways
- Require confirmation for screen recording
- Allow location only during active session

**Policy Schema (MDM):**
```json
{
  "permission_policies": {
    "camera": {
      "default": "prompt",
      "trusted_gateways": ["gateway-id-1", "gateway-id-2"],
      "require_confirmation": true
    },
    "screen_record": {
      "default": "deny",
      "allow_for_gateways": []
    },
    "location": {
      "default": "prompt",
      "granularity": "approximate"
    }
  }
}
```

---

## 8. Multi-Instance UX

### 8.1 Instance Data Model

**Instance Profile:**
- Unique ID (UUID)
- Display name
- Custom icon (URL or emoji)
- Gateway endpoint details
- Connection state (connected/disconnected/error)
- Last connected timestamp
- Organization/team grouping
- Favorite flag
- Default flag

**Instance Storage:**
- Room database for persistence
- EncryptedSharedPreferences for sensitive data (tokens, passwords)
- In-memory cache for active instance state

### 8.2 Instance Switcher UI

**Dropdown (Top Bar):**
```
┌─────────────────────────────────────────┐
│ [≡] Office MacBook ▾                    │ <- Tap to expand
├─────────────────────────────────────────┤
│ ✓ Office MacBook         [Connected]   │ <- Current
│   Home Server             [Offline]     │
│   Dev Gateway             [Connected]   │
│   ──────────────────────────────────    │
│   + Add Instance                        │
│   ⚙ Manage Instances                    │
└─────────────────────────────────────────┘
```

**Instance List (Bottom Sheet):**
```
Instances
  ├─> Favorites (⭐)
  │     - Office MacBook [Connected]
  │     - Home Server [Offline]
  ├─> Acme Corp
  │     - Dev Gateway [Connected]
  │     - Staging Gateway [Disconnected]
  ├─> Personal
  │     - Tailnet Gateway [Connected]
  └─> Actions
        - Add Instance (QR/Manual/Discover)
        - Manage Instances
```

### 8.3 Switching Behavior

**State Preservation:**
- Disconnect from current gateway gracefully
- Save current instance state (scroll position, chat session, etc.)
- Connect to new instance (if online)
- Restore new instance state
- Show switching animation (fade or slide)

**Background Behavior:**
- Keep only current instance connected
- Disconnect background instances to save resources
- Maintain discovery for available gateways

### 8.4 Instance Management

**Add Instance:**
- Scan QR code
- Manual entry (host, port, TLS, token)
- Auto-discovery (select from list)
- Import from clipboard/URL

**Edit Instance:**
- Change display name
- Update icon
- Modify connection details
- Toggle favorite
- Set as default

**Remove Instance:**
- Confirmation dialog
- Clear stored credentials
- Remove from instance list
- Cannot remove if currently connected

---

## 9. Capability Showcase

### 9.1 Onboarding Tutorial

**Interactive Demo:**
- 5-7 slides/screens showcasing key features
- Skip option on every screen
- Progress indicator
- Optional "Try It" actions

**Tutorial Screens:**

**Screen 1: Welcome**
- Hero image/animation
- "Welcome to EnterpriseClaw"
- "Your secure mobile companion for Claude Code"
- CTA: "Get Started"

**Screen 2: Security**
- Biometric icon
- "Enterprise-grade security"
- "Biometric authentication, SSO, and encrypted communication"
- Preview: Fingerprint animation

**Screen 3: Capabilities**
- Icon grid (camera, location, screen, SMS)
- "Powerful device capabilities"
- "Claude Code can use your camera, location, and more—with your permission"
- Preview: Permission dialog

**Screen 4: Multi-Instance**
- Instance switcher mockup
- "Manage multiple Claude Code instances"
- "Switch between work, home, and team gateways"
- Preview: Instance list

**Screen 5: Chat**
- Chat interface mockup
- "Chat with Claude Code on the go"
- "Ask questions, get help, and control your devices"
- Preview: Chat message thread

**Screen 6: Ready**
- Checkmark icon
- "You're all set!"
- "Scan a QR code to connect to your first gateway"
- CTA: "Scan QR Code" or "Connect Manually"

### 9.2 Demo Mode (Optional)

**Simulated Gateway:**
- No real connection required
- Pre-canned responses and interactions
- Demonstrate capabilities without setup
- Safe for demos and screenshots

**Demo Scenarios:**
- Camera: "Take a photo of this screen"
- Location: "Where am I?"
- Screen: "Record my screen for 10 seconds"
- Chat: "What can you do?"

### 9.3 Permission Education

**Rationale Dialogs:**
- Explain why each permission is needed
- Show examples of how it's used
- Reassure about privacy and security
- Option to decline gracefully

**Example: Camera Permission**
```
We need camera access to:
  ✓ Take photos when you ask Claude Code
  ✓ Scan QR codes for pairing
  ✓ Analyze images you want help with

Your privacy matters:
  ✓ Photos are only taken when you approve
  ✓ Images are processed securely
  ✓ No photos are stored permanently
```

---

## 10. Testing Strategy

### 10.1 Unit Tests

**Target Coverage:** 70%+ (lines, branches, functions, statements)

**Key Areas:**
- ViewModel logic (StateFlow updates, use case calls)
- Repository implementations (data transformation, error handling)
- Gateway protocol (message parsing, connection state)
- Security utilities (encryption, signature verification)
- Permission logic (approval, policy evaluation)
- Instance management (switching, storage)

**Frameworks:**
- JUnit 5 (test runner)
- Kotest (assertions, property-based testing)
- MockK (mocking)
- kotlinx-coroutines-test (coroutine testing)
- Robolectric (Android framework mocking)

**Example:**
```kotlin
class InstanceViewModelTest {
    private lateinit var viewModel: InstanceViewModel
    private val mockRepository = mockk<InstanceRepository>()

    @Test
    fun `switchInstance updates currentInstance state`() = runTest {
        val instance = Instance(id = "test-id", name = "Test Gateway")
        coEvery { mockRepository.getInstanceById("test-id") } returns instance

        viewModel.switchInstance("test-id")

        assertEquals(instance, viewModel.currentInstance.value)
        coVerify { mockRepository.getInstanceById("test-id") }
    }
}
```

### 10.2 UI Tests (Instrumented)

**Framework:** Espresso, Compose Testing

**Key Scenarios:**
- Onboarding flow (complete)
- QR scanning and pairing
- Instance switching
- Chat interaction (send message, view response)
- Permission approval dialog
- Settings changes
- Biometric prompt (mocked)

**Example:**
```kotlin
@Test
fun testQRScanningFlow() {
    // Launch QR scanner
    composeTestRule.onNodeWithText("Scan QR Code").performClick()

    // Simulate QR detection
    activityRule.scenario.onActivity { activity ->
        activity.onQRDetected(validQRPayload)
    }

    // Verify pairing preview shown
    composeTestRule.onNodeWithText("Office MacBook").assertIsDisplayed()

    // Approve pairing
    composeTestRule.onNodeWithText("Trust & Connect").performClick()

    // Verify main screen shown
    composeTestRule.onNodeWithTag("canvas_view").assertIsDisplayed()
}
```

### 10.3 Integration Tests

**Gateway Integration:**
- Test against local mock gateway
- Verify WebSocket connection, authentication, message exchange
- Test disconnect/reconnect scenarios
- Test certificate pinning

**SSO Integration:**
- Mock OAuth2 provider (WireMock)
- Test token acquisition, refresh, revocation
- Test error scenarios (invalid token, expired token)

**Database Integration:**
- Test Room database CRUD operations
- Test migrations (if schema changes)
- Test encryption (SQLCipher)

### 10.4 Security Testing

**Static Analysis:**
- Android Lint (security checks)
- Detekt (code quality)
- Dependency vulnerability scanning (OWASP, Snyk)

**Dynamic Analysis:**
- Manual penetration testing
- Traffic interception (verify TLS, certificate pinning)
- Root/jailbreak detection testing
- Key extraction attempts

**Compliance:**
- OWASP Mobile Top 10 checks
- GDPR data handling review
- SOC 2 security control verification

### 10.5 Performance Testing

**Metrics:**
- App startup time (<2s cold start)
- WebView load time (<1s)
- Instance switch time (<500ms)
- Memory usage (<200MB typical)
- Battery drain (<5% per hour active use)

**Profiling:**
- Android Profiler (CPU, memory, network)
- StrictMode for main thread violations
- LeakCanary for memory leaks

### 10.6 Accessibility Testing

**Tools:**
- Android Accessibility Scanner
- TalkBack testing
- Large text/display scaling

**Checks:**
- Content descriptions for all interactive elements
- Sufficient touch target sizes (48dp minimum)
- Color contrast ratios (WCAG AA)
- Keyboard navigation support

---

## 11. Android Enterprise Integration

### 11.1 Managed App Configuration

**AppConfig Schema:**
```xml
<managedAppConfiguration>
  <config>
    <!-- Gateway Configuration -->
    <entry key="gateway_host" type="string" />
    <entry key="gateway_port" type="integer" defaultValue="18789" />
    <entry key="gateway_tls_enabled" type="bool" defaultValue="true" />
    <entry key="gateway_tls_fingerprint" type="string" />
    <entry key="auto_connect" type="bool" defaultValue="false" />

    <!-- SSO Configuration -->
    <entry key="sso_enabled" type="bool" defaultValue="false" />
    <entry key="sso_provider" type="choice" defaultValue="azure">
      <choice value="azure">Azure AD</choice>
      <choice value="okta">Okta</choice>
      <choice value="google">Google</choice>
    </entry>
    <entry key="sso_client_id" type="string" />
    <entry key="sso_discovery_uri" type="string" />

    <!-- Security Policies -->
    <entry key="require_biometric" type="bool" defaultValue="true" />
    <entry key="biometric_timeout_minutes" type="integer" defaultValue="5" />
    <entry key="allow_rooted_devices" type="bool" defaultValue="false" />

    <!-- Permission Policies -->
    <entry key="auto_approve_camera" type="bool" defaultValue="false" />
    <entry key="auto_deny_sms" type="bool" defaultValue="false" />
    <entry key="default_location_mode" type="choice" defaultValue="prompt">
      <choice value="deny">Deny</choice>
      <choice value="prompt">Prompt</choice>
      <choice value="approximate">Allow (Approximate)</choice>
      <choice value="precise">Allow (Precise)</choice>
    </entry>
  </config>
</managedAppConfiguration>
```

**Receiving Configuration:**
```kotlin
class ManagedConfigReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == ACTION_APPLICATION_RESTRICTIONS_CHANGED) {
            val restrictions = context.getSystemService(RestrictionsManager::class.java)
                ?.applicationRestrictions
            applyManagedConfig(restrictions)
        }
    }

    private fun applyManagedConfig(config: Bundle?) {
        config ?: return

        val gatewayHost = config.getString("gateway_host")
        val gatewayPort = config.getInt("gateway_port", 18789)
        val tlsEnabled = config.getBoolean("gateway_tls_enabled", true)

        // Apply configuration to app settings
        // ...
    }
}
```

### 11.2 Work Profile Support

**Profile Separation:**
- Separate work and personal instances
- Work profile badge on app icon
- Data isolation between profiles
- DLP (Data Loss Prevention) policies enforced

**Work Profile Detection:**
```kotlin
fun isWorkProfile(context: Context): Boolean {
    val userManager = context.getSystemService(UserManager::class.java)
    return userManager?.isManagedProfile == true
}
```

### 11.3 Compliance Policies

**Device Compliance Checks:**
- Screen lock enabled (PIN/pattern/password/biometric)
- Device encryption enabled
- Device not rooted
- App version up-to-date
- Certificate validity

**Enforcement:**
```kotlin
class ComplianceChecker(private val context: Context) {
    fun checkCompliance(): ComplianceResult {
        val issues = mutableListOf<ComplianceIssue>()

        // Check screen lock
        val keyguardManager = context.getSystemService(KeyguardManager::class.java)
        if (!keyguardManager.isDeviceSecure) {
            issues.add(ComplianceIssue.SCREEN_LOCK_DISABLED)
        }

        // Check encryption
        val devicePolicyManager = context.getSystemService(DevicePolicyManager::class.java)
        if (devicePolicyManager.storageEncryptionStatus !=
            DevicePolicyManager.ENCRYPTION_STATUS_ACTIVE) {
            issues.add(ComplianceIssue.ENCRYPTION_DISABLED)
        }

        // Check root
        if (isDeviceRooted()) {
            issues.add(ComplianceIssue.DEVICE_ROOTED)
        }

        return if (issues.isEmpty()) {
            ComplianceResult.Compliant
        } else {
            ComplianceResult.NonCompliant(issues)
        }
    }
}
```

### 11.4 Remote Management

**Supported Actions:**
- Remote wipe (app data only)
- Remote lock (require re-authentication)
- Remote disable (prevent app launch)
- Remote config update

**Implementation:**
```kotlin
class RemoteManagementReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            ACTION_REMOTE_WIPE -> {
                wipeAppData(context)
            }
            ACTION_REMOTE_LOCK -> {
                lockApp(context)
            }
        }
    }

    private fun wipeAppData(context: Context) {
        // Clear EncryptedSharedPreferences
        // Clear Room database
        // Clear KeyStore keys
        // Sign out of SSO
        // Restart app
    }
}
```

### 11.5 MDM Vendor Support

**Microsoft Intune:**
- Managed app configuration via Intune policy
- Conditional access enforcement
- App protection policies (APP)
- Certificate deployment via SCEP/PFX

**VMware Workspace ONE:**
- SDK integration for app tunneling (optional)
- App wrapping for DLP
- Console integration

**MobileIron:**
- AppConnect SDK (optional)
- App configuration via AppConnect

---

## 12. Additional Considerations

### 12.1 Offline Capability

**Offline Features:**
- Cached canvas content (read-only)
- Previous chat history (read-only)
- Settings access
- Instance management (no connection required)
- Diagnostics and logs

**Offline Indicator:**
- Persistent banner: "No connection to gateway"
- Gray status pill
- Disabled send button in chat

**Reconnection Strategy:**
- Automatic reconnection on network restore
- Exponential backoff (350ms * 1.7^attempt, max 8s)
- User-initiated manual reconnect

### 12.2 Accessibility

**Compliance:**
- WCAG 2.1 Level AA
- Android Accessibility Guidelines
- TalkBack support
- Switch Access support

**Features:**
- Screen reader support (content descriptions)
- Keyboard navigation
- Large text support (up to 200%)
- High contrast mode
- Touch target sizes (48dp minimum)
- Focus indicators

### 12.3 Internationalization (i18n)

**Languages (Phase 1):**
- English (US, UK)
- Spanish (ES, MX)
- French (FR)
- German (DE)
- Japanese (JP)
- Chinese (ZH-CN, ZH-TW)

**Implementation:**
- Android `strings.xml` resources per locale
- RTL layout support (Arabic, Hebrew)
- Locale-aware date/time formatting
- Plurals and quantity strings
- Dynamic string formatting

### 12.4 Analytics & Telemetry

**Privacy-First Analytics:**
- No PII collection
- Opt-in telemetry
- Crash reporting (Firebase Crashlytics or Sentry)
- Anonymous usage metrics

**Metrics:**
- App launches
- Feature usage (camera, screen record, etc.)
- Error rates
- Connection success/failure rates
- Performance metrics (startup time, memory)

**User Controls:**
- Opt-in/opt-out in settings
- Clear privacy policy
- Ability to export/delete data

### 12.5 Battery & Performance

**Optimization:**
- Doze mode compatibility
- WorkManager for background tasks (discovery)
- Foreground service only when connected
- WebView memory management
- Image compression for uploads

**Monitoring:**
- Battery usage in Settings
- Data usage in Settings
- Performance alerts (high memory, slow response)

### 12.6 Notifications

**Push Notifications (Optional):**
- FCM for urgent approvals (optional)
- Local notifications for permission requests
- Notification channels (importance levels)
- Rich notifications (action buttons)

**Examples:**
- "Claude Code requests camera access" [Approve] [Deny]
- "Connection to Office MacBook lost" [Reconnect]
- "New chat message from Claude Code"

### 12.7 Dark Mode

**Theme Support:**
- Light mode (default)
- Dark mode
- System default (follow system theme)
- Dynamic color (Material You, Android 12+)

**Implementation:**
- Material3 theme with dynamic color support
- WebView canvas respects system theme
- Custom seam color integration

### 12.8 App Shortcuts

**Static Shortcuts:**
- "Scan QR Code"
- "Open Chat"
- "Switch Instance"

**Dynamic Shortcuts:**
- Recent instances (quick-switch)
- Recent chat sessions

**Example:**
```xml
<shortcuts>
  <shortcut
    android:shortcutId="scan_qr"
    android:enabled="true"
    android:icon="@drawable/ic_qr_code"
    android:shortcutShortLabel="@string/scan_qr"
    android:shortcutLongLabel="@string/scan_qr_long">
    <intent
      android:action="ai.openclaw.android.ACTION_SCAN_QR"
      android:targetPackage="ai.openclaw.android"
      android:targetClass="ai.openclaw.android.MainActivity" />
  </shortcut>
</shortcuts>
```

### 12.9 Widget Support (Future)

**Home Screen Widget:**
- Connection status
- Quick connect to default instance
- Unread chat message count
- Quick access to camera/screen share

---

## 13. Development Roadmap

### Phase 1: MVP (8-10 weeks)

**Week 1-2: Foundation**
- Project setup (Gradle, dependencies, module structure)
- Multi-module architecture (ui, domain, data, security)
- Base UI components (theme, navigation, composables)
- Enhanced data models (Instance, PermissionRequest, etc.)

**Week 3-4: Security Foundation**
- Biometric authentication implementation
- Certificate pinning enhancement
- EncryptedSharedPreferences for sensitive data
- KeyStore integration

**Week 5-6: SSO Integration**
- OAuth2/OIDC implementation (AppAuth)
- Azure AD integration
- Google Workspace integration
- Token management and refresh

**Week 7-8: QR Onboarding**
- QR scanner (CameraX + ML Kit)
- QR payload parsing
- Pairing flow UI
- Security confirmation dialog

**Week 9-10: Multi-Instance Management**
- Instance data model and storage (Room)
- Instance switcher UI
- Instance management screens
- Connection state handling

### Phase 2: Enterprise Features (6-8 weeks)

**Week 11-12: Permission System**
- Permission request dialog
- Approval logic and policies
- Permission history log
- Default policy configuration

**Week 13-14: Android Enterprise**
- Managed app configuration (AppConfig)
- Work profile support
- Compliance checks
- Remote management (wipe, lock)

**Week 15-16: MDM Integration**
- Intune integration testing
- Certificate deployment via MDM
- Policy enforcement
- Admin configuration UI

**Week 17-18: Capability Showcase**
- Onboarding tutorial screens
- Interactive demo mode
- Permission education
- Feature discovery

### Phase 3: Polish & Testing (4-6 weeks)

**Week 19-20: Testing**
- Unit test coverage (70%+)
- UI test coverage (key flows)
- Integration tests (gateway, SSO, database)
- Security testing (penetration, static analysis)

**Week 21-22: Performance & Optimization**
- Performance profiling and optimization
- Battery usage optimization
- Memory leak fixes
- Network efficiency

**Week 23-24: Accessibility & i18n**
- Accessibility compliance (WCAG AA)
- TalkBack testing and fixes
- Translation (5+ languages)
- RTL layout support

### Phase 4: Release (2 weeks)

**Week 25: Pre-Release**
- Internal dogfooding
- Beta testing with select enterprise customers
- Bug fixes and polish

**Week 26: Launch**
- Google Play Console setup (internal/beta/production tracks)
- Play Store listing (screenshots, description, video)
- Release to closed beta
- Gradual rollout to production

---

## 14. Open Questions & Decisions

### 14.1 Technical Decisions

1. **Dependency Injection:**
   - Current: Manual DI in NodeRuntime
   - Options: Continue manual DI, adopt Koin, adopt Dagger Hilt
   - Recommendation: Koin (lightweight, Kotlin-first, easier than Hilt)

2. **State Management:**
   - Current: StateFlow in ViewModels
   - Options: Continue StateFlow, adopt MVI (Orbit/MVIKotlin), adopt Redux-like
   - Recommendation: Continue StateFlow (simple, effective)

3. **Navigation:**
   - Current: BottomSheet-based navigation
   - Options: Continue BottomSheets, adopt Compose Navigation, hybrid
   - Recommendation: Hybrid (BottomSheets for modals, Navigation for deep screens)

4. **QR Library:**
   - Options: ML Kit Barcode Scanning, ZXing, CameraX-only
   - Recommendation: ML Kit (best integration with CameraX, fast, accurate)

5. **SSO Library:**
   - Options: AppAuth-Android, custom implementation
   - Recommendation: AppAuth (mature, spec-compliant, widely used)

6. **Room vs. DataStore:**
   - Current: EncryptedSharedPreferences
   - Options: Continue prefs, adopt Room for structured data, adopt DataStore
   - Recommendation: Room for instances/logs, EncryptedPrefs for tokens

### 14.2 UX Decisions

1. **Instance Switcher Location:**
   - Options: Top bar dropdown, side drawer, dedicated screen, floating button
   - Recommendation: Top bar dropdown (quick access, familiar pattern)

2. **Permission Dialog Style:**
   - Options: Full-screen dialog, bottom sheet, system-style dialog
   - Recommendation: Bottom sheet (modern, dismissable, context-aware)

3. **Onboarding Length:**
   - Options: 3 screens (minimal), 5-7 screens (comprehensive), skip option
   - Recommendation: 5 screens with skip option (balance education and friction)

4. **Biometric Fallback:**
   - Options: PIN/pattern only, password only, device credential
   - Recommendation: Device credential (any screen lock method)

### 14.3 Enterprise Decisions

1. **MDM SDK Integration:**
   - Options: Native Android Enterprise only, vendor SDKs (Intune, WS1)
   - Recommendation: Native only for MVP, vendor SDKs if customer demand

2. **Certificate Deployment:**
   - Options: Manual import, MDM push, SCEP/ACME enrollment
   - Recommendation: Manual + MDM push for MVP, SCEP in Phase 2

3. **Compliance Enforcement:**
   - Options: Block non-compliant devices, warn only, configurable
   - Recommendation: Configurable (default warn, allow admin block)

4. **Audit Log Storage:**
   - Options: Local only, cloud sync, export to SIEM
   - Recommendation: Local + export for MVP, cloud sync if needed

---

## Conclusion

This specification provides a comprehensive blueprint for building the EnterpriseClaw Android application. The app leverages the existing OpenClaw Android foundation while adding enterprise-grade security, authentication, and management capabilities.

**Key Takeaways:**
- Modern Android development (Kotlin, Compose, Material3)
- Enterprise-first security (biometric, SSO, certificate pinning)
- User-friendly onboarding (QR pairing, capability showcase)
- Multi-instance management for flexible use
- Comprehensive permission system with user control
- Android Enterprise and MDM integration
- Privacy-respecting design (opt-in telemetry, encrypted storage)

**Next Steps:**
1. Review and approve this specification
2. Finalize technical decisions (DI, QR library, etc.)
3. Set up project structure and CI/CD
4. Begin Phase 1 implementation (Foundation + Security)
5. Establish beta testing program with enterprise partners

**Success Metrics:**
- 90%+ biometric enrollment rate
- <5% permission denial rate
- <1% crash rate
- 4.5+ star rating on Google Play
- 70%+ test coverage
- 90%+ enterprise compliance success rate
- <500ms instance switch time
- <200MB typical memory usage

---

**Document Version:** 1.0
**Author:** Android Lead Developer (Claude)
**Date:** 2026-02-07
**Status:** Draft for Review
