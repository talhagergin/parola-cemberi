import SwiftUI

struct ResultsView: View {
    let session: GameSession
    let mode: GameMode
    let earnedCoins: Int
    let onReplay: () -> Void
    let onMenu: () -> Void
    @State private var inspectAnswers = false

    private var correct: Int { session.letters.filter { $0.status == .correct }.count }
    private var wrong: Int { session.letters.filter { $0.status == .wrong }.count }
    private var passed: Int { session.letters.filter { $0.status == .passed }.count }
    private var accuracy: Int {
        let answered = correct + wrong
        return answered == 0 ? 0 : Int((Double(correct) / Double(answered) * 100).rounded())
    }
    private var reviewItems: [LetterState] { session.letters.filter { $0.status == .wrong || $0.status == .passed } }

    var body: some View {
        ZStack {
            GameBackground()
            ScrollView {
                VStack(spacing: GameSpacing.lg) {
                    Image(systemName: session.endReason == .completed ? "trophy.fill" : "hourglass.bottomhalf.filled")
                        .font(.system(size: 58)).foregroundStyle(.yellow).shadow(color: .orange, radius: 18)
                    Text("TUR TAMAMLANDI").font(.system(.title2, design: .rounded, weight: .heavy)).foregroundStyle(.white)
                    Text(mode.title).font(.subheadline.bold()).foregroundStyle(GameColors.cyan)
                    Label("+\(earnedCoins) JETON", systemImage: "seal.fill").font(.headline.bold()).foregroundStyle(.yellow)

                    GlassPanel {
                        VStack(spacing: 4) {
                            Text(session.score.formatted()).font(.system(size: 54, weight: .heavy, design: .rounded)).foregroundStyle(.white)
                                .contentTransition(.numericText())
                            Text("TOPLAM PUAN").font(.caption.bold()).tracking(1.6).foregroundStyle(GameColors.cyan)
                        }.padding(GameSpacing.lg).frame(maxWidth: .infinity)
                    }

                    LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: GameSpacing.sm) {
                        ResultStat(icon: "checkmark.circle.fill", value: "\(correct)", label: "Doğru", color: GameColors.success)
                        ResultStat(icon: "xmark.circle.fill", value: "\(wrong)", label: "Yanlış", color: GameColors.danger)
                        ResultStat(icon: "arrow.right.circle.fill", value: "\(passed)", label: "Pas", color: GameColors.purple)
                        ResultStat(icon: "scope", value: "%\(accuracy)", label: "Doğruluk", color: GameColors.cyan)
                        ResultStat(icon: "flame.fill", value: "\(session.longestStreak)", label: "En uzun seri", color: GameColors.orange)
                        ResultStat(icon: "lightbulb.fill", value: "\(session.hintsUsed)", label: "İpucu", color: .yellow)
                    }

                    if !reviewItems.isEmpty {
                        Button(inspectAnswers ? "İNCELEMEYİ KAPAT" : "CEVAPLARI İNCELE") { withAnimation { inspectAnswers.toggle() } }
                            .buttonStyle(GameButtonStyle(kind: .compact))
                        if inspectAnswers {
                            VStack(spacing: GameSpacing.sm) {
                                ForEach(reviewItems) { item in ReviewAnswerRow(item: item) }
                            }.transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }

                }.padding(GameSpacing.md)
                    .padding(.bottom, 88)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            HStack(spacing: GameSpacing.sm) {
                Button("ANA MENÜ", action: onMenu).buttonStyle(GameButtonStyle(kind: .compact))
                Button("TEKRAR OYNA", action: onReplay).buttonStyle(GameButtonStyle(kind: .primary))
            }
            .padding(.horizontal, GameSpacing.md)
            .padding(.top, 10)
            .padding(.bottom, 6)
            .background(.ultraThinMaterial)
            .overlay(alignment: .top) { Rectangle().fill(GameColors.cyan.opacity(0.22)).frame(height: 1) }
        }
        .preferredColorScheme(.dark)
    }

}

private struct ResultStat: View {
    let icon: String, value: String, label: String, color: Color
    var body: some View {
        GlassPanel {
            VStack(spacing: 6) {
                Image(systemName: icon).foregroundStyle(color)
                Text(value).font(.title2.bold()).foregroundStyle(.white)
                Text(label).font(.caption).foregroundStyle(GameColors.textSecondary)
            }.padding(12).frame(maxWidth: .infinity, minHeight: 92)
        }
    }
}

private struct ReviewAnswerRow: View {
    let item: LetterState
    var body: some View {
        GlassPanel {
            HStack(alignment: .top, spacing: GameSpacing.md) {
                Text(item.letter.rawValue).font(.title2.bold()).foregroundStyle(item.status == .wrong ? GameColors.danger : GameColors.purple)
                    .frame(width: 38, height: 38).background(GameColors.background, in: RoundedRectangle(cornerRadius: 10))
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.question?.clue ?? "Soru yok").font(.caption).foregroundStyle(GameColors.textSecondary).lineLimit(2)
                    Text("Doğru cevap: \(item.question?.answer ?? "—")").font(.subheadline.bold()).foregroundStyle(.white)
                    if let submitted = item.submittedAnswer { Text("Cevabın: \(submitted)").font(.caption).foregroundStyle(GameColors.danger) }
                }
                Spacer()
            }.padding(GameSpacing.md)
        }
    }
}
