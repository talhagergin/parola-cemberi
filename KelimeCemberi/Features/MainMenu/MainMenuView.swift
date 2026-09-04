import SwiftUI

struct MainMenuView: View {
    let questionCount: Int
    let dailyCompleted: Bool
    let avatar: PlayerAvatar
    let coinBalance: Int
    let onPlay: () -> Void
    let onQuickPlay: () -> Void
    let onDailyPlay: () -> Void
    let onStatistics: () -> Void
    let onSettings: () -> Void
    let onAvatar: () -> Void
    let onStore: () -> Void
    let onLanguageLearning: () -> Void

    var body: some View {
        ZStack {
            GameBackground()
            ScrollView {
                VStack(spacing: GameSpacing.lg) {
                    HStack {
                        VStack(alignment: .leading, spacing: -3) {
                            Text("PAROLA").foregroundStyle(.white)
                            Text("ÇEMBERİ").foregroundStyle(GameColors.cyan)
                        }.font(.system(size: 32, weight: .heavy, design: .rounded))
                        Spacer()
                        Button(action: onAvatar) {
                            Image(avatar.assetName).resizable().scaledToFill().frame(width: 54, height: 54).clipShape(Circle())
                                .overlay { Circle().stroke(GameColors.cyan, lineWidth: 2) }.shadow(color: GameColors.cyan.opacity(0.6), radius: 8)
                        }.accessibilityLabel("Avatarı değiştir")
                    }
                    HStack {
                        Label(coinBalance.formatted(), systemImage: "seal.fill").font(.headline).foregroundStyle(.yellow)
                        Spacer()
                        Button("MAĞAZA", action: onStore).font(.caption.bold()).foregroundStyle(GameColors.cyan)
                    }.padding(.horizontal, 14).padding(.vertical, 10).background(GameColors.panel.opacity(0.85), in: Capsule())

                    MenuMiniCard(icon: "character.book.closed.fill", title: "Dil Öğren", color: GameColors.success, badge: "4 Dil • A1–C2", action: onLanguageLearning)

                    GlassPanel {
                        VStack(spacing: GameSpacing.md) {
                            ZStack {
                                Circle().stroke(GameColors.purple.opacity(0.5), lineWidth: 15)
                                Circle().trim(from: 0, to: 0.76).stroke(GameColors.cyan, style: .init(lineWidth: 7, lineCap: .round))
                                    .rotationEffect(.degrees(-90)).shadow(color: GameColors.cyan, radius: 12)
                                Image(systemName: "play.fill").font(.system(size: 46)).foregroundStyle(.white)
                            }.frame(width: 150, height: 150)
                            Text("ÇEMBER SENİ BEKLİYOR").font(.headline.weight(.heavy)).foregroundStyle(.white)
                            Text("\(questionCount.formatted()) özgün sorudan yeni bir tur")
                                .font(.subheadline).foregroundStyle(GameColors.textSecondary)
                            Button("OYUNA BAŞLA", action: onPlay).buttonStyle(GameButtonStyle(kind: .primary))
                        }.padding(GameSpacing.lg)
                    }

                    HStack(spacing: GameSpacing.md) {
                        MenuMiniCard(icon: "bolt.fill", title: "Hızlı Tur", color: GameColors.orange, action: onQuickPlay)
                        MenuMiniCard(icon: dailyCompleted ? "checkmark.seal.fill" : "calendar", title: "Günlük", color: GameColors.cyan, badge: dailyCompleted ? "Tamamlandı" : nil, action: onDailyPlay)
                    }
                    HStack(spacing: GameSpacing.md) {
                        MenuMiniCard(icon: "chart.bar.fill", title: "İstatistik", color: GameColors.success, action: onStatistics)
                        MenuMiniCard(icon: "trophy.fill", title: "Başarımlar", color: .yellow, badge: "Yakında", action: {})
                    }
                    MenuMiniCard(icon: "gearshape.fill", title: "Ayarlar", color: GameColors.textSecondary, action: onSettings)
                    MenuMiniCard(icon: "bag.fill", title: "Avatar ve Tema Mağazası", color: GameColors.cyan, badge: "Jeton", action: onStore)
                    AdBannerSlot()
                }.padding(GameSpacing.md)
            }
        }.preferredColorScheme(.dark)
    }
}

private struct MenuMiniCard: View {
    let icon: String, title: String, color: Color
    var badge: String? = nil
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            GlassPanel {
                HStack(spacing: 12) {
                    Image(systemName: icon).font(.title2).foregroundStyle(color)
                    Text(title).font(.subheadline.bold()).foregroundStyle(.white).lineLimit(1).minimumScaleFactor(0.72)
                    Spacer(minLength: 0)
                    if let badge { Text(badge).font(.system(size: 9, weight: .bold)).foregroundStyle(GameColors.textSecondary) }
                }.padding(14).frame(maxWidth: .infinity, minHeight: 66)
            }
        }.buttonStyle(.plain)
    }
}
