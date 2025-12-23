import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

/// Animated edge detection transition view for LiDAR mode switch
struct EdgeTransitionView: View {
    let sourceImage: CGImage
    let duration: TimeInterval = 1.5
    
    @State private var opacity: Double = 1.0
    @State private var scanProgress: CGFloat = 0.0
    
    private let ciContext = CIContext(options: [.useSoftwareRenderer: false])
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Black background
                Color.black
                    .ignoresSafeArea()
                
                // Edge-detected image
                if let edgeImage = applyEdgeDetection(to: sourceImage) {
                    Image(decorative: edgeImage, scale: 1.0, orientation: .up)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                        .opacity(opacity)
                }
                
                // Scanning line animation
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                .clear,
                                .cyan.opacity(0.5),
                                .white.opacity(0.8),
                                .cyan.opacity(0.5),
                                .clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 60)
                    .offset(y: -geometry.size.height/2 + scanProgress * geometry.size.height)
                    .opacity(opacity * 0.8)
                
                // "Initializing LiDAR" text
                VStack {
                    Spacer()
                    Text("Initializing LiDAR")
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundStyle(.cyan.opacity(0.8))
                        .padding(.bottom, 150)
                        .opacity(opacity)
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            startAnimations()
        }
    }
    
    // MARK: - Animation
    
    private func startAnimations() {
        // Scan line animation
        withAnimation(.linear(duration: duration).repeatForever(autoreverses: false)) {
            scanProgress = 1.0
        }
        
        // Fade out near end
        DispatchQueue.main.asyncAfter(deadline: .now() + duration * 0.7) {
            withAnimation(.easeOut(duration: duration * 0.3)) {
                opacity = 0
            }
        }
    }
    
    // MARK: - Edge Detection
    
    /// Apply Sobel edge detection filter to create white lines on black background
    private func applyEdgeDetection(to cgImage: CGImage) -> CGImage? {
        let ciImage = CIImage(cgImage: cgImage)
        
        // Convert to grayscale first
        guard let grayscaleFilter = CIFilter(name: "CIPhotoEffectMono") else { return nil }
        grayscaleFilter.setValue(ciImage, forKey: kCIInputImageKey)
        guard let grayscaleImage = grayscaleFilter.outputImage else { return nil }
        
        // Apply edge detection (Sobel-like)
        guard let edgeFilter = CIFilter(name: "CIEdges") else { return nil }
        edgeFilter.setValue(grayscaleImage, forKey: kCIInputImageKey)
        edgeFilter.setValue(5.0, forKey: kCIInputIntensityKey) // Increase edge intensity
        guard let edgeImage = edgeFilter.outputImage else { return nil }
        
        // Invert colors (white edges on black)
        guard let invertFilter = CIFilter(name: "CIColorInvert") else { return nil }
        invertFilter.setValue(edgeImage, forKey: kCIInputImageKey)
        guard let invertedImage = invertFilter.outputImage else { return nil }
        
        // Apply color matrix to make it more contrasty cyan/white
        guard let colorMatrix = CIFilter(name: "CIColorMatrix") else { return nil }
        colorMatrix.setValue(invertedImage, forKey: kCIInputImageKey)
        // Boost blue/cyan channel
        colorMatrix.setValue(CIVector(x: 0.5, y: 0, z: 0, w: 0), forKey: "inputRVector")
        colorMatrix.setValue(CIVector(x: 0, y: 0.8, z: 0, w: 0), forKey: "inputGVector")
        colorMatrix.setValue(CIVector(x: 0, y: 0, z: 1.0, w: 0), forKey: "inputBVector")
        guard let finalImage = colorMatrix.outputImage else { return nil }
        
        // Render to CGImage
        let extent = finalImage.extent
        return ciContext.createCGImage(finalImage, from: extent)
    }
}

#Preview {
    // Create a test pattern for preview
    let size = CGSize(width: 400, height: 600)
    UIGraphicsBeginImageContext(size)
    let context = UIGraphicsGetCurrentContext()!
    
    // Draw some shapes
    context.setFillColor(UIColor.gray.cgColor)
    context.fill(CGRect(origin: .zero, size: size))
    
    context.setFillColor(UIColor.white.cgColor)
    context.fillEllipse(in: CGRect(x: 100, y: 100, width: 200, height: 200))
    context.fill(CGRect(x: 50, y: 400, width: 300, height: 100))
    
    let image = UIGraphicsGetImageFromCurrentImageContext()!
    UIGraphicsEndImageContext()
    
    return EdgeTransitionView(sourceImage: image.cgImage!)
}
