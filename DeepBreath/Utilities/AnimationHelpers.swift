import SwiftUI

// MARK: - Press Button Style

struct PressButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.95

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .brightness(configuration.isPressed ? -0.04 : 0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Staggered Entrance Modifier

struct StaggeredAppearModifier: ViewModifier {
    let delay: Double
    let yOffset: CGFloat
    @State private var appeared = false

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : yOffset)
            .onAppear {
                withAnimation(.spring(response: 0.55, dampingFraction: 0.82).delay(delay)) {
                    appeared = true
                }
            }
    }
}

extension View {
    func staggeredAppear(delay: Double = 0, yOffset: CGFloat = 22) -> some View {
        modifier(StaggeredAppearModifier(delay: delay, yOffset: yOffset))
    }
}

// MARK: - Glow Modifier

struct GlowModifier: ViewModifier {
    let color: Color
    let radius: CGFloat

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.5), radius: radius / 2)
            .shadow(color: color.opacity(0.3), radius: radius)
    }
}

extension View {
    func glow(color: Color, radius: CGFloat = 12) -> some View {
        modifier(GlowModifier(color: color, radius: radius))
    }
}
