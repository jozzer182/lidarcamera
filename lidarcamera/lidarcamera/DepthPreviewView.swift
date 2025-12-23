import SwiftUI

/// Full-screen depth visualization view
struct DepthPreviewView: View {
    @ObservedObject var depthManager: ARDepthManager
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Black background
                Color.black
                    .ignoresSafeArea()
                
                // Depth image
                if let cgImage = depthManager.depthImage {
                    Image(decorative: cgImage, scale: 1.0, orientation: .up)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                        .rotationEffect(.degrees(90)) // Adjust for landscape depth buffer (256x192)
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
}

#Preview {
    DepthPreviewView(depthManager: ARDepthManager())
}
