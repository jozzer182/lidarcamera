//
//  CameraManager.swift
//  lidarcamera
//
//  Created by JOSE ZARABANDA on 12/23/25.
//

import AVFoundation
import Combine
import Photos
import SwiftUI

/// Manages AVFoundation camera session, capture, and lens switching
@MainActor
class CameraManager: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var permissionDenied = false
    @Published var photoSaveError: String?
    @Published var showToast = false
    @Published var toastMessage = ""
    @Published var flashEnabled = false
    @Published var lastFrameSnapshot: CGImage? // For LiDAR transition effect
    
    // MARK: - Session Properties
    
    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private let videoDataOutput = AVCaptureVideoDataOutput() // For snapshot capture
    private var currentDeviceInput: AVCaptureDeviceInput?
    private let videoOutputQueue = DispatchQueue(label: "camera.video.output.queue")
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    
    // MARK: - Initialization
    
    override init() {
        super.init()
    }
    
    // MARK: - Permission Handling
    
    func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                Task { @MainActor in
                    if granted {
                        self?.configureSession()
                    } else {
                        self?.permissionDenied = true
                    }
                }
            }
        case .denied, .restricted:
            permissionDenied = true
        @unknown default:
            permissionDenied = true
        }
    }
    
    // MARK: - Session Configuration
    
    private func configureSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.session.beginConfiguration()
            self.session.sessionPreset = .photo
            
            // Add default wide camera
            if let device = self.getDevice(for: .wide) {
                do {
                    let input = try AVCaptureDeviceInput(device: device)
                    if self.session.canAddInput(input) {
                        self.session.addInput(input)
                        self.currentDeviceInput = input
                    }
                } catch {
                    print("Error creating device input: \(error)")
                }
            }
            
            // Add photo output
            if self.session.canAddOutput(self.photoOutput) {
                self.session.addOutput(self.photoOutput)
                self.photoOutput.isHighResolutionCaptureEnabled = true
            }
            
            // Add video data output for snapshot capture
            self.videoDataOutput.setSampleBufferDelegate(self, queue: self.videoOutputQueue)
            self.videoDataOutput.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
            ]
            self.videoDataOutput.alwaysDiscardsLateVideoFrames = true
            
            if self.session.canAddOutput(self.videoDataOutput) {
                self.session.addOutput(self.videoDataOutput)
            }
            
            self.session.commitConfiguration()
            self.session.startRunning()
        }
    }
    
    // MARK: - Session Control (for mode switching)
    
    /// Pause camera session synchronously (when switching to LiDAR mode)
    func pauseSession() {
        let semaphore = DispatchSemaphore(value: 0)
        
        sessionQueue.async { [weak self] in
            guard let self = self else {
                semaphore.signal()
                return
            }
            
            // Turn off torch if on
            if let device = self.currentDeviceInput?.device,
               device.hasTorch && device.torchMode == .on {
                do {
                    try device.lockForConfiguration()
                    device.torchMode = .off
                    device.unlockForConfiguration()
                } catch { }
            }
            
            if self.session.isRunning {
                self.session.stopRunning()
            }
            
            Thread.sleep(forTimeInterval: 0.1)
            semaphore.signal()
        }
        
        _ = semaphore.wait(timeout: .now() + 2.0)
        flashEnabled = false
    }
    
    /// Resume camera session (when switching back from LiDAR mode)
    func resumeSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            Thread.sleep(forTimeInterval: 0.1)
            
            if !self.session.isRunning {
                self.session.startRunning()
            }
        }
    }
    
    // MARK: - Device Discovery
    
    private func getDevice(for lens: Lens) -> AVCaptureDevice? {
        guard let deviceType = lens.deviceType else { return nil }
        
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [deviceType],
            mediaType: .video,
            position: .back
        )
        
        return discoverySession.devices.first
    }
    
    private func isDeviceAvailable(for lens: Lens) -> Bool {
        return getDevice(for: lens) != nil
    }
    
    // MARK: - Lens Switching
    
    func switchLens(to lens: Lens) {
        // Skip if it's LiDAR (no camera switch needed)
        guard lens.requiresCameraSwitch else { return }
        
        // Check if device is available, fallback to wide if not
        var targetLens = lens
        if !isDeviceAvailable(for: lens) {
            targetLens = .wide
            showToastMessage("Lens not available, using Wide")
        }
        
        guard let device = getDevice(for: targetLens) else { return }
        
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.session.beginConfiguration()
            
            // Remove current input
            if let currentInput = self.currentDeviceInput {
                self.session.removeInput(currentInput)
            }
            
            // Add new input
            do {
                let newInput = try AVCaptureDeviceInput(device: device)
                if self.session.canAddInput(newInput) {
                    self.session.addInput(newInput)
                    self.currentDeviceInput = newInput
                }
            } catch {
                print("Error switching lens: \(error)")
                // Restore previous input if possible
                if let currentInput = self.currentDeviceInput,
                   self.session.canAddInput(currentInput) {
                    self.session.addInput(currentInput)
                }
            }
            
            self.session.commitConfiguration()
        }
    }
    
    // MARK: - Flash Control
    
    func toggleFlash() {
        guard let device = currentDeviceInput?.device,
              device.hasTorch else {
            showToastMessage("Flash not available")
            return
        }
        
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            do {
                try device.lockForConfiguration()
                if device.torchMode == .on {
                    device.torchMode = .off
                    Task { @MainActor in
                        self.flashEnabled = false
                    }
                } else {
                    try device.setTorchModeOn(level: 1.0)
                    Task { @MainActor in
                        self.flashEnabled = true
                    }
                }
                device.unlockForConfiguration()
            } catch {
                print("Error toggling flash: \(error)")
            }
        }
    }
    
    // MARK: - Photo Capture
    
    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        settings.isHighResolutionPhotoEnabled = true
        
        // Use flash if enabled and available
        if let device = currentDeviceInput?.device,
           device.hasFlash {
            settings.flashMode = flashEnabled ? .on : .off
        }
        
        sessionQueue.async { [weak self] in
            self?.photoOutput.capturePhoto(with: settings, delegate: self!)
        }
    }
    
    // MARK: - Toast Helper
    
    func showToastMessage(_ message: String) {
        Task { @MainActor in
            self.toastMessage = message
            self.showToast = true
            
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            self.showToast = false
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension CameraManager: AVCapturePhotoCaptureDelegate {
    
    nonisolated func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        
        if let error = error {
            Task { @MainActor in
                self.showToastMessage("Capture failed: \(error.localizedDescription)")
            }
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            Task { @MainActor in
                self.showToastMessage("Failed to process photo")
            }
            return
        }
        
        saveToPhotos(image: image)
    }
    
    private nonisolated func saveToPhotos(image: UIImage) {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { [weak self] status in
            switch status {
            case .authorized, .limited:
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAsset(from: image)
                }) { success, error in
                    Task { @MainActor in
                        if success {
                            self?.showToastMessage("Photo saved!")
                        } else {
                            self?.showToastMessage("Failed to save photo")
                        }
                    }
                }
            case .denied, .restricted:
                Task { @MainActor in
                    self?.showToastMessage("Enable Photos access in Settings to save photos")
                }
            case .notDetermined:
                break
            @unknown default:
                break
            }
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    nonisolated func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        // Get pixel buffer from sample buffer
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        // Create CIImage from pixel buffer
        var ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        
        // Rotate 90 degrees clockwise to match portrait orientation
        // The camera captures in landscape, we need to rotate for portrait display
        ciImage = ciImage.oriented(.right)
        
        // Create CGImage with proper color space
        let context = CIContext(options: nil)
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return }
        
        // Update snapshot on main thread
        Task { @MainActor [weak self] in
            self?.lastFrameSnapshot = cgImage
        }
    }
}

