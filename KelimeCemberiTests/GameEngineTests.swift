import XCTest
@testable import KelimeCemberi

@MainActor
final class GameEngineTests: XCTestCase {
    func testCorrectAnswerScoresAndAdvances() async throws {
        let engine = TestFixtures.engine(letters: [.a, .b])
        engine.start()
        try await engine.submitAnswer("akelime")
        XCTAssertEqual(engine.session.letters[0].status, .correct)
        XCTAssertEqual(engine.session.score, 100)
        XCTAssertEqual(engine.activeLetterState?.letter, .b)
    }

    func testWrongAnswerResetsStreakAndAdvances() async throws {
        let engine = TestFixtures.engine(letters: [.a, .b, .c])
        engine.start()
        try await engine.submitAnswer("AKELİME")
        try await engine.submitAnswer("yanlış")
        XCTAssertEqual(engine.session.letters[1].status, .wrong)
        XCTAssertEqual(engine.session.streak, 0)
        XCTAssertEqual(engine.activeLetterState?.letter, .c)
    }

    func testPassedQuestionReturnsAfterFirstPass() async throws {
        let engine = TestFixtures.engine(letters: [.a, .b])
        engine.start()
        try engine.pass()
        XCTAssertEqual(engine.activeLetterState?.letter, .b)
        try await engine.submitAnswer("BKELİME")
        XCTAssertEqual(engine.activeLetterState?.letter, .a)
        XCTAssertEqual(engine.session.letters[0].passCount, 1)
    }

    func testMaximumPassCountEndsQuestion() throws {
        let engine = TestFixtures.engine(letters: [.a], maximumPassCount: 2)
        engine.start()
        try engine.pass()
        XCTAssertEqual(engine.activeLetterState?.letter, .a)
        try engine.pass()
        XCTAssertEqual(engine.session.phase, .finished)
        XCTAssertEqual(engine.session.letters[0].status, .passed)
    }

    func testTimeExpiryFinishesRound() {
        let engine = TestFixtures.engine(duration: 2)
        engine.start()
        engine.advanceTime(by: 2)
        XCTAssertEqual(engine.session.phase, .finished)
        XCTAssertEqual(engine.session.endReason, .timeExpired)
    }

    func testPauseFreezesEngineTime() {
        let engine = TestFixtures.engine(duration: 10)
        engine.start()
        engine.pause()
        engine.advanceTime(by: 5)
        XCTAssertEqual(engine.session.remainingSeconds, 10)
        engine.resume()
        engine.advanceTime(by: 1)
        XCTAssertEqual(engine.session.remainingSeconds, 9)
    }

    func testAllCompletedFinishesWithoutWaitingForTimer() async throws {
        let engine = TestFixtures.engine(letters: [.a])
        engine.start()
        try await engine.submitAnswer("AKELİME")
        XCTAssertEqual(engine.session.phase, .finished)
        XCTAssertEqual(engine.session.endReason, .completed)
        XCTAssertEqual(engine.session.score, 340) // 100 answer + 120 * 2 time bonus
    }

    func testHintIsChargedOnlyOnce() throws {
        let engine = TestFixtures.engine(letters: [.a])
        engine.start()
        _ = try engine.useHint()
        _ = try engine.useHint()
        XCTAssertEqual(engine.session.hintsUsed, 1)
    }

    func testConcurrentSubmissionsAreRejected() async throws {
        let engine = TestFixtures.engine(letters: [.a, .b])
        engine.start()
        async let first = Self.submissionSucceeded(engine, answer: "AKELİME")
        async let second = Self.submissionSucceeded(engine, answer: "AKELİME")
        let results = await [first, second]
        XCTAssertEqual(results.filter(\.self).count, 1)
    }

    private static func submissionSucceeded(_ engine: GameEngine, answer: String) async -> Bool {
        do { try await engine.submitAnswer(answer); return true }
        catch { return false }
    }
}
