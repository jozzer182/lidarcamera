<div align="center">
  
# 📸 LiDAR Camera
  
<img src="https://img.shields.io/badge/iOS-26.0+-007AFF?style=for-the-badge&logo=apple&logoColor=white" alt="iOS 26+"/>
<img src="https://img.shields.io/badge/Swift-5.9-FA7343?style=for-the-badge&logo=swift&logoColor=white" alt="Swift 5.9"/>
<img src="https://img.shields.io/badge/SwiftUI-Liquid_Glass-00C7BE?style=for-the-badge&logo=swift&logoColor=white" alt="SwiftUI"/>
<img src="https://img.shields.io/badge/AVFoundation-Camera-34C759?style=for-the-badge&logo=apple&logoColor=white" alt="AVFoundation"/>
<img src="https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge" alt="License MIT"/>

<br/><br/>

<p align="center">
  <img src="https://developer.apple.com/assets/elements/icons/swiftui/swiftui-128x128_2x.png" width="80" alt="SwiftUI Logo"/>
</p>

### A modern iOS camera app featuring Apple's **Liquid Glass** design language with an interactive lens picker inspired by iPhone Pro's camera module.

<br/>

[Features](#-features) • [Screenshots](#-screenshots) • [Installation](#-installation) • [Architecture](#-architecture) • [Tech Stack](#-tech-stack)

</div>

---

## ✨ Features

<table>
<tr>
<td width="50%">

### 📷 Camera Features
- **Full-Screen Live Preview** — Edge-to-edge camera feed using AVFoundation
- **Multi-Lens Support** — Switch between Ultra Wide (0.5x), Wide (1x), and Telephoto (5x)
- **Flash Control** — Toggle flash with visual feedback
- **LiDAR Mode** — Dedicated LiDAR lens option (visual UI)
- **Photo Capture** — Save high-resolution photos to Photos library

</td>
<td width="50%">

### 🎨 Liquid Glass UI
- **Translucent Materials** — `.ultraThinMaterial` for frosted glass effect
- **iPhone Pro Camera Module** — Lens picker mimics real camera hardware
- **Bullseye Lens Design** — Concentric rings with interactive selection
- **Smooth Animations** — Spring animations for expand/collapse transitions
- **Blue Selection Highlight** — Active lens clearly indicated

</td>
</tr>
</table>

---

## 📱 Screenshots

<div align="center">
<table>
<tr>
<td align="center">
<img src="https://raw.githubusercontent.com/niceperson/assets/main/iphone-frame.png" width="250" alt="Collapsed View"/>
<br/>
<sub><b>Collapsed Lens Picker</b></sub>
</td>
<td align="center">
<img src="https://raw.githubusercontent.com/niceperson/assets/main/iphone-frame.png" width="250" alt="Expanded View"/>
<br/>
<sub><b>Expanded Camera Module</b></sub>
</td>
<td align="center">
<img src="https://raw.githubusercontent.com/niceperson/assets/main/iphone-frame.png" width="250" alt="Flash Enabled"/>
<br/>
<sub><b>Flash Enabled</b></sub>
</td>
</tr>
</table>
</div>

> 📌 **Note:** Screenshots will be added after device testing

---

## 🛠 Installation

### Requirements

| Requirement | Version |
|-------------|---------|
| iOS | 26.0+ |
| Xcode | 16.0+ |
| Swift | 5.9+ |
| Device | iPhone with camera |

### Steps

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/lidarcamera.git

# Open in Xcode
cd lidarcamera/lidarcamera
open lidarcamera.xcodeproj

# Build and run on device (camera requires physical device)
```

> ⚠️ **Important:** Camera functionality requires a physical iOS device. Simulator will show permission overlay.

---

## 🏗 Architecture

```
lidarcamera/
├── lidarcameraApp.swift      # App entry point
├── ContentView.swift         # Main UI with camera preview and lens picker
├── CameraManager.swift       # AVFoundation camera session management
├── CameraPreviewView.swift   # UIViewRepresentable for camera preview
├── Lens.swift                # Lens enum (ultraWide, wide, tele, lidar)
├── ToastView.swift           # Lightweight toast notifications
└── Assets.xcassets/          # App icons and laser beam icon
    └── LaserBeam.imageset/   # Custom LiDAR icon
```

### Key Components

| File | Responsibility |
|------|----------------|
| `CameraManager` | Manages `AVCaptureSession`, device discovery, lens switching, flash control, and photo capture |
| `ContentView` | SwiftUI view with expanded/collapsed camera module, capture button, and permission handling |
| `CameraPreviewView` | `UIViewRepresentable` wrapper for `AVCaptureVideoPreviewLayer` |
| `Lens` | Enum defining available lenses with labels and SF Symbols |

---

## 🔧 Tech Stack

<div align="center">

| Technology | Purpose |
|------------|---------|
| <img src="https://developer.apple.com/assets/elements/icons/swiftui/swiftui-128x128_2x.png" width="40"/> | **SwiftUI** — Declarative UI framework |
| <img src="https://developer.apple.com/assets/elements/icons/avfoundation/avfoundation-128x128_2x.png" width="40"/> | **AVFoundation** — Camera capture and control |
| <img src="https://developer.apple.com/assets/elements/icons/photos/photos-128x128_2x.png" width="40"/> | **Photos** — Save to photo library |
| <img src="https://developer.apple.com/assets/elements/icons/combine/combine-128x128_2x.png" width="40"/> | **Combine** — Reactive state management |

</div>

---

## 📋 Permissions

The app requires the following permissions (configured in build settings):

```
NSCameraUsageDescription — "LiDAR Camera needs camera access to capture photos"
NSPhotoLibraryAddUsageDescription — "LiDAR Camera needs permission to save photos"
```

---

## 🎯 Roadmap

- [x] Full-screen camera preview
- [x] Liquid Glass lens picker (collapsed/expanded)
- [x] Multi-lens switching (0.5x, 1x, 5x)
- [x] Flash control with visual feedback
- [x] Photo capture to library
- [ ] LiDAR depth visualization
- [ ] Video recording
- [ ] Manual focus/exposure controls
- [ ] Portrait mode with depth effect

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

<div align="center">

### Made with ❤️ for iOS developers

<br/>

<img src="https://img.shields.io/badge/Made_with-SwiftUI-FA7343?style=flat-square&logo=swift&logoColor=white" alt="Made with SwiftUI"/>
<img src="https://img.shields.io/badge/Designed_for-iPhone_Pro-000000?style=flat-square&logo=apple&logoColor=white" alt="Designed for iPhone Pro"/>

</div>
