import SwiftUI

/// Vertical Liquid Glass slider for adjusting depth band resolution
struct BandSlider: View {
    @Binding var value: Float
    
    /// Minimum step (fine detail) - at TOP
    let minStep: Float = 0.01
    /// Maximum step (coarse) - at BOTTOM
    let maxStep: Float = 0.20
    
    @State private var isDragging = false
    @GestureState private var dragOffset: CGFloat = 0
    
    private let sliderHeight: CGFloat = 200
    private let trackWidth: CGFloat = 8
    private let thumbSize: CGFloat = 28
    
    var body: some View {
        VStack(spacing: 8) {
            // Fine label (TOP = smaller values)
            Text("Fine")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))
            
            // Slider track
            ZStack(alignment: .top) {
                // Track background (Liquid Glass)
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Capsule()
                            .stroke(.white.opacity(0.3), lineWidth: 1)
                    )
                    .frame(width: trackWidth, height: sliderHeight)
                
                // Active fill from top
                VStack {
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.blue.opacity(0.6), .blue.opacity(0.3)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: trackWidth, height: currentThumbY + thumbSize / 2)
                    Spacer()
                }
                .frame(height: sliderHeight)
                
                // Thumb
                Circle()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Circle()
                            .fill(isDragging ? Color.blue.opacity(0.5) : .white.opacity(0.3))
                    )
                    .overlay(
                        Circle()
                            .stroke(isDragging ? Color.blue : .white.opacity(0.6), lineWidth: 2)
                    )
                    .frame(width: thumbSize, height: thumbSize)
                    .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
                    .offset(y: currentThumbY)
            }
            .frame(width: thumbSize + 10, height: sliderHeight)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        isDragging = true
                        let y = gesture.location.y
                        updateValueFromY(y)
                    }
                    .onEnded { _ in
                        isDragging = false
                    }
            )
            
            // Coarse label (BOTTOM = larger values)
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
    
    // MARK: - Computed Properties
    
    /// Calculate thumb Y position from current value
    /// TOP (y=0) = minStep (fine), BOTTOM (y=max) = maxStep (coarse)
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
        
        // TOP = fine (minStep), BOTTOM = coarse (maxStep)
        value = minStep + Float(normalizedY) * (maxStep - minStep)
        
        // Clamp value to range
        value = max(minStep, min(value, maxStep))
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.5)
        BandSlider(value: .constant(0.05))
    }
}
