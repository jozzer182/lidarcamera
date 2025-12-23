import SwiftUI

/// Vertical Liquid Glass slider for adjusting depth band resolution
struct BandSlider: View {
    @Binding var value: Float
    
    /// Minimum step (fine detail) - at TOP
    let minStep: Float = 0.01
    /// Maximum step (coarse) - at BOTTOM
    let maxStep: Float = 0.20
    
    @State private var isDragging = false
    
    private let sliderHeight: CGFloat = 200
    private let trackWidth: CGFloat = 8
    private let thumbSize: CGFloat = 28
    
    var body: some View {
        GlassEffectContainer {
            VStack(spacing: 8) {
                // Fine label (TOP = smaller values)
                Text("Fine")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
                
                // Slider track
                ZStack(alignment: .top) {
                    // Track background
                    Capsule()
                        .fill(.quaternary)
                        .frame(width: trackWidth, height: sliderHeight)
                    
                    // Active fill from top
                    VStack {
                        Capsule()
                            .fill(.tint)
                            .frame(width: trackWidth, height: currentThumbY + thumbSize / 2)
                        Spacer()
                    }
                    .frame(height: sliderHeight)
                    
                    // Thumb with Liquid Glass
                    Circle()
                        .fill(isDragging ? Color.accentColor.opacity(0.3) : .clear)
                        .frame(width: thumbSize, height: thumbSize)
                        .glassEffect(.regular, in: .circle)
                        .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                        .offset(y: currentThumbY)
                }
                .frame(width: thumbSize + 10, height: sliderHeight)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { gesture in
                            isDragging = true
                            updateValueFromY(gesture.location.y)
                        }
                        .onEnded { _ in
                            isDragging = false
                        }
                )
                
                // Coarse label (BOTTOM = larger values)
                Text("Coarse")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
                
                // Current value display with Liquid Glass
                Text(String(format: "%.0f cm", value * 100))
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .glassEffect(.regular, in: .capsule)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
        }
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
    }
    
    // MARK: - Computed Properties
    
    /// Calculate thumb Y position from current value
    private var currentThumbY: CGFloat {
        let normalizedValue = CGFloat((value - minStep) / (maxStep - minStep))
        let usableHeight = sliderHeight - thumbSize
        return normalizedValue * usableHeight
    }
    
    // MARK: - Methods
    
    /// Update value from Y position in gesture
    private func updateValueFromY(_ y: CGFloat) {
        let usableHeight = sliderHeight - thumbSize
        let clampedY = max(0, min(y - thumbSize / 2, usableHeight))
        let normalizedY = clampedY / usableHeight
        
        value = minStep + Float(normalizedY) * (maxStep - minStep)
        value = max(minStep, min(value, maxStep))
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.5)
        BandSlider(value: .constant(0.05))
    }
}
