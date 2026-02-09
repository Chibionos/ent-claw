# EnterpriseClaw Assets

This directory contains visual assets for the EnterpriseClaw project.

## Required Images

### Hero Image
**File:** `enterprise-claw-hero.png`
**Dimensions:** 1600x400px (or similar 4:1 aspect ratio)
**Description:** Main hero banner showing EnterpriseClaw branding with security emphasis

**Suggested Gemini Prompt:**
```
Create a professional hero banner image (1600x400px) for "EnterpriseClaw" -
an enterprise-grade secure AI assistant. The design should feature:
- Modern, clean aesthetic with dark blue/purple gradient background
- Prominent "EnterpriseClaw" wordmark in white
- A stylized claw logo integrated with a shield or lock icon
- Visual elements suggesting security: encrypted data streams, biometric
  authentication symbols (fingerprint, face ID), mobile devices
- Tagline: "Enterprise-Grade Claude Code Control • Zero-Trust Security • Mobile-First"
- Professional, trustworthy color scheme (deep blues, purples, silvers)
- Abstract tech patterns or grid lines suggesting encryption/security
```

### Security Architecture Diagram
**File:** `security-architecture.png`
**Dimensions:** 1400x800px (or similar)
**Description:** Visual diagram of the 7-layer security architecture

**Suggested Gemini Prompt:**
```
Create a technical architecture diagram (1400x800px) showing EnterpriseClaw's
7-layer security defense system:

Layer 1 (Top): Mobile Apps with biometric icons (Face ID, fingerprint)
Layer 2: mTLS/Zero-Trust network security with encryption symbols
Layer 3: Transport encryption (AES-256-GCM) with key exchange
Layer 4: Data protection layer with secure storage icons
Layer 5: Access control with permission checkmarks
Layer 6: Audit & compliance with logging symbols
Layer 7 (Bottom): Operational security with monitoring alerts

Use professional infographic style with:
- Dark background (#1a1a2e or similar)
- Gradient accents (blue to purple)
- Clean iconography
- Connecting lines showing data flow
- Each layer labeled with icons and text
```

### Mobile App Screenshots
**Files:**
- `ios-biometric-lock.png` (750x1624px - iPhone 14 Pro)
- `ios-qr-scanner.png` (750x1624px)
- `android-security.png` (1080x2340px - Pixel 6)

**Description:** App interface mockups showing key features

**Suggested Gemini Prompts:**

**iOS Biometric Lock Screen:**
```
Create a modern iOS app interface mockup (750x1624px) showing a biometric
lock screen for EnterpriseClaw:
- Dark background with subtle gradient
- Large Face ID/Touch ID icon in center
- Text: "EnterpriseClaw is locked"
- Blue "Unlock with Face ID" button
- Clean, minimal iOS design aesthetic
- Top status bar with time and battery
- Bottom indicator bar
```

**iOS QR Scanner:**
```
Create an iOS camera interface mockup (750x1624px) for QR code scanning:
- Camera viewfinder showing a sample QR code in center
- Scanning reticle/frame overlay
- Top banner: "Scan Gateway QR Code"
- Bottom card preview showing decoded gateway info:
  - Gateway name: "EnterpriseClaw Gateway"
  - URL: "ws://192.168.1.100:18789"
  - "Connect" button in blue
- Modern iOS camera UI style
```

**Android Security Settings:**
```
Create an Android app interface mockup (1080x2340px) showing security
settings screen:
- Material Design 3 aesthetic
- "Security" header at top
- Toggle switches for:
  - "Require Fingerprint" (enabled/on)
  - "Biometric Type" showing "Fingerprint"
- "Gateway" section below with connection status
- Clean, modern Material You design
- Dark theme with purple accent colors
```

## Generating Images with Google Gemini

### Option 1: Gemini Pro with Imagen (Recommended)

1. **Visit Google AI Studio**: https://aistudio.google.com/
2. **Select "Gemini Pro with Imagen"**
3. **Paste one of the prompts above**
4. **Generate and download**
5. **Rename to the appropriate filename**
6. **Place in this directory** (`docs/assets/`)

### Option 2: Use Gemini API (Python)

```python
import google.generativeai as genai
from PIL import Image
import io

# Configure API key
genai.configure(api_key="YOUR_API_KEY")

# Initialize model
model = genai.GenerativeModel('gemini-pro-vision')

# Generate image
prompt = """[paste prompt here]"""
response = model.generate_content(
    prompt,
    generation_config=genai.types.GenerationConfig(
        max_output_tokens=2048,
        temperature=0.7,
    )
)

# Save image
image_data = response.candidates[0].content.parts[0].inline_data.data
image = Image.open(io.BytesIO(image_data))
image.save("enterprise-claw-hero.png")
```

### Option 3: Use Other AI Image Generators

Alternative tools if Gemini is unavailable:
- **Midjourney** (Discord bot)
- **DALL-E 3** (via ChatGPT Plus or API)
- **Stable Diffusion** (local or via DreamStudio)

## Image Guidelines

- **Format:** PNG with transparency where appropriate
- **Resolution:** High-resolution (2x for Retina displays)
- **Color scheme:**
  - Primary: Deep blue (#2563eb), Purple (#7c3aed)
  - Accent: Cyan (#06b6d4), Silver (#94a3b8)
  - Background: Dark (#0f172a), Darker (#020617)
- **Style:** Modern, professional, trustworthy
- **Branding:** Consistent with enterprise/security focus

## Current Status

📝 **Placeholders Added** - All image references are in README.md
🎨 **Awaiting Generation** - Images need to be created
✅ **Ready for Integration** - Once generated, commit and push

---

**Note:** Remember to add image files to `.gitignore` if they're very large (>1MB),
or use Git LFS for version control.
