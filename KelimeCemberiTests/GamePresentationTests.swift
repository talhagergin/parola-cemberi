import XCTest
@testable import KelimeCemberi

final class GamePresentationTests: XCTestCase {
    func testClockFormatting() {
        XCTAssertEqual(120.gameClockText, "02:00")
        XCTAssertEqual(9.gameClockText, "00:09")
        XCTAssertEqual((-4).gameClockText, "00:00")
    }

    func testEveryStatusHasDistinctAccessibilityText() {
        let labels = [LetterStatus.waiting, .active, .correct, .wrong, .passed, .unavailable]
            .map(\.accessibilityDescription)
        XCTAssertEqual(Set(labels).count, 6)
    }
}
