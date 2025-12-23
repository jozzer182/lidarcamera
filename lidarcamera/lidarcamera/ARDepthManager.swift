import ARKit
import Combine
import UIKit

/// Manages ARKit session for LiDAR depth capture
@MainActor
class ARDepthManager: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var depthImage: CGImage?
    @Published var isRunning = false
    @Published var isDepthSupported = false
    @Published var errorMessage: String?
    
    // MARK: - Properties
    
    private var session: ARSession?
    private let depthRenderer = DepthRenderer()
    private var frameThrottle: Date = .distantPast
    private let targetFPS: Double = 30
    
    /// Band step in meters (adjustable via slider)
    var bandStep: Float = 0.05 {
        didSet {
            depthRenderer.stepMeters = bandStep
        }
    }
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        checkDepthSupport()
    }
    
    // MARK: - Public Methods
    
    /// Check if device supports LiDAR depth
    func checkDepthSupport() {
        isDepthSupported = ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth)
    }
    
    /// Start ARKit session with scene depth
    func startSession() {
        print("[ARDepthManager] startSession() called")
        print("[ARDepthManager] isDepthSupported: \(isDepthSupported)")
        
        guard isDepthSupported else {
            print("[ARDepthManager] ERROR: LiDAR depth not available on this device")
            errorMessage = "LiDAR depth not available on this device"
            return
        }
        
        if session == nil {
            session = ARSession()
            session?.delegate = self
        }
        
        let configuration = ARWorldTrackingConfiguration()
        
        // Enable scene depth (requires LiDAR)
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) {
            configuration.frameSemantics.insert(.sceneDepth)
        }
        
        // Use smoothed depth if available for better quality
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.smoothedSceneDepth) {
            configuration.frameSemantics.insert(.smoothedSceneDepth)
        }
        
        print("[ARDepthManager] Running session with configuration...")
        session?.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        isRunning = true
        errorMessage = nil
        print("[ARDepthManager] Session started successfully")
    }
    
    /// Pause ARKit session
    func pauseSession() {
        print("[ARDepthManager] pauseSession() called")
        session?.pause()
        isRunning = false
        depthImage = nil
        print("[ARDepthManager] Session paused")
    }
    
    /// Stop and clean up ARKit session
    func stopSession() {
        session?.pause()
        session = nil
        isRunning = false
        depthImage = nil
    }
    
    /// Capture current depth visualization as image for saving
    func captureDepthSnapshot() -> UIImage? {
        guard let cgImage = depthImage else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

// MARK: - ARSessionDelegate

extension ARDepthManager: ARSessionDelegate {
    
    nonisolated func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // Throttle frame processing
        let now = Date()
        let interval = 1.0 / targetFPS
        
        Task { @MainActor in
            guard now.timeIntervalSince(frameThrottle) >= interval else { return }
            frameThrottle = now
            
            // Get depth map (prefer smoothed if available)
            guard let depthData = frame.smoothedSceneDepth ?? frame.sceneDepth else {
                print("[ARDepthManager] WARNING: No depth data in frame")
                return
            }
            
            let depthMap = depthData.depthMap
            let confidenceMap = depthData.confidenceMap
            
            // Render depth to image
            if let renderedImage = depthRenderer.render(
                depthMap: depthMap,
                confidenceMap: confidenceMap
            ) {
                self.depthImage = renderedImage
            } else {
                print("[ARDepthManager] WARNING: Failed to render depth image")
            }
        }
    }
    
    nonisolated func session(_ session: ARSession, didFailWithError error: Error) {
        print("[ARDepthManager] ERROR: AR Session failed: \(error)")
        Task { @MainActor in
            errorMessage = "AR Session failed: \(error.localizedDescription)"
            isRunning = false
        }
    }
    
    nonisolated func sessionWasInterrupted(_ session: ARSession) {
        print("[ARDepthManager] Session was interrupted")
        Task { @MainActor in
            isRunning = false
        }
    }
    
    nonisolated func sessionInterruptionEnded(_ session: ARSession) {
        print("[ARDepthManager] Session interruption ended")
        Task { @MainActor in
            if isRunning == false {
                startSession()
            }
        }
    }
}
