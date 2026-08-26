import Foundation
import Observation

enum GameEngineError: LocalizedError, Equatable {
    case invalidPhase
    case noActiveQuestion
    case emptyAnswer
    case actionInProgress

    var errorDescription: String? {
        switch self {
        case .invalidPhase: "Oyun şu anda bu işlem için hazır değil."
        case .noActiveQuestion: "Aktif bir soru bulunmuyor."
        case .emptyAnswer: "Lütfen bir cevap yazın."
        case .actionInProgress: "Önceki cevap işleniyor."
        }
    }
}

@MainActor
@Observable
final class GameEngine {
    private(set) var session: GameSession
    private(set) var isProcessingAction = false

    private let validator: AnswerValidator
    private let scoreCalculator: ScoreCalculator
    private var firstPassQueue: [Int] = []
    private var revisitQueue: [Int] = []
    private var didApplyTimeBonus = false

    init(
        session: GameSession,
        validator: AnswerValidator = AnswerValidator(),
        scoringConfiguration: ScoringConfiguration = .standard
    ) {
        self.session = session
        self.validator = validator
        scoreCalculator = ScoreCalculator(configuration: scoringConfiguration)
    }

    var activeLetterState: LetterState? {
        session.currentIndex.map { session.letters[$0] }
    }

    func start(at date: Date = .now) {
        guard session.phase == .ready else { return }
        session.phase = .running
        session.startedAt = date
        firstPassQueue = session.letters.indices.filter { session.letters[$0].question != nil }
        moveToNextQuestion()
    }

    func submitAnswer(_ answer: String) async throws {
        guard session.phase == .running else { throw GameEngineError.invalidPhase }
        guard !isProcessingAction else { throw GameEngineError.actionInProgress }
        guard !answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw GameEngineError.emptyAnswer
        }
        guard let index = session.currentIndex, let question = session.letters[index].question else {
            throw GameEngineError.noActiveQuestion
        }

        isProcessingAction = true
        defer { isProcessingAction = false }
        await Task.yield()

        session.letters[index].submittedAnswer = answer
        if validator.isCorrect(answer, for: question) {
            session.streak += 1
            session.longestStreak = max(session.longestStreak, session.streak)
            let award = scoreCalculator.award(
                hintUsed: session.letters[index].hintUsed,
                streak: session.streak,
                passCount: session.letters[index].passCount
            )
            session.letters[index].status = .correct
            session.letters[index].awardedPoints = award.total
            session.score += award.total
        } else {
            session.letters[index].status = .wrong
            session.streak = 0
        }
        moveToNextQuestion()
    }

    func pass() throws {
        guard session.phase == .running else { throw GameEngineError.invalidPhase }
        guard !isProcessingAction else { throw GameEngineError.actionInProgress }
        guard let index = session.currentIndex, session.letters[index].question != nil else {
            throw GameEngineError.noActiveQuestion
        }

        session.letters[index].passCount += 1
        session.letters[index].status = .passed
        if session.letters[index].passCount < session.configuration.maximumPassCount {
            revisitQueue.append(index)
        }
        moveToNextQuestion()
    }

    @discardableResult
    func useHint() throws -> String? {
        guard session.phase == .running else { throw GameEngineError.invalidPhase }
        guard let index = session.currentIndex, let question = session.letters[index].question else {
            throw GameEngineError.noActiveQuestion
        }
        guard !session.letters[index].hintUsed else { return question.extendedClue }
        session.letters[index].hintUsed = true
        session.hintsUsed += 1
        return question.extendedClue
    }

    func pause() {
        guard session.phase == .running else { return }
        session.phase = .paused
    }

    func resume() {
        guard session.phase == .paused else { return }
        session.phase = .running
    }

    func advanceTime(by seconds: Int) {
        guard session.phase == .running, seconds > 0 else { return }
        session.remainingSeconds = max(0, session.remainingSeconds - seconds)
        if session.remainingSeconds == 0 { finish(reason: .timeExpired) }
    }

    func cancel(at date: Date = .now) {
        guard session.phase != .finished else { return }
        finish(reason: .cancelled, at: date)
    }

    private func moveToNextQuestion() {
        guard session.phase == .running else { return }
        session.currentIndex = nil

        while !firstPassQueue.isEmpty {
            let next = firstPassQueue.removeFirst()
            if session.letters[next].status == .waiting {
                activate(index: next)
                return
            }
        }
        while !revisitQueue.isEmpty {
            let next = revisitQueue.removeFirst()
            if session.letters[next].status == .passed {
                activate(index: next)
                return
            }
        }
        finish(reason: .completed)
    }

    private func activate(index: Int) {
        session.currentIndex = index
        session.letters[index].status = .active
    }

    private func finish(reason: GameEndReason, at date: Date = .now) {
        if let index = session.currentIndex, session.letters[index].status == .active {
            session.letters[index].status = .passed
        }
        if reason == .completed, !didApplyTimeBonus {
            session.score += scoreCalculator.timeBonus(remainingSeconds: session.remainingSeconds)
            didApplyTimeBonus = true
        }
        session.currentIndex = nil
        session.phase = .finished
        session.endReason = reason
        session.finishedAt = date
    }
}
