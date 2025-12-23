//
//  ContentView.swift
//  lidarcamera
//
//  Created by JOSE ZARABANDA on 12/23/25.
//

import SwiftUI
import Photos

struct ContentView: View {
    @StateObject private var cameraManager = CameraManager()
    @StateObject private var depthManager = ARDepthManager()
    @State private var isLensPanelExpanded = false
    @State private var selectedLens: Lens = .wide
    @State private var bandStep: Float = 0.05 // 5cm default
    @State private var showDepthError = false
    @State private var useColorMode = false // B/W by default
    @State private var showContours = false // Off by default
    @State private var showEdgeTransition = false // Loading transition
    @State private var transitionSnapshot: CGImage? // Captured frame for transition
    
    /// Whether we're in LiDAR mode (showing depth view)
    private var isLiDARMode: Bool {
        selectedLens == .lidar
    }
    
    var body: some View {
        ZStack {
            // DURING TRANSITION: Only show EdgeTransitionView (B/W image)
            if showEdgeTransition, let snapshot = transitionSnapshot {
                EdgeTransitionView(sourceImage: snapshot)
                    .ignoresSafeArea()
                    .onAppear {
                        print("[ContentView-ZStack] ⬛ TRANSITION ACTIVE - showing B/W image ONLY")
                    }
                    .onDisappear {
                        print("[ContentView-ZStack] ⬛ TRANSITION ENDED")
                    }
            } else {
                // NORMAL MODE: Show camera or depth
                if isLiDARMode {
                    // LiDAR depth visualization
                    DepthPreviewView(depthManager: depthManager)
                        .ignoresSafeArea()
                        .onAppear {
                            print("[ContentView-ZStack] 🔴 DepthPreviewView APPEARED (no transition)")
                        }
                        .onDisappear {
                            print("[ContentView-ZStack] 🔴 DepthPreviewView DISAPPEARED")
                        }
                } else {
                    // Normal camera preview
                    CameraPreviewView(session: cameraManager.session, lastFrameSnapshot: $cameraManager.lastFrameSnapshot)
                        .ignoresSafeArea()
                        .onAppear {
                            print("[ContentView-ZStack] 📷 CameraPreviewView APPEARED")
                        }
                        .onDisappear {
                            print("[ContentView-ZStack] 📷 CameraPreviewView DISAPPEARED")
                        }
                }
            }
            
            // Permission denied overlay
            if cameraManager.permissionDenied && !isLiDARMode {
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
            
            // Depth toggles (top, only in LiDAR mode)
            if isLiDARMode && !isLensPanelExpanded {
                VStack {
                    DepthToggles(useColorMode: $useColorMode, showContours: $showContours)
                        .padding(.top, 60)
                        .onChange(of: useColorMode) { _, newValue in
                            depthManager.useColorMode = newValue
                        }
                        .onChange(of: showContours) { _, newValue in
                            depthManager.showContours = newValue
                        }
                    Spacer()
                }
            }
            
            // Band slider (right side, only in LiDAR mode)
            if isLiDARMode && !isLensPanelExpanded {
                HStack {
                    Spacer()
                    BandSlider(value: $bandStep)
                        .padding(.trailing, 16)
                        .onChange(of: bandStep) { _, newValue in
                            depthManager.bandStep = newValue
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
            
            // Depth error toast
            if showDepthError {
                VStack {
                    Spacer()
                    ToastView(message: depthManager.errorMessage ?? "LiDAR depth not available")
                        .padding(.bottom, 150)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onAppear {
            cameraManager.checkPermissions()
            depthManager.checkDepthSupport()
        }
        .onChange(of: selectedLens) { oldValue, newValue in
            handleLensChange(from: oldValue, to: newValue)
        }
    }
    
    // MARK: - Mode Switching
    
    private func handleLensChange(from oldLens: Lens, to newLens: Lens) {
        print("[ContentView] handleLensChange: \(oldLens) -> \(newLens)")
        let wasLiDAR = oldLens == .lidar
        let isNowLiDAR = newLens == .lidar
        
        if isNowLiDAR && !wasLiDAR {
            print("[ContentView] ===== SWITCHING TO LIDAR MODE =====")
            print("[ContentView] Step 1: Checking for snapshot...")
            
            // Step 1: Capture snapshot and START ANIMATION FIRST
            if let snapshot = cameraManager.lastFrameSnapshot {
                print("[ContentView] Step 2: Snapshot captured, size: \(snapshot.width)x\(snapshot.height)")
                transitionSnapshot = snapshot
                
                print("[ContentView] Step 3: Starting edge transition animation NOW")
                withAnimation(.easeIn(duration: 0.2)) {
                    showEdgeTransition = true
                }
                print("[ContentView] Step 3b: showEdgeTransition = \(showEdgeTransition)")
            } else {
                print("[ContentView] WARNING: No snapshot available!")
            }
            
            // Wait 0.5 seconds to show B/W image, then start LiDAR
            print("[ContentView] Step 4: Scheduling LiDAR init in 0.5s...")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [self] in
                print("[ContentView] Step 5: 0.5s passed, starting LiDAR...")
                
                // Pause camera and start LiDAR on background thread
                Task.detached(priority: .userInitiated) {
                    await MainActor.run {
                        print("[ContentView] Step 6: Pausing camera...")
                        cameraManager.pauseSession()
                    }
                    
                    try? await Task.sleep(nanoseconds: 100_000_000) // 100ms hardware delay
                    
                    await MainActor.run {
                        print("[ContentView] Step 7: Starting LiDAR session...")
                        if depthManager.isDepthSupported {
                            depthManager.bandStep = bandStep
                            depthManager.startSession()
                            print("[ContentView] Step 8: LiDAR started, transition will hide in 1s")
                            
                            // Keep showing B/W image for 1 more second so user can see it
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                print("[ContentView] Step 9: Hiding transition NOW")
                                showEdgeTransition = false
                                transitionSnapshot = nil
                            }
                        } else {
                            showDepthError = true
                            showEdgeTransition = false
                            transitionSnapshot = nil
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                showDepthError = false
                                withAnimation {
                                    selectedLens = oldLens
                                }
                            }
                        }
                    }
                }
            }
        } else if !isNowLiDAR && wasLiDAR {
            print("[ContentView] Switching FROM LiDAR mode to camera")
            // Switching FROM LiDAR mode to camera
            depthManager.pauseSession()
            
            // Small delay before resuming camera
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                print("[ContentView] Resuming camera after delay")
                cameraManager.resumeSession()
                cameraManager.switchLens(to: newLens)
            }
        } else if !isNowLiDAR {
            print("[ContentView] Normal lens switch (camera modes)")
            // Normal lens switch (camera modes)
            cameraManager.switchLens(to: newLens)
        }
    }
    
    // MARK: - Capture
    
    private func performCapture() {
        if isLiDARMode {
            // Capture depth snapshot
            captureDepthSnapshot()
        } else {
            // Normal photo capture
            cameraManager.capturePhoto()
        }
    }
    
    private func captureDepthSnapshot() {
        guard let image = depthManager.captureDepthSnapshot() else {
            cameraManager.showToastMessage("Failed to capture depth image")
            return
        }
        
        // Save to Photos
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized else {
                Task { @MainActor in
                    cameraManager.showToastMessage("Photos permission denied")
                }
                return
            }
            
            PHPhotoLibrary.shared().performChanges {
                PHAssetCreationRequest.creationRequestForAsset(from: image)
            } completionHandler: { success, error in
                Task { @MainActor in
                    if success {
                        cameraManager.showToastMessage("Depth image saved")
                    } else {
                        cameraManager.showToastMessage("Failed to save: \(error?.localizedDescription ?? "Unknown error")")
                    }
                }
            }
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
            performCapture()
        } label: {
            ZStack {
                Circle()
                    .fill(isLiDARMode ? Color.blue : .white)
                    .frame(width: 72, height: 72)
                
                Circle()
                    .stroke(isLiDARMode ? Color.blue.opacity(0.5) : .white.opacity(0.5), lineWidth: 4)
                    .frame(width: 82, height: 82)
                
                // Show depth icon in LiDAR mode
                if isLiDARMode {
                    Image("LaserBeam")
                        .resizable()
                        .renderingMode(.template)
                        .frame(width: 28, height: 28)
                        .foregroundStyle(.white)
                }
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
                        .offset(x: 18, y: -23)
                    
                    // LiDAR (bottom-right)
                    miniLidarRing
                        .offset(x: 18, y: 23)
                }
            }
            .frame(width: 100, height: 100)
            .glassEffect(.clear, in: .rect(cornerRadius: 20))
        }
    }
    
    // MARK: - Expanded Camera Module (Liquid Glass Full)
    
    private var expandedCameraModule: some View {
        // Frame dimensions based on spec
        let frameSize: CGFloat = 240
        let lensRadius: CGFloat = 41 // ~41px outer radius for big lenses
        
        return ZStack {
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
        .frame(width: frameSize, height: frameSize)
        .glassEffect(.clear, in: .rect(cornerRadius: 36))
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
                .frame(width: 8, height: 8)
            
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
                .frame(width: 8, height: 8)
            
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
        } label: {
            ZStack {
                // Outer ring (thick) - outermost
                Circle()
                    .stroke(.white.opacity(0.75), lineWidth: radius * 0.15)
                    .frame(width: diameter, height: diameter)
                
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
        } label: {
            ZStack {
                // Outlined circle
                Circle()
                    .stroke(
                        isSelected ? Color.blue : .white.opacity(0.6),
                        lineWidth: 2
                    )
                    .frame(width: 36, height: 36)
                
                // Laser/LiDAR icon
                Image("LaserBeam")
                    .resizable()
                    .renderingMode(.template)
                    .frame(width: 18, height: 18)
                    .foregroundStyle(isSelected ? .blue : .white)
                
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
