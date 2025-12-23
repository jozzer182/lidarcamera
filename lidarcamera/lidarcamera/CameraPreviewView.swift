//
//  CameraPreviewView.swift
//  lidarcamera
//
//  Created by JOSE ZARABANDA on 12/23/25.
//

import SwiftUI
import AVFoundation

/// UIViewRepresentable wrapper for AVCaptureVideoPreviewLayer with snapshot capability
struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    @Binding var lastFrameSnapshot: CGImage?
    
    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        view.coordinator = context.coordinator
        return view
    }
    
    func updateUIView(_ uiView: PreviewView, context: Context) {
        uiView.coordinator = context.coordinator
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    class Coordinator {
        var parent: CameraPreviewView
        
        init(parent: CameraPreviewView) {
            self.parent = parent
        }
        
        func updateSnapshot(_ image: CGImage) {
            Task { @MainActor in
                parent.lastFrameSnapshot = image
            }
        }
    }
    
    /// Custom UIView that contains the preview layer and captures snapshots
    class PreviewView: UIView {
        private var snapshotTimer: Timer?
        weak var coordinator: Coordinator?
        
        override class var layerClass: AnyClass {
            AVCaptureVideoPreviewLayer.self
        }
        
        var previewLayer: AVCaptureVideoPreviewLayer {
            layer as! AVCaptureVideoPreviewLayer
        }
        
        override func didMoveToWindow() {
            super.didMoveToWindow()
            if window != nil {
                startSnapshotCapture()
            } else {
                stopSnapshotCapture()
            }
        }
        
        private func startSnapshotCapture() {
            // Capture snapshot every 0.5 seconds for transition effect
            snapshotTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
                self?.captureSnapshot()
            }
        }
        
        private func stopSnapshotCapture() {
            snapshotTimer?.invalidate()
            snapshotTimer = nil
        }
        
        private func captureSnapshot() {
            guard bounds.width > 0, bounds.height > 0 else { return }
            
            // Use explicit SRGB color space for the snapshot
            let scale = UIScreen.main.scale
            let width = Int(bounds.width * scale)
            let height = Int(bounds.height * scale)
            
            print("[CameraPreviewView] Capturing snapshot: \(width)x\(height) @ scale \(scale)")
            
            // Create bitmap context with SRGB color space
            guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
                  let context = CGContext(
                    data: nil,
                    width: width,
                    height: height,
                    bitsPerComponent: 8,
                    bytesPerRow: width * 4,
                    space: colorSpace,
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
                  ) else {
                print("[CameraPreviewView] ❌ Failed to create CGContext")
                return
            }
            
            // Scale context to match screen scale
            context.scaleBy(x: scale, y: scale)
            
            // Render the layer into our context
            layer.render(in: context)
            
            // Create CGImage from context
            guard let cgImage = context.makeImage() else {
                print("[CameraPreviewView] ❌ Failed to create CGImage")
                return
            }
            
            print("[CameraPreviewView] ✅ Snapshot captured!")
            print("[CameraPreviewView] colorSpace: \(cgImage.colorSpace?.name ?? "nil" as CFString)")
            print("[CameraPreviewView] bitsPerPixel: \(cgImage.bitsPerPixel)")
            
            coordinator?.updateSnapshot(cgImage)
        }
        
        deinit {
            stopSnapshotCapture()
        }
    }
}

/// Non-binding version for backward compatibility
extension CameraPreviewView {
    init(session: AVCaptureSession) {
        self.session = session
        self._lastFrameSnapshot = .constant(nil)
    }
}
