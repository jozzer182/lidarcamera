<div align="center">
  
# 📸 LiDAR Camera
  
<img src="https://img.shields.io/badge/iOS-26.0+-007AFF?style=for-the-badge&logo=apple&logoColor=white" alt="iOS 26+"/>
<img src="https://img.shields.io/badge/Swift-5.9-FA7343?style=for-the-badge&logo=swift&logoColor=white" alt="Swift 5.9"/>
<img src="https://img.shields.io/badge/SwiftUI-Liquid_Glass-00C7BE?style=for-the-badge&logo=swift&logoColor=white" alt="SwiftUI"/>
<img src="https://img.shields.io/badge/ARKit-LiDAR_Depth-FF3B30?style=for-the-badge&logo=apple&logoColor=white" alt="ARKit"/>
<img src="https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge" alt="License MIT"/>

<br/><br/>

<p align="center">
  <img src="https://developer.apple.com/assets/elements/icons/swiftui/swiftui-128x128_2x.png" width="80" alt="SwiftUI Logo"/>
</p>

### A modern iOS camera app featuring Apple's **Liquid Glass** design language with an interactive lens picker and **real-time LiDAR depth visualization**.

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
- **Photo Capture** — Save high-resolution photos to Photos library
- **Real-time Frame Capture** — Captures camera frames for smooth transitions

</td>
<td width="50%">

### 🔴 LiDAR Mode
- **Real-time Depth Visualization** — See depth data rendered as grayscale bands
- **Color/Grayscale Modes** — Toggle between HSL color and grayscale depth display
- **Contour Lines** — Optional edge detection overlay on depth map
- **Radar Sweep Animation** — Animated radar effect across depth visualization
- **Edge Transition Animation** — Progressive B/W to edge-detected transition

</td>
</tr>
<tr>
<td width="50%">

### 🎨 Liquid Glass UI
- **Translucent Materials** — Frosted glass effect throughout
- **iPhone Pro Camera Module** — Lens picker mimics real camera hardware
- **Bullseye Lens Design** — Concentric rings with interactive selection
- **Smooth Animations** — Spring animations for expand/collapse transitions
- **Blue Selection Highlight** — Active lens clearly indicated

</td>
<td width="50%">

### 🎬 Transitions & Effects
- **Edge Detection Animation** — Progressive grayscale to edge-only transition
- **10 Pre-computed Keyframes** — Smooth animation without blocking UI
- **CoreImage Filters** — CIEdges, CIExposureAdjust, CIScreenBlendMode
- **Seamless Mode Switching** — Camera to LiDAR with visual feedback

</td>
</tr>
</table>

---

## 📱 Screenshots

<div align="center">
<table>
<tr>
<td align="center">
<img src="https://raw.githubusercontent.com/niceperson/assets/main/iphone-frame.png" width="250" alt="Camera Mode"/>
<br/>
<sub><b>Camera Mode</b></sub>
</td>
<td align="center">
<img src="https://raw.githubusercontent.com/niceperson/assets/main/iphone-frame.png" width="250" alt="LiDAR Depth"/>
<br/>
<sub><b>LiDAR Depth Visualization</b></sub>
</td>
<td align="center">
<img src="https://raw.githubusercontent.com/niceperson/assets/main/iphone-frame.png" width="250" alt="Edge Transition"/>
<br/>
<sub><b>Edge Transition Animation</b></sub>
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
| Device | iPhone Pro with LiDAR |

### Steps

```bash
# Clone the repository
git clone https://github.com/jozzer182/lidarcamera.git

# Open in Xcode
cd lidarcamera/lidarcamera
open lidarcamera.xcodeproj

# Build and run on device (LiDAR requires iPhone Pro)
```

> ⚠️ **Important:** LiDAR features require an iPhone 12 Pro or newer with LiDAR sensor.

---

## 🏗 Architecture

```
lidarcamera/
├── lidarcameraApp.swift        # App entry point
├── ContentView.swift           # Main UI with camera/LiDAR preview and lens picker
├── CameraManager.swift         # AVFoundation camera session + video frame capture
├── CameraPreviewView.swift     # UIViewRepresentable for camera preview
├── ARDepthManager.swift        # ARKit session for LiDAR depth capture
├── DepthRenderer.swift         # Renders depth buffer to grayscale/color images
├── DepthPreviewView.swift      # SwiftUI view for depth visualization
├── EdgeTransitionView.swift    # Progressive edge detection animation
├── DepthToggles.swift          # UI toggles for color mode and contours
├── BandSlider.swift            # Vertical slider for depth band resolution
├── Lens.swift                  # Lens enum (ultraWide, wide, tele, lidar)
├── ToastView.swift             # Lightweight toast notifications
└── Assets.xcassets/            # App icons and custom images
```

### Key Components

| File | Responsibility |
|------|----------------|
| `CameraManager` | Manages `AVCaptureSession`, video data output for frame capture, lens switching, flash, photo capture |
| `ARDepthManager` | Manages `ARSession` with scene depth semantics, renders depth frames via `DepthRenderer` |
| `DepthRenderer` | Converts depth buffer to CGImage with grayscale bands, color mapping, contours, and radar sweep |
| `EdgeTransitionView` | Pre-computes 10 keyframes transitioning from B/W to edge-detected image using CoreImage |
| `ContentView` | Orchestrates camera/LiDAR mode switching with animated transitions |

---

## 🔧 Tech Stack

<div align="center">

| Technology | Purpose |
|------------|---------|
| <img src="https://developer.apple.com/assets/elements/icons/swiftui/swiftui-128x128_2x.png" width="40"/> | **SwiftUI** — Declarative UI framework |
| <img src="https://developer.apple.com/assets/elements/icons/avfoundation/avfoundation-128x128_2x.png" width="40"/> | **AVFoundation** — Camera capture and control |
| <img src="https://developer.apple.com/assets/elements/icons/arkit/arkit-128x128_2x.png" width="40"/> | **ARKit** — LiDAR depth data capture |
| <img src="https://developer.apple.com/assets/elements/icons/core-image/core-image-128x128_2x.png" width="40"/> | **CoreImage** — Image processing and filters |
| <img src="https://developer.apple.com/assets/elements/icons/photos/photos-128x128_2x.png" width="40"/> | **Photos** — Save to photo library |

</div>

---

## 📋 Permissions

The app requires the following permissions:

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
- [x] LiDAR depth visualization
- [x] Grayscale/Color depth modes
- [x] Contour overlay on depth
- [x] Radar sweep animation
- [x] Edge transition animation (B/W → edges)
- [ ] Video recording
- [ ] Manual focus/exposure controls
- [ ] Depth-based photo effects

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

<div align="center">

### Made with ❤️ for iOS developers

<br/>

<img src="https://img.shields.io/badge/Made_with-SwiftUI-FA7343?style=flat-square&logo=swift&logoColor=white" alt="Made with SwiftUI"/>
<img src="https://img.shields.io/badge/Powered_by-LiDAR-FF3B30?style=flat-square&logo=apple&logoColor=white" alt="Powered by LiDAR"/>
<img src="https://img.shields.io/badge/Designed_for-iPhone_Pro-000000?style=flat-square&logo=apple&logoColor=white" alt="Designed for iPhone Pro"/>

</div>
