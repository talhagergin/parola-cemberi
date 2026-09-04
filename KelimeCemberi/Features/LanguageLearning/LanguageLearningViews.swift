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
                                LanguageFlagView(language: language).frame(width: 58, height: 40)
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
                    ScreenHeader(title: language.title.uppercased(), flag: language, onBack: onBack)
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
    var soundEffectsEnabled = true
    let onFinished: () -> Void
    let onExit: () -> Void
    @State private var letters: [LanguageCircleItem] = []
    @State private var activeIndex: Int?
    @State private var answer = ""
    @State private var feedback: LanguageFeedback?
    @State private var correctCount = 0
    @State private var score = 0
    @State private var streak = 0
    @State private var remainingSeconds = 120
    @State private var isFinished = false
    @State private var preparationError: String?
    @State private var didPlayTimeWarning = false
    @State private var didPlayCompletionSound = false
    @State private var didReportCompletion = false
    @State private var timerTask: Task<Void, Never>?

    private var activeItem: LanguageCircleItem? { activeIndex.flatMap { letters.indices.contains($0) ? letters[$0] : nil } }
    var body: some View {
        ZStack {
            GameBackground()
            GeometryReader { proxy in
                ScrollView {
                    VStack(spacing: 12) {
                        ScreenHeader(title: "\(level.rawValue) ÇEMBERİ", flag: language, onBack: onExit)
                        LanguageCircleWheel(items: letters, remainingSeconds: remainingSeconds, score: score, streak: streak)
                            .frame(maxHeight: min(proxy.size.width - 20, proxy.size.height * 0.51))
                        if let question = activeItem?.question {
                            GlassPanel {
                                VStack(alignment: .leading, spacing: 9) {
                                    HStack {
                                        Text("\(question.initialLetter) HARFİ").font(.caption.bold()).foregroundStyle(GameColors.cyan)
                                        Spacer(); Text("\(language.nativeTitle) • \(level.rawValue)").font(.caption2.bold()).foregroundStyle(GameColors.textSecondary)
                                    }
                                    Text(question.clue).font(.title3.bold()).foregroundStyle(.white)
                                    Text("Türkçe anlamın \(language.title) karşılığını yaz.").font(.caption).foregroundStyle(GameColors.textSecondary)
                                }.padding(GameSpacing.md).frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        VStack(spacing: 10) {
                            TextField("Cevabını yaz…", text: $answer).textInputAutocapitalization(.characters).autocorrectionDisabled().submitLabel(.done)
                                .onSubmit(submit).padding(.horizontal, 16).frame(minHeight: 50)
                                .background(GameColors.background.opacity(0.8), in: RoundedRectangle(cornerRadius: 16)).foregroundStyle(.white)
                            HStack(spacing: 10) {
                                Button("PAS", action: pass).buttonStyle(GameButtonStyle(kind: .compact))
                                Button("CEVAPLA", action: submit).buttonStyle(GameButtonStyle(kind: .primary)).disabled(answer.trimmingCharacters(in: .whitespaces).isEmpty)
                            }
                        }
                    }.padding(GameSpacing.md).frame(minHeight: proxy.size.height)
                }
            }
            if let feedback {
                VStack(spacing: 8) {
                    Image(systemName: feedback.correct ? "checkmark.circle.fill" : "xmark.circle.fill").font(.system(size: 50))
                    Text(feedback.title).font(.headline.bold())
                }.foregroundStyle(feedback.correct ? GameColors.success : GameColors.danger).padding(24).background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22))
            }
            if isFinished { resultOverlay }
            if let preparationError {
                GlassPanel {
                    VStack(spacing: 14) {
                        Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 42)).foregroundStyle(GameColors.orange)
                        Text(preparationError).multilineTextAlignment(.center).foregroundStyle(.white)
                        Button("SEVİYELERE DÖN", action: onExit).buttonStyle(GameButtonStyle(kind: .primary))
                    }.padding(24)
                }.padding(28)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { prepare() }
        .onDisappear { timerTask?.cancel() }
    }

    private var resultOverlay: some View {
        let passedItems = letters.filter { $0.status != .correct && $0.passCount > 0 }
        let wrongItems = letters.filter { $0.status == .wrong && $0.passCount == 0 }
        return ZStack {
            Color.black.opacity(0.78).ignoresSafeArea()
            GlassPanel {
                ScrollView {
                    VStack(spacing: 16) {
                        Image(systemName: "trophy.fill").font(.system(size: 50)).foregroundStyle(.yellow)
                        Text("ÇEMBER TAMAMLANDI").font(.title2.bold()).foregroundStyle(.white)
                        Text("\(correctCount) doğru • \(passedItems.count) pas • \(wrongItems.count) yanlış/boş")
                            .font(.headline).foregroundStyle(GameColors.cyan).multilineTextAlignment(.center)
                        Text("\(score) puan").font(.title3.bold()).foregroundStyle(.white)
                        if !passedItems.isEmpty {
                            LanguageMistakeSection(title: "PAS GEÇİLENLER", icon: "arrow.right.circle.fill", color: GameColors.purple, items: passedItems)
                        }
                        if !wrongItems.isEmpty {
                            LanguageMistakeSection(title: "YANLIŞ / BOŞ", icon: "xmark.circle.fill", color: GameColors.danger, items: wrongItems)
                        }
                        Button("SEVİYELERE DÖN", action: onExit).buttonStyle(GameButtonStyle(kind: .primary))
                    }.padding(24)
                }
            }.padding(28)
        }
    }

    private func prepare() {
        guard letters.isEmpty else { return }
        let grouped = Dictionary(grouping: sourceQuestions, by: { $0.initialLetter.uppercased() })
        let missingLetters = language.alphabet.filter { grouped[$0]?.isEmpty != false }
        guard missingLetters.isEmpty else {
            preparationError = "Bu seviyenin soru paketi eksik. Çember başlatılamadı."
            return
        }
        letters = language.alphabet.compactMap { letter in
            grouped[letter]?.randomElement().map {
                LanguageCircleItem(letter: letter, question: $0, status: .waiting)
            }
        }
        activateNext(after: -1)
        timerTask = Task { @MainActor in
            while !Task.isCancelled && remainingSeconds > 0 && !isFinished {
                try? await Task.sleep(for: .seconds(1)); guard !Task.isCancelled else { return }
                remainingSeconds -= 1
                if remainingSeconds <= 10, remainingSeconds > 0, !didPlayTimeWarning {
                    didPlayTimeWarning = true
                    GameAudioManager.shared.play(.timeWarning, enabled: soundEffectsEnabled)
                }
            }
            if remainingSeconds == 0 && !isFinished { finish() }
        }
    }

    private func submit() {
        guard feedback == nil, let index = activeIndex, let question = letters[index].question else { return }
        let correct = question.matches(answer)
        letters[index].status = correct ? .correct : .wrong
        if correct { correctCount += 1; streak += 1; score += 100 + max(0, streak - 1) * 15 }
        else { streak = 0 }
        GameAudioManager.shared.play(correct && streak >= 3 ? .streak : correct ? .correct : .wrong, enabled: soundEffectsEnabled)
        feedback = LanguageFeedback(correct: correct, title: correct ? "DOĞRU!" : "YANLIŞ • \(question.answer)")
        answer = ""
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(650)); feedback = nil; activateNext(after: index)
        }
    }

    private func pass() {
        guard feedback == nil, let index = activeIndex else { return }
        letters[index].passCount += 1
        if letters[index].passCount >= 2 { letters[index].status = .wrong; streak = 0 }
        else { letters[index].status = .passed }
        GameAudioManager.shared.play(.passed, enabled: soundEffectsEnabled)
        answer = ""; activateNext(after: index)
    }

    private func activateNext(after current: Int) {
        guard !isFinished else { return }
        let indices = Array(letters.indices)
        let ordered = indices.filter { $0 > current } + indices.filter { $0 <= current }
        let next = ordered.first { letters[$0].status == .waiting }
            ?? ordered.first { letters[$0].status == .passed && letters[$0].passCount < 2 }
        guard let next else { finish(); return }
        letters[next].status = .active; activeIndex = next
    }

    private func finish() {
        guard !isFinished else { return }
        timerTask?.cancel(); activeIndex = nil; isFinished = true
        for index in letters.indices where [.waiting, .active, .passed].contains(letters[index].status) { letters[index].status = .wrong }
        if !didPlayCompletionSound {
            didPlayCompletionSound = true
            GameAudioManager.shared.play(.roundCompleted, enabled: soundEffectsEnabled)
        }
        if !didReportCompletion {
            didReportCompletion = true
            onFinished()
        }
    }
}

