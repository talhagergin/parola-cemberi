import SwiftUI

struct GlassPanel<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) { self.content = content() }

    var body: some View {
        content
            .background(.ultraThinMaterial.opacity(0.72), in: RoundedRectangle(cornerRadius: GameCornerRadius.card, style: .continuous))
            .background(GameColors.panel.opacity(0.66), in: RoundedRectangle(cornerRadius: GameCornerRadius.card, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: GameCornerRadius.card, style: .continuous)
                    .stroke(LinearGradient(colors: [GameColors.glassBorder, GameColors.cyan.opacity(0.20), .clear],
                                           startPoint: .topLeading, endPoint: .bottomTrailing))
            }
            .shadow(color: .black.opacity(0.35), radius: GameShadow.elevated, y: 10)
    }
}

struct GameButtonStyle: ButtonStyle {
    enum Kind { case primary, secondary, compact }
    let kind: Kind

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.headline, design: .rounded, weight: .heavy))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: kind == .compact ? 46 : 56)
            .background(background.opacity(configuration.isPressed ? 0.78 : 1), in: RoundedRectangle(cornerRadius: GameCornerRadius.button, style: .continuous))
            .overlay { RoundedRectangle(cornerRadius: GameCornerRadius.button).stroke(.white.opacity(0.22)) }
            .shadow(color: glow.opacity(configuration.isPressed ? 0.18 : 0.45), radius: configuration.isPressed ? 4 : 10, y: 4)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.22, dampingFraction: 0.70), value: configuration.isPressed)
    }

    private var background: LinearGradient {
        switch kind {
        case .primary: .primaryGameButton
        case .secondary: .secondaryGameButton
        case .compact: LinearGradient(colors: [GameColors.panel, GameColors.purple.opacity(0.8)], startPoint: .top, endPoint: .bottom)
        }
    }

    private var glow: Color { kind == .primary ? GameColors.orange : GameColors.purple }
}
