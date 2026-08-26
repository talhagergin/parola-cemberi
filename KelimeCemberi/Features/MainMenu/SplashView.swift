import SwiftUI

struct SplashView: View {
    @State private var rotate = false

    var body: some View {
        ZStack {
            GameBackground()
            VStack(spacing: GameSpacing.lg) {
                ZStack {
                    Circle().stroke(GameColors.purple.opacity(0.4), lineWidth: 16)
                    Circle().trim(from: 0, to: 0.72)
                        .stroke(GameColors.cyan, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                        .rotationEffect(.degrees(rotate ? 270 : -90)).shadow(color: GameColors.cyan, radius: 16)
                    Text("KÇ").font(.system(size: 55, weight: .heavy, design: .rounded)).foregroundStyle(.white)
                }.frame(width: 170, height: 170)
                VStack(spacing: 0) {
                    Text("PAROLA").foregroundStyle(.white)
                    Text("ÇEMBERİ").foregroundStyle(GameColors.cyan)
                }.font(.system(size: 38, weight: .heavy, design: .rounded))
                Text("Her harfte yeni bir keşif").foregroundStyle(GameColors.textSecondary)
            }
        }
        .onAppear { withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) { rotate = true } }
        .accessibilityElement(children: .ignore).accessibilityLabel("Parola Çemberi yükleniyor")
    }
}
