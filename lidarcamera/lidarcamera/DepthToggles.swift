import SwiftUI

/// Toggle controls for LiDAR depth visualization (top of screen)
struct DepthToggles: View {
    @Binding var useColorMode: Bool
    @Binding var showContours: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Color mode toggle
            TogglePill(
                isOn: $useColorMode,
                icon: useColorMode ? "paintpalette.fill" : "circle.lefthalf.filled",
                label: useColorMode ? "Color" : "B/W"
            )
            
            // Contour toggle
            TogglePill(
                isOn: $showContours,
                icon: showContours ? "square.stack.3d.up.fill" : "square.stack.3d.up",
                label: "Contours"
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
    }
}

/// Individual toggle pill button
struct TogglePill: View {
    @Binding var isOn: Bool
    let icon: String
    let label: String
    
    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isOn.toggle()
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                
                Text(label)
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundStyle(isOn ? .blue : .white.opacity(0.7))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isOn ? Color.blue.opacity(0.2) : .clear)
                    .overlay(
                        Capsule()
                            .stroke(isOn ? Color.blue.opacity(0.5) : .white.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ZStack {
        Color.black
        DepthToggles(useColorMode: .constant(false), showContours: .constant(false))
    }
}
