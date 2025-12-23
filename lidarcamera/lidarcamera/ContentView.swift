//
//  ContentView.swift
//  lidarcamera
//
//  Created by JOSE ZARABANDA on 12/23/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var cameraManager = CameraManager()
    @State private var isLensPanelExpanded = false
    @State private var selectedLens: Lens = .wide
    
    var body: some View {
        ZStack {
            // Full-screen camera preview
            CameraPreviewView(session: cameraManager.session)
                .ignoresSafeArea()
            
            // Permission denied overlay
            if cameraManager.permissionDenied {
                permissionDeniedView
            }
            
            // Scrim overlay when expanded (tap to collapse)
            if isLensPanelExpanded {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            isLensPanelExpanded = false
                        }
                    }
            }
            
            // Main UI overlay
            VStack {
                Spacer()
                
                // Expanded lens panel (centered)
                if isLensPanelExpanded {
                    expandedCameraModule
                        .transition(.scale.combined(with: .opacity))
                    
                    Spacer()
                }
                
                // Bottom controls
                HStack(alignment: .bottom) {
                    // Collapsed lens card (bottom-left)
                    if !isLensPanelExpanded {
                        collapsedCameraModule
                            .transition(.scale.combined(with: .opacity))
                    }
                    
                    Spacer()
                    
                    // Capture button (centered)
                    captureButton
                    
                    Spacer()
                    
                    // Placeholder for symmetry
                    if !isLensPanelExpanded {
                        Color.clear
                            .frame(width: 100, height: 100)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
            
            // Toast overlay
            if cameraManager.showToast {
                VStack {
                    Spacer()
                    ToastView(message: cameraManager.toastMessage)
                        .padding(.bottom, 150)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: cameraManager.showToast)
            }
        }
        .onAppear {
            cameraManager.checkPermissions()
        }
    }
    
    // MARK: - Permission Denied View
    
    private var permissionDeniedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.fill")
                .font(.system(size: 60))
                .foregroundStyle(.white.opacity(0.7))
            
            Text("Camera Access Required")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
            
            Text("Enable camera access in Settings to use this app.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.9))
    }
    
    // MARK: - Capture Button
    
    private var captureButton: some View {
        Button {
            cameraManager.capturePhoto()
        } label: {
            ZStack {
                Circle()
                    .fill(.white)
                    .frame(width: 72, height: 72)
                
                Circle()
                    .stroke(.white.opacity(0.5), lineWidth: 4)
                    .frame(width: 82, height: 82)
            }
        }
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
    }
    
    // MARK: - Collapsed Camera Module (Liquid Glass Mini)
    
    private var collapsedCameraModule: some View {
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isLensPanelExpanded = true
            }
        } label: {
            ZStack {
                // Liquid Glass background
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .frame(width: 100, height: 100)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.5), .white.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                
                // Camera lenses arrangement (contours only)
                ZStack {
                    // Ultra Wide (top-left)
                    miniLensRing(for: .ultraWide)
                        .offset(x: -18, y: -18)
                    
                    // Wide (bottom-left)
                    miniLensRing(for: .wide)
                        .offset(x: -18, y: 18)
                    
                    // Tele (center-right)
                    miniLensRing(for: .tele)
                        .offset(x: 18, y: 0)
                    
                    // Flash (top-right)
                    miniFlashRing
                        .offset(x: 18, y: -22)
                    
                    // LiDAR (bottom-right)
                    miniLidarRing
                        .offset(x: 18, y: 28)
                }
            }
            .shadow(color: .black.opacity(0.25), radius: 15, x: 0, y: 8)
        }
    }
    
    // MARK: - Expanded Camera Module (Liquid Glass Full)
    
    private var expandedCameraModule: some View {
        // Frame dimensions based on spec
        let frameSize: CGFloat = 240
        let lensRadius: CGFloat = 41 // ~41px outer radius for big lenses
        
        return ZStack {
            // Liquid Glass background - rounded square frame
            RoundedRectangle(cornerRadius: 36)
                .fill(.ultraThinMaterial)
                .frame(width: frameSize, height: frameSize)
                .overlay(
                    RoundedRectangle(cornerRadius: 36)
                        .fill(Color.blue.opacity(0.05))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 36)
                        .stroke(.white.opacity(0.4), lineWidth: 2)
                )
            
            // Camera lenses arrangement per spec:
            // - Two lenses stacked on LEFT (aligned with right lens to form centered group)
            // - One lens on RIGHT centered vertically
            ZStack {
                // TOP-LEFT lens (Ultra Wide)
                bullseyeLens(for: .ultraWide, radius: lensRadius)
                    .offset(x: -frameSize * 0.21, y: -frameSize * 0.24)
                
                // BOTTOM-LEFT lens (Wide/1x)
                bullseyeLens(for: .wide, radius: lensRadius)
                    .offset(x: -frameSize * 0.21, y: frameSize * 0.24)
                
                // RIGHT lens (Tele) - centered vertically, stays in place
                bullseyeLens(for: .tele, radius: lensRadius)
                    .offset(x: frameSize * 0.24, y: 0)
                
                // Flash - small outlined circle (top-right quadrant)
                expandedFlashRing
                    .offset(x: frameSize * 0.24, y: -frameSize * 0.32)
                
                // LiDAR - solid circle (lower-right)
                expandedLidarDot
                    .offset(x: frameSize * 0.24, y: frameSize * 0.34)
                
            }
        }
        .shadow(color: .black.opacity(0.25), radius: 20, x: 0, y: 10)
    }
    
    // MARK: - Mini Lens Ring (Collapsed - Contours)
    
    private func miniLensRing(for lens: Lens) -> some View {
        let isSelected = selectedLens == lens
        let size: CGFloat = 28
        
        return ZStack {
            // Outer ring (contour)
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.8), .white.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
                .frame(width: size, height: size)
            
            // Inner subtle fill
            Circle()
                .fill(.white.opacity(0.1))
                .frame(width: size - 4, height: size - 4)
            
            // Selection highlight
            if isSelected {
                Circle()
                    .stroke(Color.blue, lineWidth: 2)
                    .frame(width: size + 6, height: size + 6)
                
                Circle()
                    .fill(Color.blue.opacity(0.3))
                    .frame(width: size - 4, height: size - 4)
            }
        }
    }
    
    private var miniFlashRing: some View {
        ZStack {
            Circle()
                .stroke(
                    cameraManager.flashEnabled ? Color.yellow : .white.opacity(0.6),
                    lineWidth: 1.5
                )
                .frame(width: 14, height: 14)
            
            if cameraManager.flashEnabled {
                Circle()
                    .fill(Color.yellow.opacity(0.6))
                    .frame(width: 10, height: 10)
            }
        }
    }
    
    private var miniLidarRing: some View {
        let isSelected = selectedLens == .lidar
        
        return ZStack {
            Circle()
                .stroke(.white.opacity(0.5), lineWidth: 1)
                .frame(width: 10, height: 10)
            
            if isSelected {
                Circle()
                    .fill(Color.blue.opacity(0.5))
                    .frame(width: 6, height: 6)
            }
        }
    }
    
    // MARK: - Bullseye Lens (Multiple Concentric Rings)
    
    private func bullseyeLens(for lens: Lens, radius: CGFloat) -> some View {
        let isSelected = selectedLens == lens
        let diameter = radius * 2
        
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedLens = lens
            }
            cameraManager.switchLens(to: lens)
        } label: {
            ZStack {
                // Outer ring (thick) - outermost
                Circle()
                    .stroke(.white.opacity(0.75), lineWidth: radius * 0.15)
                    .frame(width: diameter, height: diameter)
                
                // Second ring (thinner, with gap)
                // Circle()
                //     .stroke(.white.opacity(0.55), lineWidth: radius * 0.08)
                //     .frame(width: diameter * 0.72, height: diameter * 0.72)
                
                // // Third ring (inner)
                // Circle()
                //     .stroke(.white.opacity(0.45), lineWidth: radius * 0.06)
                //     .frame(width: diameter * 0.48, height: diameter * 0.48)
                
                // // Innermost ring
                // Circle()
                //     .stroke(.white.opacity(0.35), lineWidth: radius * 0.04)
                //     .frame(width: diameter * 0.28, height: diameter * 0.28)
                
                // // Tiny center circle
                // Circle()
                //     .fill(.white.opacity(0.4))
                //     .frame(width: diameter * 0.12, height: diameter * 0.12)
                
                // Lens label
                Text(lens.label)
                    .font(.system(size: radius * 0.7, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
                
                // Selection ring
                if isSelected {
                    Circle()
                        .stroke(Color.blue, lineWidth: 3)
                        .frame(width: diameter + 12, height: diameter + 12)
                }
            }
        }
        .buttonStyle(.plain)
    }
    
    private var expandedFlashRing: some View {
        Button {
            cameraManager.toggleFlash()
        } label: {
            ZStack {
                // Simple outlined ring (radius ~18px = diameter 36)
                Circle()
                    .stroke(
                        cameraManager.flashEnabled ? Color.yellow : .white.opacity(0.6),
                        lineWidth: 2
                    )
                    .frame(width: 36, height: 36)
                
                // Flash icon
                Image(systemName: cameraManager.flashEnabled ? "bolt.fill" : "bolt")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(cameraManager.flashEnabled ? .yellow : .white.opacity(0.7))
            }
        }
        .buttonStyle(.plain)
    }
    
    private var expandedLidarDot: some View {
        let isSelected = selectedLens == .lidar
        
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedLens = .lidar
            }
            cameraManager.switchLens(to: .lidar)
        } label: {
            ZStack {
                // Solid filled circle (radius ~17px)
                Circle()
                    .stroke(
                        cameraManager.flashEnabled ? Color.yellow : .white.opacity(0.6),
                        lineWidth: 2
                    )
                    .frame(width: 36, height: 36)                
                // Laser/LiDAR icon
                Image("LaserBeam")
                    .resizable()
                    .renderingMode(.template)
                    .frame(width: 18, height: 18)
                    .foregroundStyle(.white)
                
                // Selection ring
                if isSelected {
                    Circle()
                        .stroke(Color.blue, lineWidth: 2)
                        .frame(width: 42, height: 42)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ContentView()
}
