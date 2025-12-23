import CoreImage
import CoreVideo
import Accelerate

/// Renders depth buffer to grayscale or color banded image with optional contour lines
class DepthRenderer {
    
    // MARK: - Properties
    
    /// Step size for depth quantization in meters
    var stepMeters: Float = 0.05
    
    /// Maximum depth range in meters (beyond this is black/blue)
    var maxRangeMeters: Float = 3.0
    
    /// Minimum depth in meters (closer is clamped to white/red)
    var minRangeMeters: Float = 0.1
    
    /// Enable contour lines at band boundaries
    var showContours: Bool = false
    
    /// Contour line intensity (0-1)
    var contourIntensity: Float = 0.8
    
    /// Use color mode (red=near, blue=far) instead of grayscale
    var useColorMode: Bool = false
    
    private let ciContext = CIContext(options: [.useSoftwareRenderer: false])
    
    // MARK: - Public Methods
    
    /// Render depth map to banded CGImage (grayscale or color)
    func render(depthMap: CVPixelBuffer, confidenceMap: CVPixelBuffer?) -> CGImage? {
        CVPixelBufferLockBaseAddress(depthMap, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(depthMap, .readOnly) }
        
        let width = CVPixelBufferGetWidth(depthMap)
        let height = CVPixelBufferGetHeight(depthMap)
        
        guard let baseAddress = CVPixelBufferGetBaseAddress(depthMap) else {
            print("[DepthRenderer] ERROR: Could not get base address of depth buffer")
            return nil
        }
        
        let depthPointer = baseAddress.assumingMemoryBound(to: Float32.self)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(depthMap)
        let floatsPerRow = bytesPerRow / MemoryLayout<Float32>.size
        
        // Band indices for contour detection
        var bandIndices = [Int](repeating: 0, count: width * height)
        
        if useColorMode {
            return renderColor(
                depthPointer: depthPointer,
                floatsPerRow: floatsPerRow,
                width: width,
                height: height,
                bandIndices: &bandIndices
            )
        } else {
            return renderGrayscale(
                depthPointer: depthPointer,
                floatsPerRow: floatsPerRow,
                width: width,
                height: height,
                bandIndices: &bandIndices
            )
        }
    }
    
    // MARK: - Grayscale Rendering
    
    private func renderGrayscale(
        depthPointer: UnsafeMutablePointer<Float32>,
        floatsPerRow: Int,
        width: Int,
        height: Int,
        bandIndices: inout [Int]
    ) -> CGImage? {
        var outputPixels = [UInt8](repeating: 0, count: width * height)
        
        for y in 0..<height {
            for x in 0..<width {
                let depthIndex = y * floatsPerRow + x
                let outputIndex = y * width + x
                
                let depthValue = depthPointer[depthIndex]
                
                guard depthValue.isFinite && depthValue > 0 else {
                    outputPixels[outputIndex] = 0
                    bandIndices[outputIndex] = -1
                    continue
                }
                
                let clampedDepth = max(minRangeMeters, min(depthValue, maxRangeMeters))
                let bandIndex = Int(floor(clampedDepth / stepMeters))
                let quantizedDepth = Float(bandIndex) * stepMeters
                bandIndices[outputIndex] = bandIndex
                
                let normalizedDepth = (quantizedDepth - minRangeMeters) / (maxRangeMeters - minRangeMeters)
                let grayValue = UInt8(max(0, min(255, (1.0 - normalizedDepth) * 255.0)))
                
                outputPixels[outputIndex] = grayValue
            }
        }
        
        if showContours {
            addContourLinesToGrayscale(pixels: &outputPixels, bandIndices: bandIndices, width: width, height: height)
        }
        
        return createGrayscaleCGImage(from: outputPixels, width: width, height: height)
    }
    
    // MARK: - Color Rendering (Red = Near, Blue = Far)
    
    private func renderColor(
        depthPointer: UnsafeMutablePointer<Float32>,
        floatsPerRow: Int,
        width: Int,
        height: Int,
        bandIndices: inout [Int]
    ) -> CGImage? {
        // RGB pixels (3 bytes per pixel)
        var outputPixels = [UInt8](repeating: 0, count: width * height * 3)
        
        for y in 0..<height {
            for x in 0..<width {
                let depthIndex = y * floatsPerRow + x
                let outputIndex = (y * width + x) * 3
                
                let depthValue = depthPointer[depthIndex]
                
                guard depthValue.isFinite && depthValue > 0 else {
                    // Black for invalid
                    outputPixels[outputIndex] = 0     // R
                    outputPixels[outputIndex + 1] = 0 // G
                    outputPixels[outputIndex + 2] = 0 // B
                    bandIndices[y * width + x] = -1
                    continue
                }
                
                let clampedDepth = max(minRangeMeters, min(depthValue, maxRangeMeters))
                let bandIndex = Int(floor(clampedDepth / stepMeters))
                let quantizedDepth = Float(bandIndex) * stepMeters
                bandIndices[y * width + x] = bandIndex
                
                // Normalized: 0 = near (red), 1 = far (blue)
                let normalizedDepth = (quantizedDepth - minRangeMeters) / (maxRangeMeters - minRangeMeters)
                
                // HSL color: Hue varies 0°-240° (red→blue)
                let (r, g, b) = hslColor(normalizedDepth: normalizedDepth)
                
                outputPixels[outputIndex] = r
                outputPixels[outputIndex + 1] = g
                outputPixels[outputIndex + 2] = b
            }
        }
        
        if showContours {
            addContourLinesToColor(pixels: &outputPixels, bandIndices: bandIndices, width: width, height: height)
        }
        
        return createRGBCGImage(from: outputPixels, width: width, height: height)
    }
    
