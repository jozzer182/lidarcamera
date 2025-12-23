import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

/// Progressive edge detection transition with pre-computed frames
/// Pre-renders keyframes for smooth, lightweight playback
struct EdgeTransitionView: View {
    let sourceImage: CGImage
    let duration: TimeInterval = 1.5
    
    @State private var currentImage: CGImage?
    @State private var precomputedFrames: [CGImage] = []
    @State private var currentFrameIndex: Int = 0
    @State private var animationTimer: Timer?
    @State private var isPrecomputing: Bool = true
    
    private let ciContext = CIContext(options: [.useSoftwareRenderer: false])
    private let frameCount = 10
    
    var body: some View {
        GeometryReader { geometry in
            if let displayImage = currentImage {
                Image(decorative: displayImage, scale: 1.0, orientation: .up)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
            } else {
                // Show grayscale source while precomputing
                Image(decorative: sourceImage, scale: 1.0, orientation: .up)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .saturation(0)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            precomputeFrames()
        }
        .onDisappear {
            stopAnimation()
        }
    }
    
    // MARK: - Pre-compute Frames
    
    private func precomputeFrames() {
        DispatchQueue.global(qos: .userInitiated).async {
            var frames: [CGImage] = []
            
            for i in 0..<frameCount {
                let phase = CGFloat(i) / CGFloat(frameCount - 1)
                if let frame = renderFrame(at: phase) {
                    frames.append(frame)
                }
            }
            
            DispatchQueue.main.async {
                precomputedFrames = frames
                isPrecomputing = false
                
                if !frames.isEmpty {
                    currentImage = frames[0]
                    startAnimation()
                }
            }
        }
    }
    
    // MARK: - Animation
    
    private func startAnimation() {
        guard !precomputedFrames.isEmpty else { return }
        
        let frameInterval = duration / Double(precomputedFrames.count - 1)
        currentFrameIndex = 0
        
        animationTimer = Timer.scheduledTimer(withTimeInterval: frameInterval, repeats: true) { [self] _ in
            currentFrameIndex += 1
            
            if currentFrameIndex >= precomputedFrames.count {
                stopAnimation()
                return
            }
            
            currentImage = precomputedFrames[currentFrameIndex]
        }
    }
    
    private func stopAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
    }
    
    // MARK: - Frame Rendering
    
    private func renderFrame(at phase: CGFloat) -> CGImage? {
        let ciImage = CIImage(cgImage: sourceImage)
        let clampedPhase = max(0, min(1, phase))
        
        // Create grayscale
        guard let grayFilter = CIFilter(name: "CIPhotoEffectMono") else { return nil }
        grayFilter.setValue(ciImage, forKey: kCIInputImageKey)
        guard let grayImage = grayFilter.outputImage else { return nil }
        
        // Create edges with increasing intensity
        guard let edgeFilter = CIFilter(name: "CIEdges") else { return nil }
        edgeFilter.setValue(grayImage, forKey: kCIInputImageKey)
        edgeFilter.setValue(3.0 + clampedPhase * 7.0, forKey: kCIInputIntensityKey)
        guard let edgeImage = edgeFilter.outputImage else { return nil }
        
        // Darken grayscale progressively
        guard let darkenFilter = CIFilter(name: "CIExposureAdjust") else { return nil }
        darkenFilter.setValue(grayImage, forKey: kCIInputImageKey)
        darkenFilter.setValue(-Float(clampedPhase) * 4.0, forKey: kCIInputEVKey)
        guard let darkenedGray = darkenFilter.outputImage else { return nil }
        
        // Blend with screen mode
        guard let blendFilter = CIFilter(name: "CIScreenBlendMode") else { return nil }
        blendFilter.setValue(darkenedGray, forKey: kCIInputImageKey)
        blendFilter.setValue(edgeImage, forKey: kCIInputBackgroundImageKey)
        guard let blended = blendFilter.outputImage else { return nil }
        
        return ciContext.createCGImage(blended, from: blended.extent)
    }
}
