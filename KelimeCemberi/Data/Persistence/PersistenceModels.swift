import Foundation
import SwiftData

@Model
final class PlayerProfile {
    @Attribute(.unique) var profileKey: String
    var createdAt: Date
    var totalGames: Int
    var totalCorrect: Int
    var totalWrong: Int
    var totalPassed: Int
    var totalHints: Int
    var highScore: Int
    var longestStreak: Int

    init(profileKey: String = "local-player") {
        self.profileKey = profileKey
        createdAt = .now
        totalGames = 0
        totalCorrect = 0
        totalWrong = 0
        totalPassed = 0
        totalHints = 0
        highScore = 0
        longestStreak = 0
    }
}

@Model
final class GameSessionRecord {
    @Attribute(.unique) var sessionID: UUID
    var playedAt: Date
    var modeRawValue: String
    var category: String?
    var score: Int
    var correctCount: Int
    var wrongCount: Int
    var passedCount: Int
    var hintsUsed: Int
    var longestStreak: Int
    var durationSeconds: Int
    var endReasonRawValue: String
    var questionIDs: [String]

    init(session: GameSession, request: GameLaunchRequest) {
        sessionID = session.id
        playedAt = session.finishedAt ?? .now
        modeRawValue = request.mode.rawValue
        category = request.category
        score = session.score
        correctCount = session.letters.count { $0.status == .correct }
        wrongCount = session.letters.count { $0.status == .wrong }
        passedCount = session.letters.count { $0.status == .passed }
        hintsUsed = session.hintsUsed
        longestStreak = session.longestStreak
        durationSeconds = max(0, session.configuration.durationSeconds - session.remainingSeconds)
        endReasonRawValue = session.endReason?.rawValue ?? GameEndReason.cancelled.rawValue
        questionIDs = session.letters.compactMap { $0.question?.id.uuidString }
    }
}

@Model
final class LetterPerformanceRecord {
    @Attribute(.unique) var letterRawValue: String
    var attempts: Int
    var correct: Int
    var wrong: Int
    var passed: Int

    init(letter: TurkishLetter) {
        letterRawValue = letter.rawValue
        attempts = 0
        correct = 0
        wrong = 0
        passed = 0
    }
}

@Model
final class CategoryPerformanceRecord {
    @Attribute(.unique) var category: String
    var attempts: Int
    var correct: Int
    var wrong: Int
    var passed: Int
    var totalScore: Int

    init(category: String) {
        self.category = category
        attempts = 0
        correct = 0
        wrong = 0
        passed = 0
        totalScore = 0
    }
}

@Model
final class DailyChallengeRecord {
    @Attribute(.unique) var dayKey: String
    var completedAt: Date
    var score: Int
    var sessionID: UUID

    init(dayKey: String, completedAt: Date, score: Int, sessionID: UUID) {
        self.dayKey = dayKey
        self.completedAt = completedAt
        self.score = score
        self.sessionID = sessionID
    }
}

enum AppThemePreference: String, CaseIterable, Identifiable {
    case system, midnight, violet
    var id: String { rawValue }
    var title: String {
        switch self { case .system: "Sistem"; case .midnight: "Gece"; case .violet: "Mor" }
    }
}

@Model
final class AppSettings {
    @Attribute(.unique) var settingsKey: String
    var musicEnabled: Bool
    var soundEffectsEnabled: Bool
    var hapticsEnabled: Bool
    var reduceMotion: Bool
    var themeRawValue: String
    var questionTextScale: Double
    var onboardingCompleted: Bool
    var selectedAvatarRawValue: String?
    var coinBalanceValue: Int?
    var ownedAvatarRawValues: [String]?
    var selectedCircleThemeRawValue: String?
    var ownedCircleThemeRawValues: [String]?
    var completedRoundsSinceAdValue: Int?
    var completedA1RoundsSinceAdValue: Int?
    var completedOtherLanguageRoundsSinceAdValue: Int?

    init(settingsKey: String = "default") {
        self.settingsKey = settingsKey
        musicEnabled = true
        soundEffectsEnabled = true
        hapticsEnabled = true
        reduceMotion = false
        themeRawValue = AppThemePreference.system.rawValue
        questionTextScale = 1
        onboardingCompleted = false
        selectedAvatarRawValue = PlayerAvatar.robot.rawValue
        coinBalanceValue = 250
        ownedAvatarRawValues = [PlayerAvatar.robot.rawValue]
        selectedCircleThemeRawValue = CircleTheme.classic.rawValue
        ownedCircleThemeRawValues = [CircleTheme.classic.rawValue]
        completedRoundsSinceAdValue = 0
        completedA1RoundsSinceAdValue = 0
        completedOtherLanguageRoundsSinceAdValue = 0
    }

    var theme: AppThemePreference {
        get { AppThemePreference(rawValue: themeRawValue) ?? .system }
        set { themeRawValue = newValue.rawValue }
    }

    var selectedAvatar: PlayerAvatar {
        get { PlayerAvatar(rawValue: selectedAvatarRawValue ?? "") ?? .robot }
        set { selectedAvatarRawValue = newValue.rawValue }
    }

    var coinBalance: Int {
        get { coinBalanceValue ?? 250 }
        set { coinBalanceValue = max(0, newValue) }
    }
    var selectedCircleTheme: CircleTheme {
        get { CircleTheme(rawValue: selectedCircleThemeRawValue ?? "") ?? .classic }
        set { selectedCircleThemeRawValue = newValue.rawValue }
    }
    var completedRoundsSinceAd: Int {
        get { completedRoundsSinceAdValue ?? 0 }
        set { completedRoundsSinceAdValue = max(0, newValue) }
    }
    var completedA1RoundsSinceAd: Int {
        get { completedA1RoundsSinceAdValue ?? 0 }
        set { completedA1RoundsSinceAdValue = max(0, newValue) }
    }
    var completedOtherLanguageRoundsSinceAd: Int {
        get { completedOtherLanguageRoundsSinceAdValue ?? 0 }
        set { completedOtherLanguageRoundsSinceAdValue = max(0, newValue) }
    }
    func owns(_ avatar: PlayerAvatar) -> Bool { (ownedAvatarRawValues ?? [PlayerAvatar.robot.rawValue]).contains(avatar.rawValue) }
    func owns(_ theme: CircleTheme) -> Bool { (ownedCircleThemeRawValues ?? [CircleTheme.classic.rawValue]).contains(theme.rawValue) }
}
