import XCTest
@testable import KelimeCemberi

final class ScoreCalculatorTests: XCTestCase {
    private let calculator = ScoreCalculator()

    func testStandardAndHintedAwards() {
        XCTAssertEqual(calculator.award(hintUsed: false, streak: 1, passCount: 0).total, 100)
        XCTAssertEqual(calculator.award(hintUsed: true, streak: 1, passCount: 0).total, 60)
    }

    func testStreakAndRevisitBonuses() {
        XCTAssertEqual(calculator.award(hintUsed: false, streak: 3, passCount: 0).total, 125)
        XCTAssertEqual(calculator.award(hintUsed: false, streak: 2, passCount: 1).total, 80)
    }

    func testRemainingTimeBonus() {
        XCTAssertEqual(calculator.timeBonus(remainingSeconds: 12), 24)
        XCTAssertEqual(calculator.timeBonus(remainingSeconds: -1), 0)
    }
}
