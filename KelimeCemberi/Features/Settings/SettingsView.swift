import SwiftUI

struct SettingsView: View {
    @Bindable var settings: AppSettings
    let errorMessage: String?
    let onSave: () -> Void
    let onReplayOnboarding: () -> Void
    let onResetProgress: () -> Void
    let onBack: () -> Void
    @State private var confirmReset = false
    @State private var showAbout = false

    var body: some View {
        ZStack {
            GameBackground()
            ScrollView {
                VStack(spacing: GameSpacing.md) {
                    ScreenHeader(title: "AYARLAR", onBack: onBack)
                    Text("Deneyimini kişiselleştir").font(.subheadline).foregroundStyle(GameColors.textSecondary)
                    settingsSection("SES VE GERİ BİLDİRİM") {
                        SettingsToggle(title: "Müzik", icon: "music.note", value: $settings.musicEnabled)
                        SettingsToggle(title: "Efekt sesleri", icon: "speaker.wave.2.fill", value: $settings.soundEffectsEnabled)
                        SettingsToggle(title: "Haptic", icon: "iphone.radiowaves.left.and.right", value: $settings.hapticsEnabled)
                    }
                    settingsSection("GÖRÜNÜM VE ERİŞİLEBİLİRLİK") {
                        SettingsToggle(title: "Hareketi azalt", icon: "figure.walk.motion", value: $settings.reduceMotion)
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Soru yazı boyutu", systemImage: "textformat.size").foregroundStyle(.white)
                            Slider(value: $settings.questionTextScale, in: 0.85...1.35, step: 0.1) { Text("Soru yazı boyutu") }
                                .tint(GameColors.cyan)
                            Text("Örnek soru metni").font(.system(size: 16 * settings.questionTextScale)).foregroundStyle(GameColors.textSecondary)
                        }.padding(.vertical, 8)
                        Picker("Tema", selection: $settings.themeRawValue) {
                            ForEach(AppThemePreference.allCases) { Text($0.title).tag($0.rawValue) }
                        }.tint(GameColors.cyan)
                    }
                    settingsSection("VERİ VE UYGULAMA") {
                        SettingsAction(title: "Onboarding’i tekrar göster", icon: "sparkles", color: GameColors.cyan, action: onReplayOnboarding)
                        SettingsAction(title: "Gizlilik ve hakkında", icon: "info.circle.fill", color: GameColors.textSecondary) { showAbout = true }
                        SettingsAction(title: "İlerlemeyi sıfırla", icon: "trash.fill", color: GameColors.danger) { confirmReset = true }
                    }
                    if let errorMessage { Text(errorMessage).font(.caption).foregroundStyle(GameColors.danger) }
                }.padding(GameSpacing.md)
            }
        }
        .preferredColorScheme(.dark)
        .onChange(of: settings.musicEnabled) { onSave() }
        .onChange(of: settings.soundEffectsEnabled) { onSave() }
        .onChange(of: settings.hapticsEnabled) { onSave() }
        .onChange(of: settings.reduceMotion) { onSave() }
        .onChange(of: settings.themeRawValue) { onSave() }
        .onChange(of: settings.questionTextScale) { onSave() }
        .confirmationDialog("Tüm oyun geçmişi silinsin mi?", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("İlerlemeyi Sil", role: .destructive, action: onResetProgress)
            Button("Vazgeç", role: .cancel) {}
        } message: { Text("Ayarların korunur; skor, harf ve kategori istatistikleri silinir.") }
        .sheet(isPresented: $showAbout) {
            NavigationStack {
                List {
                    Section("Parola Çemberi") { Text("Türk alfabesinin 29 harfiyle oynanan özgün parola yarışması.") }
                    Section("Gizlilik") { Text("Oyun ilerlemesi ve ayarlar yalnızca bu cihazda SwiftData ile saklanır. Uygulama kişisel veri toplamaz.") }
                    Section("Sürüm") { Text("1.0 • Sprint 4") }
                }.navigationTitle("Hakkında").toolbar { ToolbarItem(placement: .confirmationAction) { Button("Bitti") { showAbout = false } } }
            }.preferredColorScheme(.dark)
        }
    }

    private func settingsSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.caption.bold()).tracking(1.2).foregroundStyle(GameColors.cyan).padding(.leading, 4)
            GlassPanel { VStack(spacing: 4) { content() }.padding(GameSpacing.md) }
        }
    }
}

private struct SettingsToggle: View {
    let title, icon: String
    @Binding var value: Bool
    var body: some View { Toggle(isOn: $value) { Label(title, systemImage: icon).foregroundStyle(.white) }.tint(GameColors.cyan).frame(minHeight: 44) }
}

private struct SettingsAction: View {
    let title, icon: String
    let color: Color
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack { Label(title, systemImage: icon).foregroundStyle(color); Spacer(); Image(systemName: "chevron.right").foregroundStyle(GameColors.textSecondary) }
                .frame(minHeight: 44).contentShape(Rectangle())
        }.buttonStyle(.plain)
    }
}
