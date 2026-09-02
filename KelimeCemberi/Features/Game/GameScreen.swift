import SwiftUI

struct GameScreen: View {
    let request: GameLaunchRequest
    let questionTextScale: Double
    let reduceMotionOverride: Bool
    let recentQuestionIDs: Set<UUID>
    let soundEffectsEnabled: Bool
    let circleTheme: CircleTheme
    let onFinished: (GameSession) -> Void
    let onExit: () -> Void
    @State private var model: GameScreenViewModel
    @State private var didReportResult = false
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var didPlayTimeWarning = false
    @FocusState private var isAnswerFocused: Bool

    init(request: GameLaunchRequest, questionTextScale: Double = 1, reduceMotionOverride: Bool = false, recentQuestionIDs: Set<UUID> = [], soundEffectsEnabled: Bool = true, circleTheme: CircleTheme = .classic, onFinished: @escaping (GameSession) -> Void, onExit: @escaping () -> Void) {
        self.request = request
        self.questionTextScale = questionTextScale
        self.reduceMotionOverride = reduceMotionOverride
        self.recentQuestionIDs = recentQuestionIDs
        self.soundEffectsEnabled = soundEffectsEnabled
        self.circleTheme = circleTheme
        self.onFinished = onFinished
        self.onExit = onExit
        _model = State(initialValue: GameScreenViewModel(request: request, recentQuestionIDs: recentQuestionIDs))
    }

