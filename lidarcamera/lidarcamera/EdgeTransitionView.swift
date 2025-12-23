import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

/// Progressive edge detection transition
/// Animates from original B/W image to just edge lines over 1.5 seconds
struct EdgeTransitionView: View {
    let sourceImage: CGImage
    let duration: TimeInterval = 1.5
    
    @State private var currentImage: CGImage?
    @State private var phase: CGFloat = 0.0 // 0 = B/W, 1 = edges only
    @State private var displayLink: CADisplayLink?
    @State private var startTime: CFTimeInterval = 0
    @State private var frameCount: Int = 0
    
    private let ciContext = CIContext(options: [.useSoftwareRenderer: false])
    
    var body: some View {
        GeometryReader { geometry in
            if let displayImage = currentImage {
                Image(decorative: displayImage, scale: 1.0, orientation: .up)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
            }
        }
        .ignoresSafeArea()
        .onAppear {
            print("[EdgeTransition] ============================================")
            print("[EdgeTransition] VIEW APPEARED - Starting progressive animation")
            print("[EdgeTransition] Source: \(sourceImage.width)x\(sourceImage.height)")
            print("[EdgeTransition] Duration: \(duration)s")
            print("[EdgeTransition] ============================================")
            
            // Set initial image (grayscale original)
            currentImage = createGrayscaleImage(from: sourceImage)
            print("[EdgeTransition] Initial grayscale image created")
            
            // Start animation
            startAnimation()
        }
        .onDisappear {
            print("[EdgeTransition] VIEW DISAPPEARED - Stopping animation")
            stopAnimation()
        }
    }
    
    // MARK: - Animation Control
    
    private func startAnimation() {
        print("[EdgeTransition] 🎬 Starting DisplayLink animation")
        startTime = CACurrentMediaTime()
        
        // Create DisplayLink for 60fps updates
        let link = CADisplayLink(target: DisplayLinkTarget { [self] in
            updateFrame()
        }, selector: #selector(DisplayLinkTarget.tick))
        
        link.add(to: .main, forMode: .common)
        displayLink = link
        print("[EdgeTransition] ✅ DisplayLink added to runloop")
    }
    
    private func stopAnimation() {
        displayLink?.invalidate()
        displayLink = nil
        print("[EdgeTransition] ⏹️ DisplayLink invalidated")
    }
    
    private func updateFrame() {
        let elapsed = CACurrentMediaTime() - startTime
        let newPhase = min(CGFloat(elapsed / duration), 1.0)
        frameCount += 1
        
        // Log every 15 frames (~4 times per second at 60fps)
        if frameCount % 15 == 0 {
            print("[EdgeTransition] Frame \(frameCount): phase=\(String(format: "%.2f", newPhase)) elapsed=\(String(format: "%.2f", elapsed))s")
        }
        
        phase = newPhase
        
        // Render new image based on phase
        if let rendered = renderProgressiveEdge(phase: phase) {
            currentImage = rendered
        } else {
            print("[EdgeTransition] ⚠️ Frame \(frameCount): Render returned nil!")
        }
        
        // Stop when complete
        if newPhase >= 1.0 {
            print("[EdgeTransition] 🏁 Animation complete at frame \(frameCount)")
            stopAnimation()
        }
    }
    
    // MARK: - Image Processing
    
    private func createGrayscaleImage(from source: CGImage) -> CGImage? {
        print("[EdgeTransition] Creating grayscale from source...")
        let ciImage = CIImage(cgImage: source)
        
        guard let filter = CIFilter(name: "CIPhotoEffectMono") else {
            print("[EdgeTransition] ❌ CIPhotoEffectMono not available")
            return source
        }
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        
        guard let output = filter.outputImage,
              let result = ciContext.createCGImage(output, from: output.extent) else {
            print("[EdgeTransition] ❌ Failed to create grayscale CGImage")
            return source
        }
        
        print("[EdgeTransition] ✅ Grayscale image: \(result.width)x\(result.height)")
        return result
    }
    
    /// Renders progressive transition from grayscale to edge-only
    /// Phase 0.0 = grayscale original
    /// Phase 0.5 = half grayscale, half edges blended
    /// Phase 1.0 = edges only (white lines on black)
    private func renderProgressiveEdge(phase: CGFloat) -> CGImage? {
        let ciImage = CIImage(cgImage: sourceImage)
        let clampedPhase = max(0, min(1, phase))
        
        // Step 1: Create grayscale version
        guard let grayFilter = CIFilter(name: "CIPhotoEffectMono") else { return nil }
        grayFilter.setValue(ciImage, forKey: kCIInputImageKey)
        guard let grayImage = grayFilter.outputImage else { return nil }
        
        // Step 2: Create edge detection
        guard let edgeFilter = CIFilter(name: "CIEdges") else { return nil }
        edgeFilter.setValue(grayImage, forKey: kCIInputImageKey)
        edgeFilter.setValue(5.0 + clampedPhase * 5.0, forKey: kCIInputIntensityKey) // Intensity increases with phase
        guard let edgeImage = edgeFilter.outputImage else { return nil }
        
        // Step 3: Darken the grayscale progressively
        guard let darkenFilter = CIFilter(name: "CIExposureAdjust") else { return nil }
        darkenFilter.setValue(grayImage, forKey: kCIInputImageKey)
        darkenFilter.setValue(-Float(clampedPhase) * 3.0, forKey: kCIInputEVKey) // -3EV at phase 1.0
        guard let darkenedGray = darkenFilter.outputImage else { return nil }
        
        // Step 4: Blend darkened gray with edges
        guard let blendFilter = CIFilter(name: "CIAdditionCompositing") else { return nil }
        blendFilter.setValue(darkenedGray, forKey: kCIInputImageKey)
        blendFilter.setValue(edgeImage, forKey: kCIInputBackgroundImageKey)
        guard let blended = blendFilter.outputImage else { return nil }
        
        // Create CGImage
        return ciContext.createCGImage(blended, from: blended.extent)
    }
}

// MARK: - DisplayLink Target Helper

/// Helper class to use DisplayLink with closures (avoids @objc in structs)
class DisplayLinkTarget {
    let callback: () -> Void
    
    init(callback: @escaping () -> Void) {
        self.callback = callback
    }
    
    @objc func tick() {
        callback()
    }
}
