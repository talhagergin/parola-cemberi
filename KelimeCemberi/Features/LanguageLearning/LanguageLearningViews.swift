import SwiftUI

struct LanguageSelectionView: View {
    let onBack: () -> Void
    let onSelect: (LearningLanguage) -> Void
    var body: some View {
        ZStack {
            GameBackground()
            VStack(spacing: GameSpacing.lg) {
                ScreenHeader(title: "DİL ÖĞREN", onBack: onBack)
                Text("Öğrenmek istediğin dili seç").foregroundStyle(GameColors.textSecondary)
                ForEach(LearningLanguage.allCases) { language in
                    Button { onSelect(language) } label: {
                        GlassPanel {
                            HStack(spacing: 18) {
                                Text(language.flag).font(.system(size: 44))
                                VStack(alignment: .leading) {
                                    Text(language.title).font(.title3.bold()).foregroundStyle(.white)
                                    Text(language.nativeTitle).foregroundStyle(GameColors.textSecondary)
                                }
                                Spacer(); Image(systemName: "chevron.right").foregroundStyle(GameColors.cyan)
                            }.padding(18)
                        }
                    }.buttonStyle(.plain)
                }
                Spacer()
            }.padding(GameSpacing.md)
        }.preferredColorScheme(.dark)
    }
}

struct LevelSelectionView: View {
    let language: LearningLanguage
    let onBack: () -> Void
    let onSelect: (CEFRLevel, [LanguageLearningQuestion]) -> Void
    @State private var questions: [LanguageLearningQuestion] = []
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            GameBackground()
            ScrollView {
                VStack(spacing: GameSpacing.lg) {
                    ScreenHeader(title: "\(language.flag) \(language.title.uppercased())", onBack: onBack)
                    Text("CEFR seviyeni seç").foregroundStyle(GameColors.textSecondary)
                    LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 14) {
                        ForEach(CEFRLevel.allCases) { level in
                            Button { onSelect(level, questions.filter { $0.cefrLevel == level }) } label: {
                                GlassPanel {
                                    VStack(spacing: 8) {
                                        Text(level.rawValue).font(.system(size: 34, weight: .heavy, design: .rounded)).foregroundStyle(GameColors.cyan)
                                        Text(level.subtitle).font(.subheadline.bold()).foregroundStyle(.white)
                                        Text("\(questions.count { $0.cefrLevel == level }) soru").font(.caption).foregroundStyle(GameColors.textSecondary)
                                    }.padding(16).frame(maxWidth: .infinity, minHeight: 130)
                                }
                            }.buttonStyle(.plain).disabled(questions.isEmpty)
                        }
                    }
                    if let errorMessage { Text(errorMessage).foregroundStyle(GameColors.danger).font(.caption) }
                }.padding(GameSpacing.md)
            }
        }.preferredColorScheme(.dark)
        .task {
            do { questions = try LanguageQuestionLoader().load(language) }
            catch { errorMessage = "Dil paketi yüklenemedi." }
        }
    }
}

struct LanguageLessonView: View {
    let language: LearningLanguage
    let level: CEFRLevel
    let sourceQuestions: [LanguageLearningQuestion]
    let onExit: () -> Void
    @State private var questions: [LanguageLearningQuestion] = []
    @State private var index = 0
    @State private var answer = ""
    @State private var feedback: Bool?
    @State private var correctCount = 0

    private var current: LanguageLearningQuestion? { questions.indices.contains(index) ? questions[index] : nil }
    var body: some View {
        ZStack {
            GameBackground()
            VStack(spacing: GameSpacing.lg) {
                ScreenHeader(title: "\(language.flag) \(level.rawValue)", onBack: onExit)
                if let current {
                    Text("\(index + 1) / \(questions.count)").font(.caption.bold()).foregroundStyle(GameColors.textSecondary)
                    ProgressView(value: Double(index), total: Double(max(1, questions.count))).tint(GameColors.cyan)
                    Spacer()
                    Text(current.initialLetter).font(.system(size: 58, weight: .heavy, design: .rounded)).foregroundStyle(GameColors.cyan)
                    Text(current.clue).font(.system(.title, design: .rounded, weight: .bold)).multilineTextAlignment(.center).foregroundStyle(.white)
                    Text("\(language.nativeTitle) karşılığını yaz").foregroundStyle(GameColors.textSecondary)
                    TextField("Cevabın…", text: $answer).textInputAutocapitalization(.characters).autocorrectionDisabled()
                        .padding().background(GameColors.panel, in: RoundedRectangle(cornerRadius: 16)).foregroundStyle(.white)
                    if let feedback {
                        Text(feedback ? "DOĞRU!" : "Doğru cevap: \(current.answer)").font(.headline.bold()).foregroundStyle(feedback ? GameColors.success : GameColors.danger)
                    }
                    Button(feedback == nil ? "CEVAPLA" : "DEVAM ET") {
                        if feedback == nil { let result = current.matches(answer); feedback = result; if result { correctCount += 1 } }
                        else { index += 1; answer = ""; feedback = nil }
                    }.buttonStyle(GameButtonStyle(kind: .primary)).disabled(answer.isEmpty && feedback == nil)
                    Spacer()
                } else {
                    Spacer()
                    Image(systemName: "trophy.fill").font(.system(size: 64)).foregroundStyle(.yellow)
                    Text("DERS TAMAMLANDI").font(.title2.bold()).foregroundStyle(.white)
                    Text("\(questions.count) soruda \(correctCount) doğru").foregroundStyle(GameColors.cyan)
                    Button("SEVİYELERE DÖN", action: onExit).buttonStyle(GameButtonStyle(kind: .primary))
                    Spacer()
                }
            }.padding(GameSpacing.md)
        }.preferredColorScheme(.dark).onAppear { if questions.isEmpty { questions = Array(sourceQuestions.shuffled().prefix(10)) } }
    }
}
