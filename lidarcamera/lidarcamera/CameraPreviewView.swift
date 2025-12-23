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
            
            let renderer = UIGraphicsImageRenderer(bounds: bounds)
            let image = renderer.image { context in
                layer.render(in: context.cgContext)
            }
            
            if let cgImage = image.cgImage {
                coordinator?.updateSnapshot(cgImage)
            }
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
