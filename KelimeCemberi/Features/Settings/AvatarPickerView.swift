import SwiftUI

struct AvatarPickerView: View {
    let settings: AppSettings
    let onSelect: (PlayerAvatar) -> Void
    let onStore: () -> Void
    let onBack: () -> Void

    var body: some View {
        ZStack {
            GameBackground()
            VStack(spacing: GameSpacing.lg) {
                ScreenHeader(title: "AVATARINI SEÇ", onBack: onBack)
                Text("Seni çemberde temsil edecek karakteri seç.").font(.subheadline).foregroundStyle(GameColors.textSecondary)
                LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: GameSpacing.md) {
                    ForEach(PlayerAvatar.allCases.filter { settings.owns($0) }) { avatar in
                        Button { onSelect(avatar) } label: {
                            GlassPanel {
                                VStack(spacing: 10) {
                                    Image(avatar.assetName).resizable().scaledToFill().frame(width: 112, height: 112)
                                        .clipShape(Circle()).overlay { Circle().stroke(settings.selectedAvatar == avatar ? GameColors.cyan : .white.opacity(0.15), lineWidth: settings.selectedAvatar == avatar ? 4 : 1) }
                                        .shadow(color: settings.selectedAvatar == avatar ? GameColors.cyan.opacity(0.7) : .clear, radius: 12)
                                    HStack(spacing: 5) {
                                        if settings.selectedAvatar == avatar { Image(systemName: "checkmark.circle.fill").foregroundStyle(GameColors.success) }
                                        Text(avatar.title).font(.subheadline.bold()).foregroundStyle(.white)
                                    }
                                }.padding(12).frame(maxWidth: .infinity)
                            }
                        }.buttonStyle(.plain).accessibilityLabel("\(avatar.title) avatarı")
                    }
                }
                Button("YENİ AVATARLAR İÇİN MAĞAZAYA GİT", action: onStore).buttonStyle(GameButtonStyle(kind: .compact))
                Spacer()
            }.padding(GameSpacing.md)
        }.preferredColorScheme(.dark)
    }
}

struct GameStoreView: View {
    let settings: AppSettings
    let buyAvatar: (PlayerAvatar) -> Bool
    let buyTheme: (CircleTheme) -> Bool
    let selectAvatar: (PlayerAvatar) -> Void
    let selectTheme: (CircleTheme) -> Void
    let onBack: () -> Void
    @State private var message: String?

    var body: some View {
        ZStack {
            GameBackground()
            ScrollView {
                VStack(spacing: GameSpacing.lg) {
                    ScreenHeader(title: "MAĞAZA", onBack: onBack)
                    Label("\(settings.coinBalance.formatted()) JETON", systemImage: "seal.fill")
                        .font(.title2.bold()).foregroundStyle(.yellow).padding(12).background(GameColors.panel, in: Capsule())
                    storeTitle("AVATARLAR")
                    LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 12) {
                        ForEach(PlayerAvatar.allCases) { avatar in
                            Button { avatarAction(avatar) } label: {
                                GlassPanel {
                                    VStack(spacing: 8) {
                                        Image(avatar.assetName).resizable().scaledToFill().frame(width: 82, height: 82).clipShape(Circle())
                                        Text(avatar.title).font(.headline).foregroundStyle(.white)
                                        productState(owned: settings.owns(avatar), selected: settings.selectedAvatar == avatar, price: avatar.price)
                                    }.padding(12).frame(maxWidth: .infinity)
                                }
                            }.buttonStyle(.plain)
                        }
                    }
                    storeTitle("ÇEMBER TEMALARI")
                    ForEach(CircleTheme.allCases) { theme in
                        Button { themeAction(theme) } label: {
                            GlassPanel {
                                HStack(spacing: 16) {
                                    ZStack {
                                        Circle().stroke(theme.secondary.opacity(0.6), lineWidth: 10)
                                        Circle().trim(from: 0, to: 0.76).stroke(theme.primary, style: .init(lineWidth: 5, lineCap: .round)).rotationEffect(.degrees(-90)).shadow(color: theme.primary, radius: 7)
                                    }.frame(width: 66, height: 66)
                                    VStack(alignment: .leading, spacing: 7) {
                                        Text(theme.title).font(.headline).foregroundStyle(.white)
                                        productState(owned: settings.owns(theme), selected: settings.selectedCircleTheme == theme, price: theme.price)
                                    }
                                    Spacer()
                                }.padding(14)
                            }
                        }.buttonStyle(.plain)
                    }
                    Text("Her tamamlanan turda doğru cevaplarına göre jeton kazanırsın.").font(.caption).foregroundStyle(GameColors.textSecondary)
                }.padding(GameSpacing.md)
            }
        }.preferredColorScheme(.dark)
        .alert("Parola Çemberi", isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) {
            Button("Tamam", role: .cancel) {}
        } message: { Text(message ?? "") }
    }

    private func avatarAction(_ avatar: PlayerAvatar) {
        if settings.owns(avatar) { selectAvatar(avatar) }
        else { message = buyAvatar(avatar) ? "\(avatar.title) satın alındı." : "Yeterli jetonun yok." }
    }
    private func themeAction(_ theme: CircleTheme) {
        if settings.owns(theme) { selectTheme(theme) }
        else { message = buyTheme(theme) ? "\(theme.title) satın alındı." : "Yeterli jetonun yok." }
    }
    private func storeTitle(_ title: String) -> some View {
        Text(title).font(.caption.bold()).tracking(1.4).foregroundStyle(GameColors.cyan).frame(maxWidth: .infinity, alignment: .leading)
    }
    @ViewBuilder private func productState(owned: Bool, selected: Bool, price: Int) -> some View {
        if selected { Label("SEÇİLİ", systemImage: "checkmark.circle.fill").foregroundStyle(GameColors.success).font(.caption.bold()) }
        else if owned { Text("KULLAN").foregroundStyle(GameColors.cyan).font(.caption.bold()) }
        else { Label(price.formatted(), systemImage: "seal.fill").foregroundStyle(.yellow).font(.caption.bold()) }
    }
}
