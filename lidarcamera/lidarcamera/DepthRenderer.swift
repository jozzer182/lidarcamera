import CoreImage
import CoreVideo
import Accelerate

/// Renders depth buffer to grayscale banded image with contour lines
class DepthRenderer {
    
    // MARK: - Properties
    
    /// Step size for depth quantization in meters
    var stepMeters: Float = 0.05
    
    /// Maximum depth range in meters (beyond this is black)
    var maxRangeMeters: Float = 3.0
    
    /// Minimum depth in meters (closer is clamped to white)
    var minRangeMeters: Float = 0.1
    
    /// Enable contour lines at band boundaries
    var showContours: Bool = true
    
    /// Contour line intensity (0-1)
    var contourIntensity: Float = 0.8
    
    private let ciContext = CIContext(options: [.useSoftwareRenderer: false])
    
    // MARK: - Public Methods
    
    /// Render depth map to grayscale banded CGImage with contours
    func render(depthMap: CVPixelBuffer, confidenceMap: CVPixelBuffer?) -> CGImage? {
        CVPixelBufferLockBaseAddress(depthMap, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(depthMap, .readOnly) }
        
        let width = CVPixelBufferGetWidth(depthMap)
        let height = CVPixelBufferGetHeight(depthMap)
        
        guard let baseAddress = CVPixelBufferGetBaseAddress(depthMap) else {
            return nil
        }
        
        let depthPointer = baseAddress.assumingMemoryBound(to: Float32.self)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(depthMap)
        let floatsPerRow = bytesPerRow / MemoryLayout<Float32>.size
        
        // Create output buffer for grayscale image
        var outputPixels = [UInt8](repeating: 0, count: width * height)
        var bandIndices = [Int](repeating: 0, count: width * height)
        
        // Process each pixel
        for y in 0..<height {
            for x in 0..<width {
                let depthIndex = y * floatsPerRow + x
                let outputIndex = y * width + x
                
                let depthValue = depthPointer[depthIndex]
                
                // Handle invalid depth (NaN, Inf, or out of range)
                guard depthValue.isFinite && depthValue > 0 else {
                    outputPixels[outputIndex] = 0 // Black for invalid
                    bandIndices[outputIndex] = -1
                    continue
                }
                
                // Clamp depth to range
                let clampedDepth = max(minRangeMeters, min(depthValue, maxRangeMeters))
                
                // Quantize to bands
                let bandIndex = Int(floor(clampedDepth / stepMeters))
                let quantizedDepth = Float(bandIndex) * stepMeters
                bandIndices[outputIndex] = bandIndex
                
                // Map to grayscale (near = white, far = black)
                let normalizedDepth = (quantizedDepth - minRangeMeters) / (maxRangeMeters - minRangeMeters)
                let grayValue = UInt8(max(0, min(255, (1.0 - normalizedDepth) * 255.0)))
                
                outputPixels[outputIndex] = grayValue
            }
        }
        
        // Add contour lines at band boundaries
        if showContours {
            addContourLines(
                pixels: &outputPixels,
                bandIndices: bandIndices,
                width: width,
                height: height
            )
        }
        
        // Create CGImage from pixel buffer
        return createCGImage(from: outputPixels, width: width, height: height)
    }
    
    // MARK: - Private Methods
    
    /// Add contour lines where band indices differ between adjacent pixels
    private func addContourLines(
        pixels: inout [UInt8],
        bandIndices: [Int],
        width: Int,
        height: Int
    ) {
        let contourValue = UInt8(contourIntensity * 255)
        
        for y in 1..<(height - 1) {
            for x in 1..<(width - 1) {
                let idx = y * width + x
                let currentBand = bandIndices[idx]
                
                // Skip invalid pixels
                guard currentBand >= 0 else { continue }
                
                // Check 4-connected neighbors for band boundary
                let neighbors = [
                    bandIndices[idx - 1],         // left
                    bandIndices[idx + 1],         // right
                    bandIndices[idx - width],     // top
                    bandIndices[idx + width]      // bottom
                ]
                
                var isEdge = false
                for neighborBand in neighbors {
                    if neighborBand >= 0 && neighborBand != currentBand {
                        isEdge = true
                        break
                    }
                }
                
                if isEdge {
                    // Draw contour (bright line)
                    pixels[idx] = min(255, pixels[idx] + contourValue / 2)
                }
            }
        }
    }
    
    /// Create CGImage from grayscale pixel array
    private func createCGImage(from pixels: [UInt8], width: Int, height: Int) -> CGImage? {
        let colorSpace = CGColorSpaceCreateDeviceGray()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue)
        
        guard let provider = CGDataProvider(data: Data(pixels) as CFData) else {
            return nil
        }
        
        return CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 8,
            bytesPerRow: width,
            space: colorSpace,
            bitmapInfo: bitmapInfo,
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        )
    }
}
