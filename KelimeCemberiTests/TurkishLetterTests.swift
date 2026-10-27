import XCTest
@testable import KelimeCemberi

final class TurkishLetterTests: XCTestCase {
    func testAlphabetHasCorrectOrderAndCount() {
        XCTAssertEqual(TurkishLetter.allCases.count, 28)
        XCTAssertEqual(TurkishLetter.allCases.map(\.rawValue).joined(), "ABCÇDEFGHIİJKLMNOÖPRSŞTUÜVYZ")
        XCTAssertFalse(GameConfiguration.classic.letters.contains(.gBreve))
        XCTAssertEqual(TurkishLetter(rawValue: "Ğ"), .gBreve)
    }

    func testTurkishInitialLetterDerivation() {
        XCTAssertEqual(TurkishLetter.initialLetter(in: "  istanbul"), .iDotted)
        XCTAssertEqual(TurkishLetter.initialLetter(in: "ışık"), .iDotless)
        XCTAssertEqual(TurkishLetter.initialLetter(in: "'çember"), .cCedilla)
    }
}
