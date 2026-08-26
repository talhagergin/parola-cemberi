import SwiftUI

struct CategorySelectionView: View {
    let categories: [String: Int]
    let onBack: () -> Void
    let onSelect: (String?) -> Void
    @State private var search = ""

    private var filtered: [(String, Int)] {
        categories.sorted { $0.key.localizedStandardCompare($1.key) == .orderedAscending }
            .filter { search.isEmpty || $0.key.localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        ZStack {
            GameBackground()
            VStack(spacing: GameSpacing.md) {
                ScreenHeader(title: "KATEGORİ SEÇ", onBack: onBack)
                HStack {
                    Image(systemName: "magnifyingglass").foregroundStyle(GameColors.cyan)
                    TextField("Kategori ara", text: $search).foregroundStyle(.white)
                }.padding().background(GameColors.panel.opacity(0.8), in: RoundedRectangle(cornerRadius: 18))

                ScrollView {
                    LazyVStack(spacing: GameSpacing.sm) {
                        CategoryRow(name: "Tüm Kategoriler", count: categories.values.reduce(0, +), icon: "sparkles") { onSelect(nil) }
                        ForEach(filtered, id: \.0) { name, count in
                            CategoryRow(name: name, count: count, icon: icon(for: name)) { onSelect(name) }
                        }
                    }.padding(.bottom, GameSpacing.lg)
                }
            }.padding(GameSpacing.md)
        }.preferredColorScheme(.dark)
    }

    private func icon(for category: String) -> String {
        if category.contains("Bilim") || category.contains("Teknoloji") { return "atom" }
        if category.contains("Hayvan") { return "pawprint.fill" }
        if category.contains("Bitki") { return "leaf.fill" }
        if category.contains("Spor") { return "figure.run" }
        if category.contains("Müzik") { return "music.note" }
        if category.contains("Yiyecek") { return "fork.knife" }
        if category.contains("Coğrafya") || category.contains("Deniz") { return "globe.europe.africa.fill" }
        return "books.vertical.fill"
    }
}

private struct CategoryRow: View {
    let name: String, count: Int, icon: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            GlassPanel {
                HStack(spacing: GameSpacing.md) {
                    Image(systemName: icon).font(.title3).foregroundStyle(GameColors.cyan).frame(width: 34)
                    VStack(alignment: .leading) {
                        Text(name).font(.subheadline.bold()).foregroundStyle(.white)
                        Text("\(count) soru").font(.caption).foregroundStyle(GameColors.textSecondary)
                    }
                    Spacer()
                    if count < 29 { Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(GameColors.orange) }
                    Image(systemName: "chevron.right").foregroundStyle(GameColors.purple)
                }.padding(GameSpacing.md)
            }
        }.buttonStyle(.plain)
    }
}
