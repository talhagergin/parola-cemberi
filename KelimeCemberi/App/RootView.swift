import SwiftUI

struct RootView: View {
    @State private var model = AppViewModel()
    @State private var persistence: PersistenceStore
    @State private var premium: PremiumStore
    @State private var flow: AppFlow = .splash

    init(persistence: PersistenceStore) {
        if UserDefaults.standard.bool(forKey: "onboardingCompleted"), !persistence.settings.onboardingCompleted {
            persistence.settings.onboardingCompleted = true
            persistence.saveSettings()
        }
        _persistence = State(initialValue: persistence)
        _premium = State(initialValue: PremiumStore())
    }

    var body: some View {
        Group {
            switch model.state {
            case .loading:
                SplashView()
            case .failed(let message):
                ZStack {
                    GameBackground()
                    ContentUnavailableView("Sorular yüklenemedi", systemImage: "exclamationmark.triangle", description: Text(message))
                        .foregroundStyle(.white)
                }
            case .ready(let report):
                destination(report: report)
            }
        }
        .task { await model.prepare() }
        .animation(.easeInOut(duration: 0.28), value: routeAnimationKey)
    }

    @ViewBuilder
    private func destination(report: QuestionValidationReport) -> some View {
        switch flow {
        case .splash:
            SplashView().onAppear { flow = persistence.settings.onboardingCompleted ? .mainMenu : .onboarding }
        case .onboarding:
            OnboardingView {
                persistence.settings.onboardingCompleted = true
                persistence.saveSettings()
                flow = .mainMenu
            }
        case .mainMenu:
            MainMenuView(
                questionCount: report.validQuestions.count,
                dailyCompleted: persistence.isDailyCompleted(),
                avatar: persistence.settings.selectedAvatar,
                isPremium: premium.isPremium,
                coinBalance: persistence.settings.coinBalance,
                onPlay: { flow = .modeSelection },
                onQuickPlay: { flow = .game(GameLaunchRequest(mode: .quick)) },
                onDailyPlay: {
                    if !persistence.isDailyCompleted() { flow = .game(GameLaunchRequest(mode: .daily)) }
                },
                onStatistics: { persistence.refresh(); flow = .statistics },
                onSettings: { flow = .settings },
                onAvatar: { flow = .avatarSelection },
                onPremium: { flow = .premium },
                onStore: { flow = .store },
                onLanguageLearning: { flow = .languageSelection }
            )
        case .modeSelection:
            ModeSelectionView(dailyCompleted: persistence.isDailyCompleted(), onBack: { flow = .mainMenu }) { mode in
                flow = mode == .category ? .categorySelection : .game(GameLaunchRequest(mode: mode))
            }
        case .categorySelection:
            CategorySelectionView(
                categories: report.categoryDistribution,
                onBack: { flow = .modeSelection },
                onSelect: { flow = .game(GameLaunchRequest(mode: .category, category: $0)) }
            )
        case .statistics:
            StatisticsView(snapshot: persistence.snapshot, onBack: { flow = .mainMenu })
        case .settings:
            SettingsView(
                settings: persistence.settings,
                errorMessage: persistence.lastErrorMessage,
                onSave: persistence.saveSettings,
                onReplayOnboarding: {
                    persistence.settings.onboardingCompleted = false
                    persistence.saveSettings()
                    flow = .onboarding
                },
                onResetProgress: persistence.resetProgress,
                onBack: { flow = .mainMenu }
            )
        case .avatarSelection:
            AvatarPickerView(settings: persistence.settings, onSelect: persistence.select, onStore: { flow = .store }, onBack: { flow = .mainMenu })
        case .premium:
            PremiumView(store: premium, onBack: { flow = .mainMenu })
        case .store:
            GameStoreView(settings: persistence.settings,
                          buyAvatar: persistence.purchase,
                          buyTheme: persistence.purchase,
                          selectAvatar: persistence.select,
                          selectTheme: persistence.select,
                          onBack: { flow = .mainMenu })
        case .languageSelection:
            LanguageSelectionView(onBack: { flow = .mainMenu }, onSelect: { flow = .levelSelection($0) })
        case .levelSelection(let language):
            LevelSelectionView(language: language, onBack: { flow = .languageSelection }) { level, questions in
                flow = .languageLesson(language, level, questions)
            }
        case .languageLesson(let language, let level, let questions):
            LanguageLessonView(language: language, level: level, sourceQuestions: questions, onExit: { flow = .levelSelection(language) })
        case .game(let request):
            GameScreen(request: request, questionTextScale: persistence.settings.questionTextScale, reduceMotionOverride: persistence.settings.reduceMotion, recentQuestionIDs: persistence.recentQuestionIDs(), soundEffectsEnabled: persistence.settings.soundEffectsEnabled, circleTheme: persistence.settings.selectedCircleTheme, onFinished: { session in
                let earnedCoins = persistence.record(session: session, request: request)
                let shouldShowAd = !premium.isPremium && persistence.consumeInterstitialMilestone()
                Task { @MainActor in
                    if shouldShowAd {
                        await AdService.shared.prepare()
                        await AdService.shared.showInterstitial()
                    }
                    flow = .results(session, request, earnedCoins)
                }
            }, onExit: { flow = .mainMenu })
        case .results(let session, let request, let earnedCoins):
            ResultsView(session: session, mode: request.mode, earnedCoins: earnedCoins,
                        onReplay: { flow = .game(request) },
                        onMenu: { flow = .mainMenu })
        }
    }

    private var routeAnimationKey: String {
        switch flow {
        case .splash: "splash"; case .onboarding: "onboarding"; case .mainMenu: "menu"
        case .modeSelection: "modes"; case .categorySelection: "categories"
        case .statistics: "statistics"; case .settings: "settings"
        case .avatarSelection: "avatar"
        case .premium: "premium"
        case .store: "store"
        case .languageSelection: "languages"
        case .levelSelection: "levels"
        case .languageLesson: "lesson"
        case .game: "game"; case .results: "results"
        }
    }
}
