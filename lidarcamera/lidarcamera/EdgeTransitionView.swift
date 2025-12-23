import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

/// Simple edge detection transition - shows edge-detected image immediately with scan line
struct EdgeTransitionView: View {
    let sourceImage: CGImage
    
    @State private var scanLineY: CGFloat = 0.0
    @State private var pulseOpacity: Double = 1.0
    @State private var edgeImage: CGImage?
    
    private let ciContext = CIContext(options: [.useSoftwareRenderer: false])
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Black background
                Color.black
                    .ignoresSafeArea()
                
                // Edge-detected image (computed once, shown immediately)
                if let displayImage = edgeImage {
                    Image(decorative: displayImage, scale: 1.0, orientation: .up)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                        .opacity(pulseOpacity)
                }
                
                // Scanning line
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                .clear,
                                .cyan.opacity(0.5),
                                .white,
                                .cyan.opacity(0.5),
                                .clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 100)
                    .offset(y: -geometry.size.height/2 + scanLineY * geometry.size.height)
                    .blur(radius: 3)
                
                // "Initializing LiDAR" text at bottom
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
            }
        }
        .ignoresSafeArea()
        .onAppear {
            print("[EdgeTransition] onAppear")
            createEdgeImage()
            startAnimations()
        }
    }
    
    // MARK: - Image Processing (synchronous, fast)
    
    private func createEdgeImage() {
        print("[EdgeTransition] Creating edge image from \(sourceImage.width)x\(sourceImage.height)...")
        
        let ciImage = CIImage(cgImage: sourceImage)
        
        // Convert to grayscale
        guard let grayFilter = CIFilter(name: "CIPhotoEffectMono") else {
            print("[EdgeTransition] ERROR: Gray filter failed")
            return
        }
        grayFilter.setValue(ciImage, forKey: kCIInputImageKey)
        guard let grayOutput = grayFilter.outputImage else { return }
        
        // Apply edge detection
        guard let edgeFilter = CIFilter(name: "CIEdges") else {
            print("[EdgeTransition] ERROR: Edge filter failed")
            return
        }
        edgeFilter.setValue(grayOutput, forKey: kCIInputImageKey)
        edgeFilter.setValue(3.0, forKey: kCIInputIntensityKey)
        guard let edgeOutput = edgeFilter.outputImage else { return }
        
        // Boost brightness for visibility
        guard let brightnessFilter = CIFilter(name: "CIColorControls") else { return }
        brightnessFilter.setValue(edgeOutput, forKey: kCIInputImageKey)
        brightnessFilter.setValue(0.5, forKey: kCIInputBrightnessKey) // Boost
        brightnessFilter.setValue(2.0, forKey: kCIInputContrastKey) // High contrast
        guard let brightOutput = brightnessFilter.outputImage else { return }
        
        // Render to CGImage
        if let result = ciContext.createCGImage(brightOutput, from: brightOutput.extent) {
            edgeImage = result
            print("[EdgeTransition] Edge image created successfully")
        } else {
            print("[EdgeTransition] ERROR: Failed to create CGImage")
        }
    }
    
    // MARK: - Animations (lightweight, SwiftUI-only)
    
    private func startAnimations() {
        print("[EdgeTransition] Starting animations")
        
        // Scan line sweeps down continuously
        withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
            scanLineY = 1.0
        }
        
        // Subtle pulse effect on edges
        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
            pulseOpacity = 0.7
        }
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
