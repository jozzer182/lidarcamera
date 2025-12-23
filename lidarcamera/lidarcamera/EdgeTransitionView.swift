import SwiftUI
import CoreImage

/// Simple B/W transition - just shows the captured camera frame in grayscale
struct EdgeTransitionView: View {
    let sourceImage: CGImage
    
    @State private var grayImage: CGImage?
    
    private let ciContext = CIContext(options: [.useSoftwareRenderer: false])
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                // Grayscale camera image
                if let displayImage = grayImage ?? sourceImage as CGImage? {
                    Image(decorative: displayImage, scale: 1.0, orientation: .up)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            createGrayscaleImage()
        }
    }
    
    private func createGrayscaleImage() {
        let ciImage = CIImage(cgImage: sourceImage)
        
        guard let filter = CIFilter(name: "CIPhotoEffectMono") else { return }
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        
        guard let output = filter.outputImage,
              let result = ciContext.createCGImage(output, from: output.extent) else { return }
        
        grayImage = result
    }
}
