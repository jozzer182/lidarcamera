import SwiftUI

/// Simple B/W transition - just shows the captured camera frame in grayscale
struct EdgeTransitionView: View {
    let sourceImage: CGImage
    
    var body: some View {
        GeometryReader { geometry in
            // Show the original image with grayscale modifier - NO CoreImage needed!
            Image(decorative: sourceImage, scale: 1.0, orientation: .up)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
                .saturation(0) // SwiftUI native grayscale - instant, no processing
                .onAppear {
                    print("[EdgeTransition] ✅ IMAGE RENDERING")
                    print("[EdgeTransition] sourceImage size: \(sourceImage.width)x\(sourceImage.height)")
                    print("[EdgeTransition] sourceImage bitsPerPixel: \(sourceImage.bitsPerPixel)")
                    print("[EdgeTransition] sourceImage bitsPerComponent: \(sourceImage.bitsPerComponent)")
                    print("[EdgeTransition] geometry size: \(geometry.size)")
                    
                    // Check if image has content
                    if let colorSpace = sourceImage.colorSpace {
                        print("[EdgeTransition] colorSpace: \(colorSpace.name ?? "unknown" as CFString)")
                    } else {
                        print("[EdgeTransition] ⚠️ WARNING: No colorSpace!")
                    }
                }
        }
        .ignoresSafeArea()
        .onAppear {
            print("[EdgeTransition] ========================================")
            print("[EdgeTransition] VIEW APPEARED")
            print("[EdgeTransition] sourceImage: \(sourceImage.width)x\(sourceImage.height)")
            print("[EdgeTransition] ========================================")
        }
        .onDisappear {
            print("[EdgeTransition] VIEW DISAPPEARED")
        }
    }
}
