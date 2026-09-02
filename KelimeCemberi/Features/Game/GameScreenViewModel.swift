import Foundation
import Observation

@MainActor
@Observable
final class GameScreenViewModel {
    enum LoadState: Equatable { case loading, ready, failed(String) }
    enum Feedback: Equatable { case correct, wrong, passed, skipped }

    private(set) var loadState: LoadState = .loading
    private(set) var engine: GameEngine?
    private(set) var feedback: Feedback?
    var answerText = ""

    private let request: GameLaunchRequest
    private let recentQuestionIDs: Set<UUID>
    private let selector: QuestionSelector
    private var timer: CountdownTimer?
    private var timerTask: Task<Void, Never>?
    private var feedbackTask: Task<Void, Never>?

    init(
        request: GameLaunchRequest = GameLaunchRequest(mode: .classic),
        recentQuestionIDs: Set<UUID> = [],
        repository: any QuestionRepository = LocalQuestionRepository()
    ) {
        self.request = request
        self.recentQuestionIDs = recentQuestionIDs
        selector = QuestionSelector(repository: repository)
    }

    var session: GameSession? { engine?.session }
    var activeQuestion: Question? { engine?.activeLetterState?.question }
    var activeLetter: TurkishLetter? { engine?.activeLetterState?.letter }
    var isPaused: Bool { session?.phase == .paused }
    var isFinished: Bool { session?.phase == .finished }
    var canSubmit: Bool {
        session?.phase == .running && !answerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && engine?.isProcessingAction == false
    }

    func prepare() async {
        timerTask?.cancel()
        await timer?.stop()
        loadState = .loading
        do {
            let configuration = request.configuration
            let selected = try await selector.selectQuestions(
                for: configuration.letters,
                category: request.category,
                excluding: request.mode == .daily ? [] : recentQuestionIDs,
                deterministicSeed: request.dailySeed
            )
            let session = GameSession(configuration: configuration, questions: selected)
            let engine = GameEngine(session: session, scoringConfiguration: request.mode.scoringConfiguration)
            self.engine = engine
            engine.start()
            let timer = CountdownTimer(durationSeconds: configuration.durationSeconds)
            self.timer = timer
            let stream = await timer.ticks()
            let initialDuration = configuration.durationSeconds
            timerTask = Task { [weak self] in
                var previous = initialDuration
                for await remaining in stream {
                    guard let self, !Task.isCancelled else { return }
                    if remaining < previous { self.engine?.advanceTime(by: previous - remaining) }
                    previous = remaining
                    if self.engine?.session.phase == .finished { return }
                }
            }
            await timer.start()
            loadState = .ready
        } catch {
            loadState = .failed((error as? LocalizedError)?.errorDescription ?? "Oyun hazırlanamadı.")
        }
    }

    func submit() async {
        guard let engine, canSubmit, let index = engine.session.currentIndex else { return }
        do {
            try await engine.submitAnswer(answerText)
            showFeedback(engine.session.letters[index].status == .correct ? .correct : .wrong)
            answerText = ""
            await stopTimerIfFinished()
        } catch { loadState = .failed(error.localizedDescription) }
    }

    func pass() async {
        guard let engine else { return }
        do {
            try engine.pass()
            answerText = ""
            showFeedback(.passed)
            await stopTimerIfFinished()
        } catch { loadState = .failed(error.localizedDescription) }
    }

    func skip() async {
        guard let engine else { return }
        do {
            try engine.skip()
            answerText = ""
            showFeedback(.skipped)
            await stopTimerIfFinished()
        } catch { loadState = .failed(error.localizedDescription) }
    }

    func useHint() {
        do { _ = try engine?.useHint() }
        catch { loadState = .failed(error.localizedDescription) }
    }

    func pause() async {
        engine?.pause()
        await timer?.pause()
    }

    func resume() async {
        engine?.resume()
        await timer?.resume()
    }

    func pauseForBackground() async {
        guard session?.phase == .running else { return }
        await pause()
    }

    func exitGame() async {
        engine?.cancel()
        timerTask?.cancel()
        await timer?.stop()
    }

    private func stopTimerIfFinished() async {
        if isFinished { await timer?.stop() }
    }

    private func showFeedback(_ value: Feedback) {
        feedbackTask?.cancel()
        feedback = value
        feedbackTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(520))
            guard !Task.isCancelled else { return }
            self?.feedback = nil
        }
    }
}
