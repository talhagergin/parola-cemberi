import SwiftUI

struct ModeSelectionView: View {
    let dailyCompleted: Bool
    let onBack: () -> Void
    let onSelect: (GameMode) -> Void

    var body: some View {
        ZStack {
            GameBackground()
            ScrollView {
                VStack(spacing: GameSpacing.md) {
                    ScreenHeader(title: "OYUN MODLARI", onBack: onBack)
                    ForEach(GameMode.allCases) { mode in
                        let available = mode.isAvailable && !(mode == .daily && dailyCompleted)
                        Button { if available { onSelect(mode) } } label: {
                            GlassPanel {
                                HStack(spacing: GameSpacing.md) {
                                    Image(systemName: mode.icon).font(.system(size: 32, weight: .bold))
                                        .foregroundStyle(modeColor(mode)).frame(width: 58, height: 58)
                                        .background(modeColor(mode).opacity(0.14), in: RoundedRectangle(cornerRadius: 16))
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(mode.title).font(.headline.weight(.heavy)).foregroundStyle(.white)
                                        Text(mode.subtitle).font(.subheadline).foregroundStyle(GameColors.textSecondary)
                                    }
                                    Spacer()
                                    if available { Image(systemName: "chevron.right").foregroundStyle(GameColors.cyan) }
                                    else { Text("TAMAMLANDI").font(.caption2.bold()).foregroundStyle(GameColors.success) }
                                }.padding(GameSpacing.md).frame(minHeight: 92)
                            }
                        }.buttonStyle(.plain).opacity(available ? 1 : 0.62)
                    }
                }.padding(GameSpacing.md)
            }
        }.preferredColorScheme(.dark)
    }

    private func modeColor(_ mode: GameMode) -> Color {
        switch mode { case .classic: GameColors.cyan; case .quick: GameColors.orange; case .category: GameColors.purple; case .daily: .yellow }
    }
}

struct ScreenHeader: View {
    let title: String
    let onBack: () -> Void
    var body: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left").font(.headline).frame(width: 44, height: 44)
                    .background(GameColors.panel.opacity(0.8), in: RoundedRectangle(cornerRadius: 14))
            }.accessibilityLabel("Geri")
            Spacer()
            Text(title).font(.system(.title3, design: .rounded, weight: .heavy)).foregroundStyle(.white)
            Spacer()
            Color.clear.frame(width: 44, height: 44)
        }
    }
}
