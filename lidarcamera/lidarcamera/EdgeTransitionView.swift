import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

/// Animated edge detection transition view - image progressively degrades to show only edges
/// Uses explicit Timer for animation since SwiftUI animation doesn't work with CoreImage rendering
struct EdgeTransitionView: View {
    let sourceImage: CGImage
    let duration: TimeInterval = 1.5
    
    @State private var phase: CGFloat = 0.0 // 0 = original, 1 = edges only
    @State private var opacity: Double = 1.0
    @State private var scanLineY: CGFloat = 0.0
    @State private var currentImage: CGImage?
    @State private var animationTimer: Timer?
    @State private var startTime: Date?
    
    private let ciContext = CIContext(options: [.useSoftwareRenderer: false])
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Black background
                Color.black
                    .ignoresSafeArea()
                
                // Rendered image (updated by timer)
                if let displayImage = currentImage {
                    Image(decorative: displayImage, scale: 1.0, orientation: .up)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                }
                
                // Scanning line
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                .clear,
                                .cyan.opacity(0.4),
                                .white.opacity(0.9),
                                .cyan.opacity(0.4),
                                .clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 80)
                    .offset(y: -geometry.size.height/2 + scanLineY * geometry.size.height)
                
                // "Initializing LiDAR" text
                VStack {
                    Spacer()
                    HStack(spacing: 8) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .cyan))
                            .scaleEffect(0.8)
                        Text("Initializing LiDAR...")
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                            .foregroundStyle(.cyan)
                    }
                    .padding(.bottom, 120)
                }
                .opacity(opacity)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            print("[EdgeTransition] onAppear - starting animation")
            startAnimations()
        }
        .onDisappear {
            print("[EdgeTransition] onDisappear - stopping timer")
            animationTimer?.invalidate()
            animationTimer = nil
        }
    }
    
    // MARK: - Animation
    
    private func startAnimations() {
        print("[EdgeTransition] startAnimations() called")
        
        // Set initial image
        currentImage = sourceImage
        startTime = Date()
        
        // Create timer for phase animation (30 fps)
        print("[EdgeTransition] Creating animation timer at 30fps")
        animationTimer = Timer.scheduledTimer(withTimeInterval: 1/30.0, repeats: true) { _ in
            updatePhase()
        }
        
        // Scan line animation
        withAnimation(.linear(duration: 0.8).repeatForever(autoreverses: false)) {
            scanLineY = 1.0
        }
        
        // Fade out at the end
        DispatchQueue.main.asyncAfter(deadline: .now() + duration * 0.85) {
            print("[EdgeTransition] Starting fade out")
            withAnimation(.easeOut(duration: duration * 0.15)) {
                opacity = 0
            }
        }
    }
    
    private func updatePhase() {
        guard let start = startTime else { return }
        
        let elapsed = Date().timeIntervalSince(start)
        let newPhase = min(elapsed / duration, 1.0)
        
        // Log every ~0.25 seconds
        if Int(elapsed * 4) != Int((elapsed - 1/30.0) * 4) {
            print("[EdgeTransition] Phase update: \(String(format: "%.2f", newPhase)) (elapsed: \(String(format: "%.2f", elapsed))s)")
        }
        
        phase = newPhase
        
        // Render new image
        if let rendered = renderProgressiveEdge(phase: phase) {
            currentImage = rendered
        }
        
        // Stop timer when complete
        if newPhase >= 1.0 {
            print("[EdgeTransition] Animation complete, stopping timer")
            animationTimer?.invalidate()
            animationTimer = nil
        }
    }
    
    // MARK: - Progressive Edge Rendering
    
    /// Render image with progressive edge detection based on phase (0 = original, 1 = edges only)
    private func renderProgressiveEdge(phase: CGFloat) -> CGImage? {
        let ciImage = CIImage(cgImage: sourceImage)
        let clampedPhase = max(0, min(1, phase))
        
        // Step 1: Create grayscale version
        guard let grayFilter = CIFilter(name: "CIPhotoEffectMono") else { 
            print("[EdgeTransition] ERROR: CIPhotoEffectMono filter failed")
            return nil 
        }
        grayFilter.setValue(ciImage, forKey: kCIInputImageKey)
        guard let grayImage = grayFilter.outputImage else { return nil }
        
        // Step 2: Create edge detection
        guard let edgeFilter = CIFilter(name: "CIEdges") else { 
            print("[EdgeTransition] ERROR: CIEdges filter failed")
            return nil 
        }
        edgeFilter.setValue(grayImage, forKey: kCIInputImageKey)
        edgeFilter.setValue(8.0, forKey: kCIInputIntensityKey) // Strong edges
        guard let edgeImage = edgeFilter.outputImage else { return nil }
        
        // Step 3: Blend based on phase
        // phase 0-0.3: darken original to grayscale
        // phase 0.3-1.0: fade grayscale to edges
        
        let darkPhase = min(clampedPhase / 0.3, 1.0)
        let edgePhase = max(0, (clampedPhase - 0.3) / 0.7)
        
        // Darken the original
        guard let darkenFilter = CIFilter(name: "CIExposureAdjust") else { return nil }
        darkenFilter.setValue(ciImage, forKey: kCIInputImageKey)
        darkenFilter.setValue(-Float(darkPhase) * 1.5, forKey: kCIInputEVKey)
        guard let darkenedOriginal = darkenFilter.outputImage else { return nil }
        
        // Blend original with grayscale
        guard let blendToGray = CIFilter(name: "CIDissolveTransition") else { return nil }
        blendToGray.setValue(darkenedOriginal, forKey: kCIInputImageKey)
        blendToGray.setValue(grayImage, forKey: kCIInputTargetImageKey)
        blendToGray.setValue(Float(darkPhase), forKey: kCIInputTimeKey)
        guard let grayBlended = blendToGray.outputImage else { return nil }
        
        // Blend grayscale with edges
        guard let blendToEdge = CIFilter(name: "CIDissolveTransition") else { return nil }
        blendToEdge.setValue(grayBlended, forKey: kCIInputImageKey)
        blendToEdge.setValue(edgeImage, forKey: kCIInputTargetImageKey)
        blendToEdge.setValue(Float(edgePhase), forKey: kCIInputTimeKey)
        guard let edgeBlended = blendToEdge.outputImage else { return nil }
        
        // Add cyan tint in later phases
        let tintAmount = max(0, edgePhase - 0.3) / 0.7
        guard let colorMatrix = CIFilter(name: "CIColorMatrix") else { return nil }
        colorMatrix.setValue(edgeBlended, forKey: kCIInputImageKey)
        
        let r = 1.0 - Float(tintAmount) * 0.5
        colorMatrix.setValue(CIVector(x: CGFloat(r), y: 0, z: 0, w: 0), forKey: "inputRVector")
        colorMatrix.setValue(CIVector(x: 0, y: 1, z: 0, w: 0), forKey: "inputGVector")
        colorMatrix.setValue(CIVector(x: 0, y: 0, z: 1, w: 0), forKey: "inputBVector")
        
        guard let tinted = colorMatrix.outputImage else { 
            return ciContext.createCGImage(edgeBlended, from: edgeBlended.extent)
        }
        
        return ciContext.createCGImage(tinted, from: tinted.extent)
    }
}

#Preview {
    let size = CGSize(width: 400, height: 600)
    UIGraphicsBeginImageContext(size)
    let ctx = UIGraphicsGetCurrentContext()!
    
    ctx.setFillColor(UIColor.darkGray.cgColor)
    ctx.fill(CGRect(origin: .zero, size: size))
    
    ctx.setFillColor(UIColor.white.cgColor)
    ctx.fillEllipse(in: CGRect(x: 100, y: 100, width: 200, height: 200))
    ctx.fill(CGRect(x: 50, y: 400, width: 300, height: 100))
    
    let image = UIGraphicsGetImageFromCurrentImageContext()!
    UIGraphicsEndImageContext()
    
    return EdgeTransitionView(sourceImage: image.cgImage!)
}
