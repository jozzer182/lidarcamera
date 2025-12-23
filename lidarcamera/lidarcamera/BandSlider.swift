import SwiftUI

/// Vertical Liquid Glass slider for adjusting depth band resolution
struct BandSlider: View {
    @Binding var value: Float
    
    /// Minimum step (fine detail)
    let minStep: Float = 0.01
    /// Maximum step (coarse)
    let maxStep: Float = 0.20
    
    @State private var isDragging = false
    
    private let sliderHeight: CGFloat = 200
    private let trackWidth: CGFloat = 6
    private let thumbSize: CGFloat = 24
    
    var body: some View {
        VStack(spacing: 8) {
            // Fine label
            Text("Fine")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))
            
            // Slider track
            GeometryReader { geometry in
                ZStack(alignment: .bottom) {
                    // Track background (Liquid Glass)
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Capsule()
                                .stroke(.white.opacity(0.3), lineWidth: 1)
                        )
                        .frame(width: trackWidth)
                    
                    // Active fill
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.blue.opacity(0.6), .blue.opacity(0.3)],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .frame(width: trackWidth, height: thumbPosition(in: geometry.size.height))
                    
                    // Thumb
                    Circle()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Circle()
                                .fill(isDragging ? Color.blue.opacity(0.5) : .white.opacity(0.2))
                        )
                        .overlay(
                            Circle()
                                .stroke(isDragging ? Color.blue : .white.opacity(0.5), lineWidth: 2)
                        )
                        .frame(width: thumbSize, height: thumbSize)
                        .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
                        .offset(y: -thumbPosition(in: geometry.size.height) + thumbSize / 2)
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { gesture in
                                    isDragging = true
                                    updateValue(from: gesture.location.y, in: geometry.size.height)
                                }
                                .onEnded { _ in
                                    isDragging = false
                                }
                        )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            }
            .frame(width: thumbSize + 10, height: sliderHeight)
            
            // Coarse label
            Text("Coarse")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))
            
            // Current value display
            Text(String(format: "%.0f cm", value * 100))
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.8))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Capsule()
                                .stroke(.white.opacity(0.2), lineWidth: 1)
                        )
                )
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.25), radius: 10, y: 4)
    }
    
    // MARK: - Helper Methods
    
    private func thumbPosition(in height: CGFloat) -> CGFloat {
        let normalizedValue = (value - minStep) / (maxStep - minStep)
        // Inverted: top = fine (low value), bottom = coarse (high value)
        let invertedValue = 1.0 - normalizedValue
        return CGFloat(invertedValue) * (height - thumbSize) + thumbSize / 2
    }
    
    private func updateValue(from y: CGFloat, in height: CGFloat) {
        let usableHeight = height - thumbSize
        let clampedY = max(thumbSize / 2, min(y, height - thumbSize / 2))
        let normalizedY = (clampedY - thumbSize / 2) / usableHeight
        // Inverted mapping
        let invertedValue = 1.0 - normalizedY
        value = minStep + Float(invertedValue) * (maxStep - minStep)
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.5)
        BandSlider(value: .constant(0.05))
    }
}