struct LanguageFlagView: View {
    let language: LearningLanguage

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                switch language {
                case .english:
                    Color(red: 0.05, green: 0.16, blue: 0.42)
                    diagonalCross(in: proxy.size, color: .white, width: proxy.size.height * 0.24)
                    diagonalCross(in: proxy.size, color: Color(red: 0.78, green: 0.05, blue: 0.12), width: proxy.size.height * 0.10)
                    Rectangle().fill(.white).frame(height: proxy.size.height * 0.30)
                    Rectangle().fill(.white).frame(width: proxy.size.height * 0.30)
                    Rectangle().fill(Color(red: 0.78, green: 0.05, blue: 0.12)).frame(height: proxy.size.height * 0.16)
                    Rectangle().fill(Color(red: 0.78, green: 0.05, blue: 0.12)).frame(width: proxy.size.height * 0.16)
                case .italian:
                    HStack(spacing: 0) {
                        Color(red: 0.0, green: 0.57, blue: 0.27)
                        Color.white
                        Color(red: 0.81, green: 0.07, blue: 0.15)
                    }
                case .german:
                    VStack(spacing: 0) {
                        Color.black
                        Color(red: 0.86, green: 0.0, blue: 0.08)
                        Color(red: 1.0, green: 0.80, blue: 0.0)
                    }
                case .dutch:
                    VStack(spacing: 0) {
                        Color(red: 0.68, green: 0.08, blue: 0.12)
                        Color.white
                        Color(red: 0.08, green: 0.20, blue: 0.48)
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: max(3, proxy.size.height * 0.14)))
            .overlay {
                RoundedRectangle(cornerRadius: max(3, proxy.size.height * 0.14))
                    .stroke(.white.opacity(0.45), lineWidth: 1)
            }
        }
        .aspectRatio(1.45, contentMode: .fit)
        .accessibilityLabel("\(language.title) bayrağı")
    }

    private func diagonalCross(in size: CGSize, color: Color, width: CGFloat) -> some View {
        Path { path in
            path.move(to: .zero)
            path.addLine(to: CGPoint(x: size.width, y: size.height))
            path.move(to: CGPoint(x: size.width, y: 0))
            path.addLine(to: CGPoint(x: 0, y: size.height))
        }
        .stroke(color, style: StrokeStyle(lineWidth: width, lineCap: .butt))
    }
}

