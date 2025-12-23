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
    private var currentDeviceInput: AVCaptureDeviceInput?
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
            
            self.session.commitConfiguration()
            self.session.startRunning()
        }
    }
    
    // MARK: - Session Control (for mode switching)
    
    /// Pause camera session synchronously (when switching to LiDAR mode)
    /// Uses semaphore to ensure camera is fully stopped before returning
    func pauseSession() {
        print("[CameraManager] pauseSession() called")
        let semaphore = DispatchSemaphore(value: 0)
        
        sessionQueue.async { [weak self] in
            guard let self = self else {
                print("[CameraManager] pauseSession: self is nil")
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
                } catch {
                    print("Error turning off torch: \(error)")
                }
            }
            
            // Stop session
            if self.session.isRunning {
                print("[CameraManager] Stopping AVCaptureSession...")
                self.session.stopRunning()
                print("[CameraManager] AVCaptureSession stopped")
            } else {
                print("[CameraManager] Session was not running")
            }
            
            // Small delay to ensure hardware is released
            print("[CameraManager] Waiting 100ms for hardware release...")
            Thread.sleep(forTimeInterval: 0.1)
            print("[CameraManager] Hardware release delay complete")
            
            semaphore.signal()
        }
        
        // Wait for session to fully stop (max 2 seconds)
        print("[CameraManager] Waiting for session to stop...")
        let result = semaphore.wait(timeout: .now() + 2.0)
        if result == .timedOut {
            print("[CameraManager] WARNING: Semaphore timed out!")
        } else {
            print("[CameraManager] Session stopped successfully")
        }
        flashEnabled = false
    }
    
    /// Resume camera session (when switching back from LiDAR mode)
    func resumeSession() {
        print("[CameraManager] resumeSession() called")
        sessionQueue.async { [weak self] in
            guard let self = self else {
                print("[CameraManager] resumeSession: self is nil")
                return
            }
            
            // Small delay before restarting
            print("[CameraManager] Waiting 100ms before restart...")
            Thread.sleep(forTimeInterval: 0.1)
            
            if !self.session.isRunning {
                print("[CameraManager] Starting AVCaptureSession...")
                self.session.startRunning()
                print("[CameraManager] AVCaptureSession started")
            } else {
                print("[CameraManager] Session was already running")
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
