import SwiftUI

enum GameColors {
    static let background = Color(red: 0.015, green: 0.025, blue: 0.16)
    static let panel = Color(red: 0.08, green: 0.10, blue: 0.30)
    static let cyan = Color(red: 0.08, green: 0.90, blue: 0.94)
    static let purple = Color(red: 0.42, green: 0.20, blue: 0.93)
    static let orange = Color(red: 1.00, green: 0.47, blue: 0.08)
    static let success = Color(red: 0.31, green: 0.82, blue: 0.25)
    static let danger = Color(red: 1.00, green: 0.22, blue: 0.31)
    static let muted = Color(red: 0.22, green: 0.25, blue: 0.44)
    static let textSecondary = Color.white.opacity(0.68)
    static let glassBorder = Color.white.opacity(0.18)
}

enum GameSpacing { static let xs: CGFloat = 4, sm: CGFloat = 8, md: CGFloat = 16, lg: CGFloat = 24, xl: CGFloat = 32 }
enum GameCornerRadius { static let button: CGFloat = 18, card: CGFloat = 24, panel: CGFloat = 30 }
enum GameShadow { static let glow: CGFloat = 12, elevated: CGFloat = 20 }

extension LinearGradient {
    static let primaryGameButton = LinearGradient(
        colors: [Color(red: 1, green: 0.68, blue: 0.12), GameColors.orange, Color(red: 0.95, green: 0.20, blue: 0.04)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    static let secondaryGameButton = LinearGradient(
        colors: [Color(red: 0.66, green: 0.25, blue: 0.95), GameColors.purple],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
}

struct GameBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [GameColors.background, Color(red: 0.04, green: 0.02, blue: 0.26)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            Circle().fill(GameColors.purple.opacity(0.22)).blur(radius: 70).offset(x: -150, y: 260)
            Circle().fill(GameColors.cyan.opacity(0.15)).blur(radius: 80).offset(x: 170, y: -280)
            Canvas { context, size in
                for index in 0..<26 {
                    let x = CGFloat((index * 71) % 101) / 101 * size.width
                    let y = CGFloat((index * 43) % 97) / 97 * size.height
                    let radius = CGFloat(index % 3 + 1)
                    context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: radius, height: radius)),
                                 with: .color(index.isMultiple(of: 3) ? GameColors.cyan.opacity(0.45) : .white.opacity(0.20)))
                }
            }
        }.ignoresSafeArea()
    }
}