    var body: some View {
        ZStack {
            GameBackground()
            content
            if model.isPaused { pauseOverlay }
            feedbackOverlay
        }
        .preferredColorScheme(.dark)
        .task { await model.prepare() }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { Task { await model.pauseForBackground() } }
        }
        .onChange(of: model.session?.phase) { _, phase in
            if phase == .finished, !didReportResult, let session = model.session {
                didReportResult = true
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(280))
                    GameAudioManager.shared.play(.roundCompleted, enabled: soundEffectsEnabled)
                }
                onFinished(session)
            }
        }
        .onChange(of: model.feedback) { _, feedback in
            guard let feedback else { return }
            let event: GameSoundEvent = switch feedback {
            case .correct: (model.session?.streak ?? 0) >= 3 ? .streak : .correct
            case .wrong: .wrong
            case .passed: .passed
            }
            GameAudioManager.shared.play(event, enabled: soundEffectsEnabled)
        }
        .onChange(of: model.session?.remainingSeconds) { _, remaining in
            if let remaining, remaining <= 10, remaining > 0, !didPlayTimeWarning {
                didPlayTimeWarning = true
                GameAudioManager.shared.play(.timeWarning, enabled: soundEffectsEnabled)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch model.loadState {
        case .loading:
            ProgressView("Çember hazırlanıyor…").tint(GameColors.cyan).foregroundStyle(.white)
        case .failed(let message):
            ContentUnavailableView("Oyun hazırlanamadı", systemImage: "exclamationmark.triangle", description: Text(message))
                .foregroundStyle(.white)
        case .ready:
            if let session = model.session {
                GeometryReader { proxy in
                    ScrollView {
                        VStack(spacing: max(10, proxy.size.height * 0.012)) {
                            GameTopBar(
                                streak: session.streak,
                                correctCount: session.letters.filter { $0.status == .correct }.count,
                                onPause: { Task { await model.pause() } }
                            )
                            LetterWheelView(
                                letters: session.letters,
                                remainingSeconds: session.remainingSeconds,
                                totalSeconds: session.configuration.durationSeconds,
                                score: session.score,
                                streak: session.streak,
                                theme: circleTheme
                            )
                            .frame(maxHeight: wheelHeight(for: proxy.size))

                            if let active = model.engine?.activeLetterState {
                                GameQuestionCard(letterState: active, textScale: questionTextScale)
                                    .animation(reduceMotion || reduceMotionOverride ? nil : .spring(response: 0.4, dampingFraction: 0.82), value: active.question?.id)
                            }
                        }
                        .padding(.horizontal, GameSpacing.md)
                        .padding(.vertical, GameSpacing.sm)
                        .frame(minHeight: proxy.size.height)
                    }
                    .scrollDismissesKeyboard(.interactively)
                }
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    answerControls
                        .padding(.horizontal, GameSpacing.md)
                        .padding(.top, GameSpacing.sm)
                        .background(.ultraThinMaterial)
                }
                .animation(.easeInOut(duration: 0.22), value: isAnswerFocused)
            }
        }
    }

    private func wheelHeight(for size: CGSize) -> CGFloat {
        if isAnswerFocused {
            return min(size.width * 0.68, max(210, size.height * 0.34))
        }
        return min(size.width - 20, size.height * 0.49)
    }

    private var answerControls: some View {
        VStack(spacing: GameSpacing.sm) {
            HStack(alignment: .center, spacing: 8) {
                JokerButton(icon: "lightbulb.fill", title: "İPUCU", remaining: remainingHintJokers, color: .yellow, disabled: !canUseHint) {
                    model.useHint()
                    GameAudioManager.shared.play(.hint, enabled: soundEffectsEnabled)
                }

                HStack(spacing: 7) {
                    Image(systemName: "character.cursor.ibeam").foregroundStyle(GameColors.cyan)
                    TextField("Cevabını yaz…", text: $model.answerText)
                        .focused($isAnswerFocused)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                        .onSubmit { Task { await model.submit() } }
                        .foregroundStyle(.white)
                        .accessibilityLabel("Cevap alanı")
                    if isAnswerFocused {
                        Button { Task { await model.submit() } } label: {
                            Image(systemName: "checkmark").font(.headline.bold()).foregroundStyle(.white)
                                .frame(width: 38, height: 36)
                                .background(GameColors.orange, in: RoundedRectangle(cornerRadius: 11))
                        }
                        .disabled(!model.canSubmit).opacity(model.canSubmit ? 1 : 0.42)
                        .accessibilityLabel("Cevapla")
                    }
                }
                .padding(.horizontal, 10).frame(minHeight: 54)
                .background(GameColors.background.opacity(0.78), in: RoundedRectangle(cornerRadius: GameCornerRadius.button))
                .overlay { RoundedRectangle(cornerRadius: GameCornerRadius.button).stroke(GameColors.purple.opacity(0.55), lineWidth: 1.5) }

                JokerButton(icon: "forward.fill", title: "ATLA", remaining: remainingSkipJokers, color: GameColors.purple, disabled: remainingSkipJokers == 0) {
                    Task { await model.pass() }
                }
            }

            if !isAnswerFocused {
                Button("CEVAPLA") { Task { await model.submit() } }
                    .buttonStyle(GameButtonStyle(kind: .primary))
                    .disabled(!model.canSubmit).opacity(model.canSubmit ? 1 : 0.48)
            }
        }
        .padding(.bottom, GameSpacing.sm)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Klavyeyi Kapat") { isAnswerFocused = false }
            }
        }
    }

    private var remainingHintJokers: Int {
        guard let session = model.session else { return 0 }
        return max(0, session.configuration.maximumHintJokers - session.hintsUsed)
    }

    private var remainingSkipJokers: Int {
        guard let session = model.session else { return 0 }
        return max(0, session.configuration.maximumSkipJokers - session.skipsUsed)
    }

    private var canUseHint: Bool {
        guard let active = model.engine?.activeLetterState else { return false }
        return remainingHintJokers > 0 && !active.hintUsed && active.question?.extendedClue != nil
    }

    private var pauseOverlay: some View {
        Color.black.opacity(0.70).ignoresSafeArea().overlay {
            GlassPanel {
                VStack(spacing: GameSpacing.md) {
                    Image(systemName: "pause.circle.fill").font(.system(size: 54)).foregroundStyle(GameColors.cyan)
                    Text("OYUN DURAKLATILDI").font(.title3.bold()).foregroundStyle(.white)
                    Button("DEVAM ET") { Task { await model.resume() } }
                        .buttonStyle(GameButtonStyle(kind: .primary))
                    Button("YENİDEN BAŞLAT") { Task { await model.prepare() } }
                        .buttonStyle(GameButtonStyle(kind: .secondary))
                    Button("ANA MENÜYE DÖN") {
                        Task { await model.exitGame(); onExit() }
                    }.buttonStyle(GameButtonStyle(kind: .compact))
                }.padding(GameSpacing.xl).frame(maxWidth: 300)
            }
        }.transition(.opacity).zIndex(3)
    }

    @ViewBuilder
    private var feedbackOverlay: some View {
        if let feedback = model.feedback {
            let data: (String, String, Color) = switch feedback {
            case .correct: ("checkmark.circle.fill", "DOĞRU!", GameColors.success)
            case .wrong: ("xmark.circle.fill", "YANLIŞ", GameColors.danger)
            case .passed: ("arrow.right.circle.fill", "PAS", GameColors.purple)
            }
            Label(data.1, systemImage: data.0)
                .font(.system(.title2, design: .rounded, weight: .heavy)).foregroundStyle(.white)
                .padding(.horizontal, 22).padding(.vertical, 13)
                .background(data.2.opacity(0.94), in: Capsule()).shadow(color: data.2, radius: 18)
                .transition(.scale.combined(with: .opacity)).zIndex(5)
        }
    }
}

private struct JokerButton: View {
    let icon: String
    let title: String
    let remaining: Int
    let color: Color
    let disabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 3) {
                    Image(systemName: icon).font(.system(size: 19, weight: .bold))
                    Text(title).font(.system(size: 8, weight: .heavy, design: .rounded))
                }
                .foregroundStyle(color)
                .frame(width: 56, height: 54)
                .background(GameColors.background.opacity(0.82), in: RoundedRectangle(cornerRadius: 15))
                .overlay { RoundedRectangle(cornerRadius: 15).stroke(color.opacity(0.65), lineWidth: 1.5) }

                Text("\(remaining)")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(width: 20, height: 20)
                    .background(color, in: Circle())
                    .offset(x: 5, y: -5)
            }
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.38 : 1)
        .accessibilityLabel("\(title), \(remaining) hak kaldı")
    }
}
