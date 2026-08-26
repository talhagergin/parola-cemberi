import StoreKit
import SwiftUI

struct PremiumView: View {
    @Bindable var store: PremiumStore
    let onBack: () -> Void

    var body: some View {
        ZStack {
            GameBackground()
            ScrollView {
                VStack(spacing: GameSpacing.lg) {
                    ScreenHeader(title: "PREMIUM", onBack: onBack)
                    Image(systemName: "crown.fill").font(.system(size: 68)).foregroundStyle(.yellow).shadow(color: .orange, radius: 18)
                    Text(store.isPremium ? "PREMIUM AKTİF" : "KESİNTİSİZ OYNA")
                        .font(.system(.title2, design: .rounded, weight: .heavy)).foregroundStyle(.white)
                    Text("Reklamları kaldır, oyunun ritmini hiç bozmadan çemberi tamamla.")
                        .multilineTextAlignment(.center).foregroundStyle(GameColors.textSecondary)

                    GlassPanel {
                        VStack(alignment: .leading, spacing: 14) {
                            PremiumBenefit(icon: "nosign", text: "Tüm banner reklamları kaldırılır")
                            PremiumBenefit(icon: "gamecontroller.fill", text: "Oyun modları reklamsız kalır")
                            PremiumBenefit(icon: "sparkles", text: "Gelecekteki premium kozmetiklere erişim")
                        }.padding(GameSpacing.lg)
                    }

                    if store.isPremium {
                        Label("Aboneliğin doğrulandı", systemImage: "checkmark.seal.fill").foregroundStyle(GameColors.success).font(.headline)
                    } else if store.products.isEmpty {
                        Button("ÜRÜNLERİ YENİLE") { Task { await store.load() } }.buttonStyle(GameButtonStyle(kind: .primary))
                    } else {
                        ForEach(store.products, id: \.id) { product in
                            Button { Task { await store.purchase(product) } } label: {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(product.displayName).font(.headline)
                                        Text(product.description).font(.caption).foregroundStyle(GameColors.textSecondary).lineLimit(2)
                                    }
                                    Spacer()
                                    Text(product.displayPrice).font(.headline).foregroundStyle(GameColors.cyan)
                                }
                            }.buttonStyle(GameButtonStyle(kind: .secondary))
                        }
                    }
                    Button("SATIN ALMALARI GERİ YÜKLE") { Task { await store.restore() } }.buttonStyle(GameButtonStyle(kind: .compact))
                    if store.isLoading { ProgressView().tint(GameColors.cyan) }
                    if let message = store.message { Text(message).font(.caption).multilineTextAlignment(.center).foregroundStyle(GameColors.textSecondary) }
                }.padding(GameSpacing.md)
            }
        }.preferredColorScheme(.dark)
    }
}

private struct PremiumBenefit: View {
    let icon, text: String
    var body: some View { Label(text, systemImage: icon).foregroundStyle(.white).frame(minHeight: 32) }
}
