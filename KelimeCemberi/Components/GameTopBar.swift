import SwiftUI

struct GameTopBar: View {
    let streak: Int
    let correctCount: Int
    let onPause: () -> Void

    var body: some View {
        HStack(spacing: GameSpacing.sm) {
            Button(action: onPause) {
                Image(systemName: "pause.fill")
                    .font(.headline).frame(width: 44, height: 44)
                    .background(GameColors.panel.opacity(0.85), in: RoundedRectangle(cornerRadius: 14))
                    .overlay { RoundedRectangle(cornerRadius: 14).stroke(GameColors.glassBorder) }
            }.accessibilityLabel("Oyunu duraklat")

            VStack(spacing: -3) {
                Text("PAROLA").foregroundStyle(.white)
                Text("ÇEMBERİ").foregroundStyle(GameColors.cyan)
            }.font(.system(size: 18, weight: .heavy, design: .rounded)).tracking(0.4)

            Spacer()
            Label("\(streak)", systemImage: "flame.fill")
                .foregroundStyle(streak > 1 ? GameColors.orange : GameColors.textSecondary)
            Label("\(correctCount)", systemImage: "checkmark.seal.fill")
                .foregroundStyle(GameColors.success)
        }
        .font(.subheadline.bold()).foregroundStyle(.white)
    }
}
