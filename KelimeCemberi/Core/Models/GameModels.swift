import Foundation

enum LetterStatus: String, Codable, Sendable {
    case waiting, active, correct, wrong, passed, unavailable
}

enum GamePhase: String, Codable, Sendable {
    case ready, running, paused, finished
}

enum GameEndReason: String, Codable, Sendable {
    case completed, timeExpired, cancelled
}

struct LetterState: Identifiable, Hashable, Sendable {
    var id: TurkishLetter { letter }
    let letter: TurkishLetter
    let question: Question?
    var status: LetterStatus
    var passCount: Int
    var hintUsed: Bool
    var submittedAnswer: String?
    var awardedPoints: Int

    init(letter: TurkishLetter, question: Question?) {
        self.letter = letter
        self.question = question
        status = question == nil ? .unavailable : .waiting
        passCount = 0
        hintUsed = false
        submittedAnswer = nil
        awardedPoints = 0
    }
}

struct GameConfiguration: Hashable, Sendable {
    let letters: [TurkishLetter]
    let durationSeconds: Int
    let maximumPassCount: Int

    static let classic = GameConfiguration(
        letters: TurkishLetter.allCases,
        durationSeconds: 120,
        maximumPassCount: 2
    )

    init(letters: [TurkishLetter], durationSeconds: Int, maximumPassCount: Int) {
        precondition(durationSeconds > 0)
        precondition(maximumPassCount >= 0)
        self.letters = letters
        self.durationSeconds = durationSeconds
        self.maximumPassCount = maximumPassCount
    }
}

struct GameSession: Sendable {
    let id: UUID
    let configuration: GameConfiguration
    var phase: GamePhase
    var endReason: GameEndReason?
    var letters: [LetterState]
    var currentIndex: Int?
    var remainingSeconds: Int
    var score: Int
    var streak: Int
    var longestStreak: Int
    var hintsUsed: Int
    var startedAt: Date?
    var finishedAt: Date?

    init(id: UUID = UUID(), configuration: GameConfiguration, questions: [TurkishLetter: Question]) {
        self.id = id
        self.configuration = configuration
        phase = .ready
        endReason = nil
        letters = configuration.letters.map { LetterState(letter: $0, question: questions[$0]) }
        currentIndex = nil
        remainingSeconds = configuration.durationSeconds
        score = 0
        streak = 0
        longestStreak = 0
        hintsUsed = 0
        startedAt = nil
        finishedAt = nil
    }
}
