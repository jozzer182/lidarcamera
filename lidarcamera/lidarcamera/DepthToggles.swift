import SwiftUI

/// Toggle controls for LiDAR depth visualization (top of screen)
struct DepthToggles: View {
    @Binding var useColorMode: Bool
    @Binding var showContours: Bool
    
    var body: some View {
        GlassEffectContainer {
            HStack(spacing: 12) {
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
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .glassEffect(.regular, in: .capsule)
    }
}

/// Individual toggle pill button with Liquid Glass
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
            .foregroundStyle(isOn ? Color.accentColor : Color.white.opacity(0.7))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
        .glassEffect(isOn ? .regular.tint(.accentColor) : .clear, in: .capsule)
    }
}

#Preview {
    ZStack {
        Color.black
        DepthToggles(useColorMode: .constant(false), showContours: .constant(false))
    }
}
