import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

/// Animated edge detection transition view - image progressively degrades to show only edges
struct EdgeTransitionView: View {
    let sourceImage: CGImage
    let duration: TimeInterval = 1.5
    
    @State private var phase: CGFloat = 0.0
    @State private var opacity: Double = 1.0
    @State private var scanLineY: CGFloat = 0.0
    @State private var currentImage: CGImage?
    @State private var animationTimer: Timer?
    @State private var startTime: Date?
    @State private var frameCount: Int = 0
    
    // Pre-computed images for performance
    @State private var originalImage: CGImage?
    @State private var grayImage: CGImage?
    @State private var edgeImage: CGImage?
    
    private let ciContext = CIContext(options: [.useSoftwareRenderer: false])
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Black background
                Color.black
                    .ignoresSafeArea()
                
                // Rendered image
                if let displayImage = currentImage ?? originalImage ?? sourceImage as CGImage? {
                    Image(decorative: displayImage, scale: 1.0, orientation: .up)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                } else {
                    // Fallback - should never happen
                    Text("No image")
                        .foregroundStyle(.red)
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
            print("[EdgeTransition] onAppear - source image: \(sourceImage.width)x\(sourceImage.height)")
            prepareImages()
            startAnimations()
        }
        .onDisappear {
            print("[EdgeTransition] onDisappear")
            animationTimer?.invalidate()
            animationTimer = nil
        }
    }
    
    // MARK: - Pre-compute Images
    
    private func prepareImages() {
        print("[EdgeTransition] prepareImages() - pre-computing gray and edge versions...")
        
        // Keep original
        originalImage = sourceImage
        currentImage = sourceImage
        
        let ciImage = CIImage(cgImage: sourceImage)
        
        // Pre-compute grayscale
        if let grayFilter = CIFilter(name: "CIPhotoEffectMono") {
            grayFilter.setValue(ciImage, forKey: kCIInputImageKey)
            if let output = grayFilter.outputImage,
               let cgGray = ciContext.createCGImage(output, from: output.extent) {
                grayImage = cgGray
                print("[EdgeTransition] Gray image created: \(cgGray.width)x\(cgGray.height)")
            } else {
                print("[EdgeTransition] ERROR: Failed to create gray image")
            }
        }
        
        // Pre-compute edges
        if let grayCI = grayImage.map({ CIImage(cgImage: $0) }),
           let edgeFilter = CIFilter(name: "CIEdges") {
            edgeFilter.setValue(grayCI, forKey: kCIInputImageKey)
            edgeFilter.setValue(5.0, forKey: kCIInputIntensityKey)
            if let output = edgeFilter.outputImage,
               let cgEdge = ciContext.createCGImage(output, from: output.extent) {
                edgeImage = cgEdge
                print("[EdgeTransition] Edge image created: \(cgEdge.width)x\(cgEdge.height)")
            } else {
                print("[EdgeTransition] ERROR: Failed to create edge image")
            }
        }
    }
    
    // MARK: - Animation
    
    private func startAnimations() {
        print("[EdgeTransition] startAnimations()")
        startTime = Date()
        
        // Timer at 15fps (less CPU intensive)
        animationTimer = Timer.scheduledTimer(withTimeInterval: 1/15.0, repeats: true) { _ in
            updatePhase()
        }
        
        // Scan line animation
        withAnimation(.linear(duration: 0.8).repeatForever(autoreverses: false)) {
            scanLineY = 1.0
        }
        
        // Fade out at end
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
        frameCount += 1
        
        // Log periodically
        if frameCount % 8 == 0 { // Every ~0.5 seconds
            print("[EdgeTransition] Frame \(frameCount): phase=\(String(format: "%.2f", newPhase))")
        }
        
        phase = newPhase
        
        // Simple cross-fade between pre-computed images
        updateCurrentImage(phase: newPhase)
        
        if newPhase >= 1.0 {
            print("[EdgeTransition] Animation complete at frame \(frameCount)")
            animationTimer?.invalidate()
            animationTimer = nil
        }
    }
    
    private func updateCurrentImage(phase: CGFloat) {
        // Simple 3-stage transition using pre-computed images
        // 0.0-0.3: original
        // 0.3-0.6: grayscale  
        // 0.6-1.0: edges
        
        if phase < 0.3 {
            // Show original (maybe slightly darkened)
            if let img = blendImages(originalImage, grayImage, blend: phase / 0.3) {
                currentImage = img
            }
        } else if phase < 0.6 {
            // Transition from gray to edges
            if let img = blendImages(grayImage, edgeImage, blend: (phase - 0.3) / 0.3) {
                currentImage = img
            }
        } else {
            // Show edges
            currentImage = edgeImage
        }
    }
    
    private func blendImages(_ image1: CGImage?, _ image2: CGImage?, blend: CGFloat) -> CGImage? {
        guard let img1 = image1, let img2 = image2 else {
            return image1 ?? image2
        }
        
        let ci1 = CIImage(cgImage: img1)
        let ci2 = CIImage(cgImage: img2)
        
        guard let blendFilter = CIFilter(name: "CIDissolveTransition") else { return img1 }
        blendFilter.setValue(ci1, forKey: kCIInputImageKey)
        blendFilter.setValue(ci2, forKey: kCIInputTargetImageKey)
        blendFilter.setValue(Float(blend), forKey: kCIInputTimeKey)
        
        guard let output = blendFilter.outputImage else { return img1 }
        return ciContext.createCGImage(output, from: output.extent)
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
    
    let image = UIGraphicsGetImageFromCurrentImageContext()!
    UIGraphicsEndImageContext()
    
    return EdgeTransitionView(sourceImage: image.cgImage!)
}
