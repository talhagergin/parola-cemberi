import SwiftUI

struct GameQuestionCard: View {
    let letterState: LetterState
    var textScale: Double = 1

    var body: some View {
        if let question = letterState.question {
            GlassPanel {
                VStack(alignment: .leading, spacing: GameSpacing.sm) {
                    HStack {
                        Text("\(letterState.letter.rawValue) HARFİ")
                            .font(.caption.weight(.heavy)).tracking(1.1).foregroundStyle(GameColors.cyan)
                        Spacer()
                        Label(question.category, systemImage: "globe.europe.africa.fill")
                            .font(.caption2.weight(.semibold)).foregroundStyle(GameColors.textSecondary)
                        Text(String(repeating: "◆", count: min(3, max(1, question.difficulty))))
                            .font(.system(size: 7)).foregroundStyle(GameColors.orange)
                    }
                    Text(question.clue)
                        .font(.system(size: 17 * textScale, weight: .bold, design: .rounded))
                        .foregroundStyle(.white).fixedSize(horizontal: false, vertical: true)
                    if letterState.hintUsed, let extended = question.extendedClue {
                        Text(extended)
                            .font(.system(size: 15 * textScale)).foregroundStyle(GameColors.cyan.opacity(0.90))
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    HStack {
                        Text("\(question.letterCount) harf")
                            .font(.caption).foregroundStyle(GameColors.textSecondary)
                        if letterState.hintUsed {
                            Spacer()
                            Label("İpucu açık", systemImage: "lightbulb.fill")
                                .font(.caption.bold()).foregroundStyle(GameColors.success)
                        }
                    }
                }.padding(GameSpacing.md)
            }
            .id(question.id)
            .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)))
        }
    }
}
