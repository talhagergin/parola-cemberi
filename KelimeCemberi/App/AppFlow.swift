import Foundation

enum AppFlow {
    case splash
    case onboarding
    case mainMenu
    case modeSelection
    case categorySelection
    case statistics
    case settings
    case avatarSelection
    case store
    case languageSelection
    case levelSelection(LearningLanguage)
    case languageLesson(LearningLanguage, CEFRLevel, [LanguageLearningQuestion])
    case game(GameLaunchRequest)
    case results(GameSession, GameLaunchRequest, Int)
}