    /// Generate color from depth using HSL: only Hue varies (0°=red/near → 360°=magenta/far)
    /// S=1.0, L=0.5 for vibrant colors
    private func hslColor(normalizedDepth: Float) -> (UInt8, UInt8, UInt8) {
        let t = max(0, min(1, normalizedDepth))
        
        // Hue: 0 (red) → 240 (blue) for near→far
        // Using 0-240 range to go from red through yellow, green, cyan to blue
        let hue = t * 240.0 // 0° to 240°
        let saturation: Float = 1.0
        let lightness: Float = 0.5
        
        // Convert HSL to RGB
        let (r, g, b) = hslToRGB(h: hue, s: saturation, l: lightness)
        
        return (
            UInt8(max(0, min(255, r * 255))),
            UInt8(max(0, min(255, g * 255))),
            UInt8(max(0, min(255, b * 255)))
        )
    }
    
    /// Convert HSL to RGB
    /// h: 0-360, s: 0-1, l: 0-1
    private func hslToRGB(h: Float, s: Float, l: Float) -> (Float, Float, Float) {
        let c = (1 - abs(2 * l - 1)) * s // Chroma
        let hPrime = h / 60.0
        let x = c * (1 - abs(hPrime.truncatingRemainder(dividingBy: 2) - 1))
        
        var r: Float = 0
        var g: Float = 0
        var b: Float = 0
        
        if hPrime < 1 {
            r = c; g = x; b = 0
        } else if hPrime < 2 {
            r = x; g = c; b = 0
        } else if hPrime < 3 {
            r = 0; g = c; b = x
        } else if hPrime < 4 {
            r = 0; g = x; b = c
        } else if hPrime < 5 {
            r = x; g = 0; b = c
        } else {
            r = c; g = 0; b = x
        }
        
        let m = l - c / 2
        return (r + m, g + m, b + m)
    }
    
    // MARK: - Contour Lines
    
    private func addContourLinesToGrayscale(
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
                
                guard currentBand >= 0 else { continue }
                
                let neighbors = [
                    bandIndices[idx - 1],
                    bandIndices[idx + 1],
                    bandIndices[idx - width],
                    bandIndices[idx + width]
                ]
                
                var isEdge = false
                for neighborBand in neighbors {
                    if neighborBand >= 0 && neighborBand != currentBand {
                        isEdge = true
                        break
                    }
                }
                
                if isEdge {
                    let currentValue = Int(pixels[idx])
                    let addValue = Int(contourValue) / 2
                    pixels[idx] = UInt8(min(255, currentValue + addValue))
                }
            }
        }
    }
    
    private func addContourLinesToColor(
        pixels: inout [UInt8],
        bandIndices: [Int],
        width: Int,
        height: Int
    ) {
        for y in 1..<(height - 1) {
            for x in 1..<(width - 1) {
                let idx = y * width + x
                let currentBand = bandIndices[idx]
                
                guard currentBand >= 0 else { continue }
                
                let neighbors = [
                    bandIndices[idx - 1],
                    bandIndices[idx + 1],
                    bandIndices[idx - width],
                    bandIndices[idx + width]
                ]
                
                var isEdge = false
                for neighborBand in neighbors {
                    if neighborBand >= 0 && neighborBand != currentBand {
                        isEdge = true
                        break
                    }
                }
                
                if isEdge {
                    // White contour line for color mode
                    let pixelIdx = idx * 3
                    pixels[pixelIdx] = 255     // R
                    pixels[pixelIdx + 1] = 255 // G
                    pixels[pixelIdx + 2] = 255 // B
                }
            }
        }
    }
    
    // MARK: - CGImage Creation
    
    private func createGrayscaleCGImage(from pixels: [UInt8], width: Int, height: Int) -> CGImage? {
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
    
    private func createRGBCGImage(from pixels: [UInt8], width: Int, height: Int) -> CGImage? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue)
        
        guard let provider = CGDataProvider(data: Data(pixels) as CFData) else {
            return nil
        }
        
        return CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 24,
            bytesPerRow: width * 3,
            space: colorSpace,
            bitmapInfo: bitmapInfo,
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        )
    }
}
