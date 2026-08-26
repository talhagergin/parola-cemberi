import SwiftUI

struct StatisticsView: View {
    let snapshot: StatisticsSnapshot
    let onBack: () -> Void
    @State private var detail: StatisticsDetail = .letters

    var body: some View {
        ZStack {
            GameBackground()
            ScrollView {
                VStack(spacing: GameSpacing.md) {
                    ScreenHeader(title: "İSTATİSTİKLER", onBack: onBack)
                    Text("Tüm oyun geçmişin").font(.subheadline).foregroundStyle(GameColors.textSecondary)

                    LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: GameSpacing.sm) {
                        StatisticTile(icon: "gamecontroller.fill", value: snapshot.totalGames.formatted(), label: "Toplam oyun", color: GameColors.purple)
                        StatisticTile(icon: "trophy.fill", value: snapshot.highScore.formatted(), label: "En yüksek skor", color: .yellow)
                        StatisticTile(icon: "checkmark.circle.fill", value: snapshot.totalCorrect.formatted(), label: "Toplam doğru", color: GameColors.success)
                        StatisticTile(icon: "scope", value: "%\(snapshot.accuracy)", label: "Doğruluk", color: GameColors.cyan)
                        StatisticTile(icon: "flame.fill", value: snapshot.longestStreak.formatted(), label: "En uzun seri", color: GameColors.orange)
                        StatisticTile(icon: "calendar.badge.checkmark", value: snapshot.dailyStreak.formatted(), label: "Günlük seri", color: GameColors.cyan)
                    }

                    if snapshot.totalGames == 0 {
                        GlassPanel {
                            ContentUnavailableView("Henüz istatistik yok", systemImage: "chart.bar", description: Text("İlk turunu tamamladığında gelişimin burada görünecek."))
                                .foregroundStyle(.white).padding()
                        }
                    } else {
                        categoryHighlights
                        Picker("İstatistik detayı", selection: $detail) {
                            ForEach(StatisticsDetail.allCases) { Text($0.title).tag($0) }
                        }.pickerStyle(.segmented)

                        VStack(spacing: GameSpacing.sm) {
                            ForEach(detail == .letters ? snapshot.letters : snapshot.categories) { PerformanceRow(item: $0) }
                        }
                    }
                }.padding(GameSpacing.md)
            }
        }
        .preferredColorScheme(.dark)
        .accessibilityElement(children: .contain)
    }

    private var categoryHighlights: some View {
        HStack(spacing: GameSpacing.sm) {
            CategoryHighlight(title: "En başarılı", value: snapshot.bestCategory?.title ?? "—", color: GameColors.success)
            CategoryHighlight(title: "En zor", value: snapshot.hardestCategory?.title ?? "—", color: GameColors.danger)
        }
    }
}

private enum StatisticsDetail: String, CaseIterable, Identifiable {
    case letters, categories
    var id: String { rawValue }
    var title: String { self == .letters ? "Harfler" : "Kategoriler" }
}

private struct StatisticTile: View {
    let icon: String, value: String, label: String
    let color: Color
    var body: some View {
        GlassPanel {
            VStack(spacing: 6) {
                Image(systemName: icon).foregroundStyle(color)
                Text(value).font(.title2.bold()).foregroundStyle(.white).minimumScaleFactor(0.7)
                Text(label).font(.caption).foregroundStyle(GameColors.textSecondary)
            }.padding(12).frame(maxWidth: .infinity, minHeight: 94)
        }.accessibilityElement(children: .ignore).accessibilityLabel("\(label), \(value)")
    }
}

private struct CategoryHighlight: View {
    let title, value: String
    let color: Color
    var body: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 5) {
                Text(title.uppercased()).font(.caption2.bold()).foregroundStyle(color)
                Text(value).font(.subheadline.bold()).foregroundStyle(.white).lineLimit(1)
            }.padding(12).frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct PerformanceRow: View {
    let item: PerformanceItem
    var body: some View {
        GlassPanel {
            HStack(spacing: 12) {
                Text(item.title).font(.headline.bold()).foregroundStyle(.white).frame(minWidth: 36, alignment: .leading)
                ProgressView(value: Double(item.accuracy), total: 100).tint(item.accuracy >= 60 ? GameColors.success : GameColors.orange)
                Text("%\(item.accuracy)").font(.subheadline.monospacedDigit().bold()).foregroundStyle(GameColors.cyan).frame(width: 46)
                Text("\(item.attempts)").font(.caption).foregroundStyle(GameColors.textSecondary).frame(width: 25)
            }.padding(12)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(item.title), yüzde \(item.accuracy) başarı, \(item.attempts) deneme")
    }
}
