import XCTest
import SwiftData
@testable import KelimeCemberi

@MainActor
final class PersistenceStoreTests: XCTestCase {
    func testFinishedSessionUpdatesProfileAndBreakdownsOnlyOnce() throws {
        let store = try makeStore()
        let questions: [TurkishLetter: Question] = [
            .a: TestFixtures.question(letter: .a),
            .b: TestFixtures.question(letter: .b)
        ]
        var session = GameSession(
            configuration: GameConfiguration(letters: [.a, .b], durationSeconds: 60, maximumPassCount: 1),
            questions: questions
        )
        session.phase = .finished
        session.score = 140
        session.longestStreak = 2
        session.hintsUsed = 1
        session.letters[0].status = .correct
        session.letters[0].awardedPoints = 140
        session.letters[1].status = .wrong
        let request = GameLaunchRequest(mode: .classic)

        store.record(session: session, request: request)
        store.record(session: session, request: request)

        XCTAssertEqual(store.snapshot.totalGames, 1)
        XCTAssertEqual(store.snapshot.totalCorrect, 1)
        XCTAssertEqual(store.snapshot.totalWrong, 1)
        XCTAssertEqual(store.snapshot.highScore, 140)
        XCTAssertEqual(store.snapshot.letters.count, 2)
        XCTAssertEqual(store.snapshot.categories.first?.attempts, 2)
    }

    func testResetProgressPreservesSettings() throws {
        let store = try makeStore()
        store.settings.musicEnabled = false
        store.settings.selectedAvatar = .owl
        store.saveSettings()
        store.resetProgress()

        XCTAssertFalse(store.settings.musicEnabled)
        XCTAssertEqual(store.settings.selectedAvatar, .owl)
        XCTAssertEqual(store.snapshot.totalGames, 0)
    }

    func testGameEconomyRewardsOnceAndUnlocksProducts() throws {
        let store = try makeStore()
        var session = GameSession(configuration: GameConfiguration(letters: [.a], durationSeconds: 60, maximumPassCount: 1), questions: [.a: TestFixtures.question(letter: .a)])
        session.phase = .finished
        session.letters[0].status = .correct
        let request = GameLaunchRequest(mode: .classic)

        XCTAssertEqual(store.record(session: session, request: request), 20)
        XCTAssertEqual(store.record(session: session, request: request), 0)
        XCTAssertEqual(store.settings.coinBalance, 270)
        store.settings.coinBalance = 2_000
        XCTAssertTrue(store.purchase(PlayerAvatar.fox))
        XCTAssertTrue(store.settings.owns(PlayerAvatar.fox))
        XCTAssertEqual(store.settings.selectedAvatar, .fox)
        XCTAssertTrue(store.purchase(CircleTheme.sunset))
        XCTAssertTrue(store.settings.owns(CircleTheme.sunset))
        XCTAssertEqual(store.settings.selectedCircleTheme, .sunset)
    }

    func testInterstitialMilestoneOccursEveryThirdCompletedRound() throws {
        let store = try makeStore()
        store.settings.completedRoundsSinceAd = 2
        store.settings.completedRoundsSinceAd += 1
        XCTAssertTrue(store.consumeInterstitialMilestone())
        XCTAssertEqual(store.settings.completedRoundsSinceAd, 0)
        XCTAssertFalse(store.consumeInterstitialMilestone())
    }

    func testDailyStreakCountsTodayAndPreviousDays() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: now)!

        XCTAssertEqual(PersistenceStore.dailyStreak(from: [now, yesterday, twoDaysAgo], calendar: calendar, now: now), 3)
        XCTAssertEqual(PersistenceStore.dailyStreak(from: [twoDaysAgo], calendar: calendar, now: now), 0)
    }

    func testOnlyFirstDailyCompletionIsRecordedForSameDay() throws {
        let store = try makeStore()
        let question = TestFixtures.question(letter: .a)
        var first = GameSession(configuration: GameConfiguration(letters: [.a], durationSeconds: 60, maximumPassCount: 1), questions: [.a: question])
        first.phase = .finished
        first.letters[0].status = .correct
        var second = GameSession(configuration: first.configuration, questions: [.a: question])
        second.phase = .finished
        second.letters[0].status = .correct
        let request = GameLaunchRequest(mode: .daily)

        store.record(session: first, request: request)
        store.record(session: second, request: request)

        XCTAssertTrue(store.isDailyCompleted(dayKey: request.dailyDayKey!))
        XCTAssertEqual(store.dailyCompletionCount(), 1)
    }

    private func makeStore() throws -> PersistenceStore {
        let configuration = ModelConfiguration(schema: PersistenceContainer.schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: PersistenceContainer.schema, configurations: [configuration])
        return PersistenceStore(context: container.mainContext)
    }
}
