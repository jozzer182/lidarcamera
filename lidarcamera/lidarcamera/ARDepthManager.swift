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
    
    // Animation timer
    private var animationTimer: Timer?
    private var animationStartTime: Date = Date()
    
    /// Duration of one radar sweep cycle (near to far)
    var sweepDuration: TimeInterval = 2.0
    
    /// Band step in meters (adjustable via slider)
    var bandStep: Float = 0.05 {
        didSet {
            depthRenderer.stepMeters = bandStep
        }
    }
    
    /// Show contour lines at band boundaries
    var showContours: Bool = false {
        didSet {
            depthRenderer.showContours = showContours
        }
    }
    
    /// Use color mode (red=near, blue=far) instead of B/W
    var useColorMode: Bool = false {
        didSet {
            depthRenderer.useColorMode = useColorMode
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
        guard isDepthSupported else {
            errorMessage = "LiDAR depth not available on this device"
            return
        }
        
        if session == nil {
            session = ARSession()
            session?.delegate = self
        }
        
        let configuration = ARWorldTrackingConfiguration()
        
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) {
            configuration.frameSemantics.insert(.sceneDepth)
        }
        
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.smoothedSceneDepth) {
            configuration.frameSemantics.insert(.smoothedSceneDepth)
        }
        
        session?.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        isRunning = true
        errorMessage = nil
        
        startAnimationTimer()
    }
    
    /// Start the radar sweep animation timer
    private func startAnimationTimer() {
        animationStartTime = Date()
        animationTimer?.invalidate()
        animationTimer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateAnimation()
            }
        }
    }
    
    /// Update animation phase based on elapsed time
    private func updateAnimation() {
        let elapsed = Date().timeIntervalSince(animationStartTime)
        let phase = Float((elapsed.truncatingRemainder(dividingBy: sweepDuration)) / sweepDuration)
        depthRenderer.animationPhase = phase
    }
    
    /// Pause ARKit session
    func pauseSession() {
        animationTimer?.invalidate()
        animationTimer = nil
        session?.pause()
        isRunning = false
        depthImage = nil
    }
    
    /// Stop and clean up ARKit session
    func stopSession() {
        session?.pause()
        session = nil
        isRunning = false
        depthImage = nil
    }
    
    /// Capture current depth visualization as image for saving
    /// Note: ARKit depth map is captured in landscape orientation.
    /// We rotate 90° clockwise to match portrait display orientation.
    func captureDepthSnapshot() -> UIImage? {
        guard let cgImage = depthImage else { return nil }
        // Apply portrait orientation (rotate 90° clockwise from landscape)
        return UIImage(cgImage: cgImage, scale: 1.0, orientation: .right)
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
            guard let depthData = frame.smoothedSceneDepth ?? frame.sceneDepth else { return }
            
            let depthMap = depthData.depthMap
            let confidenceMap = depthData.confidenceMap
            
            if let renderedImage = depthRenderer.render(
                depthMap: depthMap,
                confidenceMap: confidenceMap
            ) {
                self.depthImage = renderedImage
            }
        }
    }
    
    nonisolated func session(_ session: ARSession, didFailWithError error: Error) {
        Task { @MainActor in
            errorMessage = "AR Session failed: \(error.localizedDescription)"
            isRunning = false
        }
    }
    
    nonisolated func sessionWasInterrupted(_ session: ARSession) {
        Task { @MainActor in
            isRunning = false
        }
    }
    
    nonisolated func sessionInterruptionEnded(_ session: ARSession) {
        Task { @MainActor in
            if isRunning == false {
                startSession()
            }
        }
    }
}
