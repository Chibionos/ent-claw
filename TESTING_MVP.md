# EnterpriseClaw MVP Testing Guide

**Status:** ✅ Ready to Test
**Date:** February 7, 2026
**Features:** Biometric Authentication + QR Code Pairing

---

## 🎯 What Was Built

The agent team successfully delivered:

### ✅ iOS App Enhancements
1. **Biometric Authentication** (Face ID / Touch ID)
   - Lock screen on app launch
   - Settings toggle to enable/disable
   - Graceful fallback to device passcode

2. **QR Code Scanner**
   - Camera-based QR scanner
   - Parses gateway configuration JSON
   - Auto-connects to gateway after scan

### ✅ Backend Install Script
- **File:** `scripts/install-enterprise.sh`
- Installs OpenClaw gateway
- Generates secure token
- Creates QR code for iOS app
- **Restricts channels to Mobile + Slack only**
- Starts gateway automatically

---

## 📋 Changes Made

### New Files Created
```
apps/ios/Sources/Auth/
├── BiometricAuthManager.swift       (111 lines)
└── BiometricLockScreen.swift        (84 lines)

apps/ios/Sources/QRScanning/
└── QRScannerView.swift              (255 lines)

scripts/
└── install-enterprise.sh            (8.2KB, executable)
```

### Modified Files
```
apps/ios/Sources/OpenClawApp.swift       (+biometric lock overlay)
apps/ios/Sources/Settings/SettingsTab.swift  (+Security section, +QR scanner link)
apps/ios/Sources/Info.plist              (+NSFaceIDUsageDescription)
apps/ios/project.yml                     (+Face ID permission)
```

---

## 🧪 Test Scenario #1: Install Gateway + Generate QR

### Prerequisites
- macOS or Linux machine
- Node.js 22+ installed
- Terminal access

### Steps

**1. Run the install script:**
```bash
cd /home/chibionos/r/ent-claw
bash scripts/install-enterprise.sh
```

**Expected Output:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 EnterpriseClaw Gateway Installer
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

➜ Checking dependencies...
✅ Dependencies OK

➜ Installing OpenClaw globally...
✅ OpenClaw installed

➜ Initializing OpenClaw configuration...
✅ Configuration initialized

➜ Generating secure gateway token...
✅ Token generated

➜ Starting gateway...
✅ Gateway started on ws://192.168.1.X:18789

📱 Scan this QR code with your iOS app:
[ASCII QR CODE DISPLAYED HERE]

Or connect manually:
  URL: ws://192.168.1.X:18789
  Token: [64-char hex token]

Gateway logs: /tmp/openclaw-gateway.log
```

**2. Verify gateway is running:**
```bash
# Check if gateway process is running
ps aux | grep "openclaw gateway"

# Check gateway logs
tail -f /tmp/openclaw-gateway.log
```

**3. Save connection info:**
- Note the WebSocket URL (e.g., `ws://192.168.1.100:18789`)
- Note the token (64-character hex string)
- QR code should be visible in terminal

---

## 🧪 Test Scenario #2: Build iOS App

### Prerequisites
- Mac with Xcode 15+ installed
- iOS device (iPhone/iPad) with Face ID or Touch ID
- OR iOS Simulator (will use passcode fallback)

### Steps

**1. Open Xcode project:**
```bash
cd /home/chibionos/r/ent-claw/apps/ios
open OpenClaw.xcodeproj
# If using project.yml, first run: xcodegen generate
```

**2. Select your device/simulator:**
- In Xcode, select your target device from the device dropdown
- For QR scanning, **physical device required** (simulator has no camera)

**3. Build and run:**
- Press `Cmd+R` or click the Play button
- Allow code signing if prompted

**Expected Behavior:**
- App builds without errors
- App launches on device/simulator

---

## 🧪 Test Scenario #3: Biometric Authentication

### Steps

**1. First Launch:**
- App should open normally (biometric not enabled by default)
- Navigate to **Settings** tab (bottom navigation)

