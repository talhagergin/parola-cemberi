import XCTest
@testable import KelimeCemberi

final class GameModeTests: XCTestCase {
    func testClassicAndQuickConfigurations() {
        XCTAssertEqual(GameMode.classic.configuration.letters.count, 29)
        XCTAssertEqual(GameMode.classic.configuration.durationSeconds, 120)
        XCTAssertEqual(GameMode.quick.configuration.letters.count, 10)
        XCTAssertEqual(GameMode.quick.configuration.durationSeconds, 60)
    }

    func testAllSprintFiveModesAreAvailable() {
        XCTAssertTrue(GameMode.daily.isAvailable)
        XCTAssertTrue(GameMode.classic.isAvailable)
        XCTAssertTrue(GameMode.quick.isAvailable)
        XCTAssertTrue(GameMode.category.isAvailable)
    }

    func testModeSpecificScoringAndDailySeed() {
        XCTAssertEqual(GameMode.quick.scoringConfiguration.remainingSecondBonus, 3)
        XCTAssertEqual(GameMode.classic.scoringConfiguration.remainingSecondBonus, 2)
        let date = Date(timeIntervalSince1970: 1_800_000_000)
        let first = GameLaunchRequest(mode: .daily, date: date)
        let second = GameLaunchRequest(mode: .daily, date: date)
        let nextDay = GameLaunchRequest(mode: .daily, date: Calendar.turkey.date(byAdding: .day, value: 1, to: date)!)
        XCTAssertEqual(first.dailyDayKey, second.dailyDayKey)
        XCTAssertEqual(first.dailySeed, second.dailySeed)
        XCTAssertNotEqual(first.dailySeed, nextDay.dailySeed)
    }
}
