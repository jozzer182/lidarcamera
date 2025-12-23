import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

/// Full-screen depth visualization view with blurred background fill
struct DepthPreviewView: View {
    @ObservedObject var depthManager: ARDepthManager
    
    // Blur radius for background (adjust for performance vs quality)
    private let blurRadius: CGFloat = 25
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Black background (fallback)
                Color.black
                    .ignoresSafeArea()
                
                // Depth image with blurred background
                if let cgImage = depthManager.depthImage {
                    // Layer 1: Blurred stretched background (fills entire screen)
                    blurredBackground(from: cgImage, size: geometry.size)
                        .ignoresSafeArea()
                    
                    // Layer 2: Sharp depth image (maintains aspect ratio)
                    Image(decorative: cgImage, scale: 1.0, orientation: .up)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .rotationEffect(.degrees(90))
                    
                } else if depthManager.isRunning {
                    // Loading indicator
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                } else if !depthManager.isDepthSupported {
                    // Not supported message
                    VStack(spacing: 16) {
                        Image(systemName: "sensor.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.white.opacity(0.6))
                        Text("LiDAR Not Available")
                            .font(.headline)
                            .foregroundStyle(.white.opacity(0.8))
                        Text("This device doesn't support scene depth")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
            }
        }
        .ignoresSafeArea()
    }
    
    /// Create blurred, stretched background from depth image
    @ViewBuilder
    private func blurredBackground(from cgImage: CGImage, size: CGSize) -> some View {
        // Use SwiftUI's blur for simplicity and performance
        Image(decorative: cgImage, scale: 1.0, orientation: .up)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: size.width, height: size.height)
            .rotationEffect(.degrees(90))
            .blur(radius: blurRadius)
            .scaleEffect(1.2) // Slightly larger to avoid edge artifacts from blur
            .clipped()
    }
}

#Preview {
    DepthPreviewView(depthManager: ARDepthManager())
}