private struct LanguageFeedback { let correct: Bool; let title: String }
private enum LanguageCircleStatus { case waiting, active, correct, wrong, passed }
private struct LanguageCircleItem: Identifiable {
    let letter: String
    let question: LanguageLearningQuestion?
    var status: LanguageCircleStatus
    var passCount = 0
    var id: String { letter }
}

private struct LanguageMistakeSection: View {
    let title: String
    let icon: String
    let color: Color
    let items: [LanguageCircleItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon).font(.caption.bold()).foregroundStyle(color)
            ForEach(items) { item in
                if let question = item.question {
                    HStack(alignment: .top, spacing: 10) {
                        Text(item.letter).font(.headline.bold()).foregroundStyle(color).frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(question.clue).font(.subheadline).foregroundStyle(.white)
                            Text(question.answer).font(.caption.bold()).foregroundStyle(GameColors.cyan)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(10)
                    .background(GameColors.background.opacity(0.52), in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct LanguageCircleWheel: View {
    let items: [LanguageCircleItem]
    let remainingSeconds: Int
    let score: Int
    let streak: Int
    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            let tile = min(34.0, max(24.0, side * 0.078))
            let radius = side * 0.425
            let center = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)
            ZStack {
                Circle().stroke(GameColors.purple.opacity(0.3), lineWidth: 2).frame(width: side * 0.72, height: side * 0.72)
                Circle().stroke(style: StrokeStyle(lineWidth: 6, lineCap: .round, dash: [1, 11])).foregroundStyle(GameColors.cyan.opacity(0.22)).frame(width: side * 0.64, height: side * 0.64)
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    let angle = Angle.degrees(-90 + (360 / Double(max(1, items.count))) * Double(index))
                    LanguageCircleTile(item: item, size: tile)
                        .position(x: center.x + radius * cos(angle.radians), y: center.y + radius * sin(angle.radians))
                }
                LanguageCircleCenter(remainingSeconds: remainingSeconds, score: score, streak: streak)
                    .frame(width: side * 0.52, height: side * 0.52)
            }.frame(maxWidth: .infinity, maxHeight: .infinity)
        }.aspectRatio(1, contentMode: .fit)
    }
}

private struct LanguageCircleTile: View {
    let item: LanguageCircleItem
    let size: CGFloat
    var body: some View {
        Text(item.letter)
            .font(.system(size: size * 0.5, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)
            .frame(width: size, height: size * 1.12)
            .background(fill(item.status), in: RoundedRectangle(cornerRadius: size * 0.25))
            .overlay { RoundedRectangle(cornerRadius: size * 0.25).stroke(border, lineWidth: item.status == .active ? 2.5 : 1) }
            .shadow(color: item.status == .active ? GameColors.orange : .clear, radius: 10)
    }
    private var border: Color { item.status == .active ? .white : .white.opacity(0.2) }
    private func fill(_ status: LanguageCircleStatus) -> LinearGradient {
        let colors: [Color] = switch status {
        case .waiting: [Color(red: 0.31, green: 0.35, blue: 0.84), GameColors.panel]
        case .active: [.yellow, GameColors.orange]
        case .correct: [Color(red: 0.42, green: 0.91, blue: 0.25), Color(red: 0.08, green: 0.48, blue: 0.15)]
        case .wrong: [Color(red: 1, green: 0.34, blue: 0.4), Color(red: 0.6, green: 0.05, blue: 0.13)]
        case .passed: [GameColors.purple, GameColors.panel]
        }
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

private struct LanguageCircleCenter: View {
    let remainingSeconds: Int
    let score: Int
    let streak: Int
    var body: some View {
        ZStack {
            Circle().fill(GameColors.background.opacity(0.94))
            Circle().stroke(GameColors.purple.opacity(0.5), lineWidth: 4)
            VStack(spacing: 5) {
                Image(systemName: "clock.fill").foregroundStyle(remainingSeconds <= 10 ? GameColors.danger : GameColors.cyan)
                Text(remainingSeconds.gameClockText).font(.system(size: 30, weight: .heavy, design: .rounded)).monospacedDigit()
                Text("PUAN").font(.caption2.bold()).foregroundStyle(GameColors.cyan)
                Text(score.formatted()).font(.title2.bold())
                if streak > 1 { Label("\(streak) SERİ", systemImage: "flame.fill").font(.caption2.bold()).foregroundStyle(GameColors.orange) }
            }.foregroundStyle(.white)
        }
    }
}
