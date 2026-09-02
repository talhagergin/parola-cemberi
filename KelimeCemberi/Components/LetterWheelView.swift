import SwiftUI

struct LetterWheelView: View {
    let letters: [LetterState]
    let remainingSeconds: Int
    let totalSeconds: Int
    let score: Int
    let streak: Int
    let theme: CircleTheme

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulse = false

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            let tileSize = min(34.0, max(25.0, side * 0.078))
            let radius = side * 0.425
            let center = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)

            ZStack {
                Circle()
                    .stroke(theme.secondary.opacity(0.35), lineWidth: 2)
                    .frame(width: side * 0.72, height: side * 0.72)
                Circle()
                    .stroke(style: StrokeStyle(lineWidth: 6, lineCap: .round, dash: [1, 11]))
                    .foregroundStyle(theme.primary.opacity(0.28))
                    .frame(width: side * 0.64, height: side * 0.64)

                ForEach(Array(letters.enumerated()), id: \.element.id) { index, state in
                    let angle = Angle.degrees(-90 + (360 / Double(letters.count)) * Double(index))
                    LetterTile(state: state, size: tileSize, pulse: pulse && state.status == .active, theme: theme)
                        .position(
                            x: center.x + radius * cos(angle.radians),
                            y: center.y + radius * sin(angle.radians)
                        )
                }

                TimerScoreCenter(
                    remainingSeconds: remainingSeconds,
                    totalSeconds: totalSeconds,
                    score: score,
                    streak: streak,
                    theme: theme
                )
                .frame(width: side * 0.52, height: side * 0.52)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 0.85).repeatForever(autoreverses: true)) { pulse = true }
        }
    }
}

private struct LetterTile: View {
    let state: LetterState
    let size: CGFloat
    let pulse: Bool
    let theme: CircleTheme

    var body: some View {
        Text(state.letter.rawValue)
            .font(.system(size: size * 0.54, weight: .heavy, design: .rounded))
            .foregroundStyle(.white.opacity(state.status == .unavailable ? 0.46 : 1))
            .frame(width: size, height: size * 1.12)
            .background(fill, in: RoundedRectangle(cornerRadius: size * 0.25, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: size * 0.25, style: .continuous)
                    .stroke(border, lineWidth: state.status == .active ? 2.5 : 1)
            }
            .shadow(color: glow, radius: state.status == .active ? (pulse ? 13 : 7) : 3)
            .scaleEffect(state.status == .active ? (pulse ? 1.13 : 1.07) : 1)
            .rotationEffect(.degrees(state.status == .wrong ? -2 : 0))
            .animation(.spring(response: 0.32, dampingFraction: 0.68), value: state.status)
            .accessibilityLabel("\(state.letter.rawValue) harfi, \(state.status.accessibilityDescription).")
    }

    private var fill: LinearGradient {
        let colors: [Color] = switch state.status {
        case .waiting: [theme.primary.opacity(0.88), theme.secondary.opacity(0.72)]
        case .active: [Color.yellow, GameColors.orange]
        case .correct: [Color(red: 0.42, green: 0.91, blue: 0.25), Color(red: 0.08, green: 0.48, blue: 0.15)]
        case .wrong: [Color(red: 1, green: 0.34, blue: 0.40), Color(red: 0.60, green: 0.05, blue: 0.13)]
        case .passed: [GameColors.muted, Color(red: 0.07, green: 0.08, blue: 0.20)]
        case .skipped: [GameColors.purple, Color(red: 0.07, green: 0.08, blue: 0.20)]
        case .unavailable: [GameColors.muted.opacity(0.5), GameColors.background]
        }
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private var border: Color { state.status == .active ? .white : .white.opacity(0.22) }
    private var glow: Color {
        switch state.status {
        case .active: GameColors.orange
        case .correct: GameColors.success.opacity(0.65)
        case .wrong: GameColors.danger.opacity(0.6)
        default: .black.opacity(0.25)
        }
    }
}

private struct TimerScoreCenter: View {
    let remainingSeconds: Int
    let totalSeconds: Int
    let score: Int
    let streak: Int
    let theme: CircleTheme

    private var progress: Double { Double(remainingSeconds) / Double(max(1, totalSeconds)) }
    private var timerColor: Color {
        if remainingSeconds <= 10 { return GameColors.danger }
        if remainingSeconds <= 30 { return GameColors.orange }
        return theme.primary
    }

    var body: some View {
        ZStack {
            Circle().fill(GameColors.background.opacity(0.92))
            Circle().stroke(theme.secondary.opacity(0.55), lineWidth: 4)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(timerColor, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .shadow(color: timerColor.opacity(0.8), radius: 8)
                .animation(.linear(duration: 0.35), value: remainingSeconds)

            VStack(spacing: 5) {
                Image(systemName: "clock.fill").foregroundStyle(timerColor)
                Text(remainingSeconds.gameClockText)
                    .font(.system(size: 31, weight: .heavy, design: .rounded))
                    .monospacedDigit().minimumScaleFactor(0.7)
                Rectangle().fill(.white.opacity(0.22)).frame(width: 74, height: 1)
                Text("PUAN").font(.caption2.weight(.bold)).tracking(1.4).foregroundStyle(theme.primary)
                Text(score.formatted()).font(.system(size: 23, weight: .heavy, design: .rounded)).contentTransition(.numericText())
                if streak > 1 {
                    Label("\(streak) SERİ", systemImage: "flame.fill")
                        .font(.caption2.bold()).foregroundStyle(GameColors.orange)
                }
            }.foregroundStyle(.white)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Kalan süre \(remainingSeconds.gameClockText), puan \(score), seri \(streak)")
    }
}
