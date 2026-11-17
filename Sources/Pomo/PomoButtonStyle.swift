import SwiftUI

/// Shared geometry and interaction feedback for window and menu-bar controls.
struct PomoButtonStyle: ButtonStyle {
    enum Emphasis { case primary, secondary, quiet }
    var accent: Color
    var emphasis: Emphasis = .secondary

    func makeBody(configuration: Configuration) -> some View {
        Surface(configuration: configuration, accent: accent, emphasis: emphasis)
    }

    private struct Surface: View {
        let configuration: ButtonStyleConfiguration
        let accent: Color
        let emphasis: Emphasis
        @Environment(\.isEnabled) private var enabled
        @Environment(\.isFocused) private var focused
        @State private var hovering = false

        var body: some View {
            configuration.label
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.primary)
                .padding(.horizontal, 14).frame(minHeight: 40)
                .background(fill, in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(focused ? accent : accent.opacity(emphasis == .quiet ? 0 : 0.35), lineWidth: focused ? 2 : 1))
                .opacity(enabled ? 1 : 0.38)
                .contentShape(RoundedRectangle(cornerRadius: 12))
                .onHover { hovering = $0 }
        }
        private var fill: Color {
            let base = emphasis == .primary ? 0.32 : emphasis == .secondary ? 0.10 : 0.0
            return accent.opacity(base + (enabled && (hovering || configuration.isPressed) ? 0.12 : 0))
        }
    }
}