**2. Enable Biometric:**
- Scroll to **Security** section
- Toggle **"Require Face ID"** (or "Require Touch ID") to ON
- Should see current biometric type displayed

**3. Background the app:**
- Swipe up to home screen
- Wait 5 seconds

**4. Return to app:**
- App should show **lock screen overlay**
- Message: "EnterpriseClaw is locked"
- Large icon (face/fingerprint based on device)
- Button: "Unlock with Face ID" (or Touch ID)

**5. Authenticate:**
- Tap the unlock button
- Face ID prompt should appear (or Touch ID)
- Authenticate with your face/finger/passcode
- Lock screen should smoothly fade away

**Expected Results:**
- ✅ Lock screen appears when app backgrounded
- ✅ Biometric prompt triggers on unlock
- ✅ Successful auth dismisses lock screen
- ✅ Failed auth shows error message
- ✅ Can disable biometric in Settings

---

## 🧪 Test Scenario #4: QR Code Pairing

### Prerequisites
- Gateway running from Scenario #1
- iOS app on **physical device** (simulator lacks camera)
- QR code visible on terminal

### Steps

**1. Navigate to QR Scanner:**
- Open iOS app
- Tap **Settings** tab
- Scroll to **Gateway** section
- Tap **Advanced** disclosure group
- Tap **"Scan QR Code"**

**2. Grant Camera Permission:**
- First time: System prompt "Allow access to camera?"
- Tap **"OK"** or **"Allow"**

**3. Scan QR Code:**
- Point camera at QR code displayed in terminal
- QR scanner should detect code automatically
- Preview should show decoded JSON

**4. Confirm Connection:**
- Scanner should show: "Gateway found: EnterpriseClaw Gateway"
- Displays URL: `ws://192.168.1.X:18789`
- Button: **"Connect"**
- Tap Connect

**5. Verify Connection:**
- Scanner dismisses automatically
- Returns to Settings
- Check **Gateway** section:
  - Status should change to **"Connected"**
  - Server name: **"EnterpriseClaw Gateway"** (or your hostname)
  - Address: `ws://192.168.1.X:18789`

**Expected Results:**
- ✅ Camera permission granted
- ✅ QR code detected and parsed
- ✅ Gateway config extracted from JSON
- ✅ Connection established automatically
- ✅ Status updated in Settings
- ✅ Can send messages via Chat tab

---

## 🧪 Test Scenario #5: End-to-End Flow

### Full Integration Test

**1. Start fresh:**
```bash
# On gateway machine:
cd /home/chibionos/r/ent-claw
bash scripts/install-enterprise.sh
```

**2. Launch iOS app:**
- Build and run on physical device
- Enable biometric in Settings → Security

**3. Background and unlock:**
- Background app
- Return to app
- Authenticate with Face ID/Touch ID
- Verify unlock succeeds

**4. Scan QR and connect:**
- Go to Settings → Gateway → Advanced → Scan QR Code
- Scan QR from terminal
- Wait for "Connected" status

**5. Test chat:**
- Navigate to **Chat** tab
- Type a message: "Hello from EnterpriseClaw!"
- Send message
- Verify gateway receives it (check logs: `tail -f /tmp/openclaw-gateway.log`)
- Gateway should respond (if Claude configured)

**Expected Results:**
- ✅ All features work together
- ✅ Biometric lock → unlock → scan QR → connect → chat
- ✅ Messages flow: iOS → Gateway → Claude Code

---

## 🐛 Troubleshooting

### Issue: Install script fails
**Symptoms:** Script exits with error
**Solutions:**
- Check Node.js version: `node --version` (should be 22+)
- Try manual install: `npm install -g openclaw@latest`
- Check logs: `cat /tmp/openclaw-gateway.log`

