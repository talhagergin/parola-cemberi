import Foundation

actor CountdownTimer {
    enum State: Sendable { case idle, running, paused, finished }

    private(set) var remainingSeconds: Int
    private(set) var state: State = .idle
    private let durationSeconds: Int
    private var task: Task<Void, Never>?
    private var continuation: AsyncStream<Int>.Continuation?

    init(durationSeconds: Int) {
        precondition(durationSeconds > 0)
        self.durationSeconds = durationSeconds
        remainingSeconds = durationSeconds
    }

    func ticks() -> AsyncStream<Int> {
        AsyncStream { continuation in
            self.continuation = continuation
            continuation.yield(remainingSeconds)
        }
    }

    func start() {
        stopTask()
        remainingSeconds = durationSeconds
        state = .running
        continuation?.yield(remainingSeconds)
        schedule()
    }

    func pause() {
        guard state == .running else { return }
        state = .paused
        stopTask()
    }

    func resume() {
        guard state == .paused, remainingSeconds > 0 else { return }
        state = .running
        schedule()
    }

    func stop() {
        stopTask()
        state = .idle
        remainingSeconds = durationSeconds
    }

    /// Deterministic entry point used by the engine and unit tests.
    func advanceOneSecond() {
        guard state == .running else { return }
        remainingSeconds = max(0, remainingSeconds - 1)
        continuation?.yield(remainingSeconds)
        if remainingSeconds == 0 {
            state = .finished
            stopTask()
            continuation?.finish()
        }
    }

    private func schedule() {
        task = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                await self?.advanceOneSecond()
            }
        }
    }

    private func stopTask() {
        task?.cancel()
        task = nil
    }
}
