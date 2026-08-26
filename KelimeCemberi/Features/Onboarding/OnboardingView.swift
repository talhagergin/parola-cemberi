import SwiftUI

struct OnboardingView: View {
    let onComplete: () -> Void
    @State private var page = 0

    private let pages = [
        OnboardingPage(icon: "circle.hexagongrid.fill", title: "ÇEMBERİ TAMAMLA",
                       message: "Türk alfabesindeki her harf için doğru kelimeyi bul.", color: GameColors.cyan),
        OnboardingPage(icon: "arrowshape.turn.up.right.fill", title: "CEVAPLA YA DA PAS",
                       message: "Takıldığın soruyu pas geç; turun sonunda ona yeniden dön.", color: GameColors.purple),
        OnboardingPage(icon: "flame.fill", title: "SERİNİ BÜYÜT",
                       message: "Arka arkaya doğru cevaplarla bonus puan kazan. İpucunu akıllıca kullan.", color: GameColors.orange)
    ]

    var body: some View {
        ZStack {
            GameBackground()
            VStack(spacing: GameSpacing.xl) {
                HStack {
                    Spacer()
                    Button("Atla", action: onComplete).foregroundStyle(GameColors.textSecondary)
                }.padding(.horizontal)
                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, item in
                        VStack(spacing: GameSpacing.xl) {
                            ZStack {
                                Circle().fill(item.color.opacity(0.16)).frame(width: 210, height: 210)
                                Circle().stroke(item.color.opacity(0.45), lineWidth: 3).frame(width: 180, height: 180)
                                Image(systemName: item.icon).font(.system(size: 78, weight: .bold))
                                    .foregroundStyle(item.color).shadow(color: item.color, radius: 20)
                            }
                            Text(item.title).font(.system(.title, design: .rounded, weight: .heavy)).foregroundStyle(.white)
                            Text(item.message).font(.title3).multilineTextAlignment(.center)
                                .foregroundStyle(GameColors.textSecondary).padding(.horizontal, 32)
                        }.tag(index)
                    }
                }.tabViewStyle(.page(indexDisplayMode: .always))
                Button(page == pages.count - 1 ? "OYUNA BAŞLA" : "DEVAM ET") {
                    if page == pages.count - 1 { onComplete() }
                    else { withAnimation { page += 1 } }
                }
                .buttonStyle(GameButtonStyle(kind: .primary)).padding(.horizontal, 34).padding(.bottom, 28)
            }
        }.preferredColorScheme(.dark)
    }
}

private struct OnboardingPage {
    let icon: String
    let title: String
    let message: String
    let color: Color
}