### Issue: QR code not scanning
**Symptoms:** Scanner doesn't detect QR code
**Solutions:**
- Ensure physical device (simulator has no camera)
- Check camera permissions: Settings → OpenClaw → Camera
- Try manual connection: Settings → Gateway → Advanced → Manual Gateway
- Increase QR code size on terminal (zoom terminal)

### Issue: Biometric not working
**Symptoms:** Lock screen doesn't appear or auth fails
**Solutions:**
- Check biometric is enrolled: Settings → Face ID & Passcode
- Try disabling/re-enabling in app Settings → Security
- Simulator: Will use passcode fallback (expected)
- Reset biometric: Delete app, reinstall, enable biometric again

### Issue: Connection fails after scanning
**Symptoms:** "Connected" never appears
**Solutions:**
- Verify gateway is running: `ps aux | grep openclaw`
- Check gateway logs: `tail -f /tmp/openclaw-gateway.log`
- Verify network: Ping gateway IP from iOS device
- Check firewall: Ensure port 18789 is open
- Try manual connection with same URL/token

### Issue: Xcode build errors
**Symptoms:** "Cannot find BiometricAuthManager in scope"
**Solutions:**
- Clean build folder: Product → Clean Build Folder (Cmd+Shift+K)
- Restart Xcode
- Ensure all new files are added to target
- Check file structure matches expected layout

---

## 📊 Success Criteria

### ✅ MVP is Complete When:
- [ ] Install script runs without errors
- [ ] Gateway starts and listens on port 18789
- [ ] QR code displays in terminal
- [ ] iOS app builds in Xcode
- [ ] Biometric lock appears on app background
- [ ] Biometric auth successfully unlocks app
- [ ] QR scanner opens and requests camera permission
- [ ] QR code is detected and parsed
- [ ] Connection succeeds after scanning
- [ ] "Connected" status appears in Settings
- [ ] Can send chat message to gateway
- [ ] Gateway receives and responds to message

### Known Limitations (Expected)
- ❌ No enterprise SSO (OAuth2/SAML) - not in MVP
- ❌ No certificate pinning - basic TLS only
- ❌ No permission approval workflows - direct execution
- ❌ No multi-instance management - connects to one gateway
- ❌ Manual gateway config needed in script - no automatic discovery in QR

### 📱 Available Channels
The install script restricts channels to:
- ✅ **Mobile App** (iOS + Android via gateway WebSocket)
- ✅ **Slack** (optional, for fallback communication)
- ❌ WhatsApp, Telegram, Discord, Signal, iMessage - **disabled by default**

To enable all channels, run: `openclaw config delete plugins.allow`

---

## 🚀 Next Steps After MVP

Once you've verified the MVP works:

1. **Document Issues:** Note any bugs or UX issues
2. **Gather Feedback:** What works well? What needs improvement?
3. **Plan Iteration 2:** Choose next features:
   - Multi-instance switching?
   - Permission approval UI?
   - Certificate pinning?
   - Android app?
4. **Code Cleanup:** Review code for production readiness
5. **Testing:** Add unit/integration tests

---

## 📞 Getting Help

**If you encounter blockers:**

1. **Check logs:**
   - Gateway: `/tmp/openclaw-gateway.log`
   - iOS: Xcode console

2. **Review code:**
   - Biometric: `apps/ios/Sources/Auth/`
   - QR Scanner: `apps/ios/Sources/QRScanning/`
   - Install script: `scripts/install-enterprise.sh`

3. **Ask for help:**
   - Provide specific error messages
   - Share relevant log excerpts
   - Describe steps to reproduce

---

## 🎉 Success!

If all scenarios pass, congratulations! You have a working EnterpriseClaw MVP with:
- ✅ Biometric authentication (Face ID / Touch ID)
- ✅ QR code pairing (scan → auto-connect)
- ✅ Gateway installation (one script)
- ✅ End-to-end communication (iOS → Gateway → Claude Code)

This is the foundation for the full enterprise transformation outlined in the architecture docs.

**Time to test:** ~30-60 minutes
**Ready to deploy:** Tonight! 🚀
