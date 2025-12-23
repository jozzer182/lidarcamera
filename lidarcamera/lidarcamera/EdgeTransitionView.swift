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
                    print("[EdgeTransition] ✅ B/W IMAGE IS NOW VISIBLE (saturation=0)")
                }
        }
        .ignoresSafeArea()
        .onAppear {
            print("[EdgeTransition] VIEW APPEARED - showing B/W of \(sourceImage.width)x\(sourceImage.height)")
        }
        .onDisappear {
            print("[EdgeTransition] VIEW DISAPPEARED")
        }
    }
}
