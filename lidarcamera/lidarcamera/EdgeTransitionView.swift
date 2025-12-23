import SwiftUI
import CoreImage

/// Simple B/W transition - just shows the captured camera frame in grayscale
struct EdgeTransitionView: View {
    let sourceImage: CGImage
    
    @State private var grayImage: CGImage?
    @State private var hasAppeared = false
    
    private let ciContext = CIContext(options: [.useSoftwareRenderer: false])
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Red debug background to confirm view is rendering
                Color.red
                    .ignoresSafeArea()
                
                // The actual content
                Group {
                    if let displayImage = grayImage {
                        Image(decorative: displayImage, scale: 1.0, orientation: .up)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .clipped()
                            .onAppear {
                                print("[EdgeTransition] ✅ GRAY IMAGE IS RENDERING")
                            }
                    } else if hasAppeared {
                        // Fallback - show original if gray failed
                        Image(decorative: sourceImage, scale: 1.0, orientation: .up)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .clipped()
                            .colorMultiply(.gray) // Simple grayscale effect
                            .onAppear {
                                print("[EdgeTransition] ⚠️ FALLBACK: Using colorMultiply gray")
                            }
                    } else {
                        Text("Loading...")
                            .foregroundStyle(.white)
                            .onAppear {
                                print("[EdgeTransition] ⏳ Loading placeholder visible")
                            }
                    }
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            print("[EdgeTransition] ========================================")
            print("[EdgeTransition] VIEW APPEARED")
            print("[EdgeTransition] Source image: \(sourceImage.width)x\(sourceImage.height)")
            print("[EdgeTransition] ========================================")
            hasAppeared = true
            createGrayscaleImage()
        }
        .onDisappear {
            print("[EdgeTransition] VIEW DISAPPEARED")
        }
    }
    
    private func createGrayscaleImage() {
        print("[EdgeTransition] createGrayscaleImage() starting...")
        
        let ciImage = CIImage(cgImage: sourceImage)
        print("[EdgeTransition] CIImage created from source")
        
        guard let filter = CIFilter(name: "CIPhotoEffectMono") else {
            print("[EdgeTransition] ❌ ERROR: CIPhotoEffectMono filter not available!")
            return
        }
        print("[EdgeTransition] CIPhotoEffectMono filter created")
        
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        
        guard let output = filter.outputImage else {
            print("[EdgeTransition] ❌ ERROR: Filter output is nil!")
            return
        }
        print("[EdgeTransition] Filter output created, extent: \(output.extent)")
        
        guard let result = ciContext.createCGImage(output, from: output.extent) else {
            print("[EdgeTransition] ❌ ERROR: Failed to create CGImage from filter output!")
            return
        }
        
        print("[EdgeTransition] ✅ Grayscale image created: \(result.width)x\(result.height)")
        grayImage = result
    }
}
