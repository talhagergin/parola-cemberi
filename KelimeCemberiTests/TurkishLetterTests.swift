import XCTest
@testable import KelimeCemberi

final class TurkishLetterTests: XCTestCase {
    func testAlphabetHasCorrectOrderAndCount() {
        XCTAssertEqual(TurkishLetter.allCases.count, 29)
        XCTAssertEqual(TurkishLetter.allCases.map(\.rawValue).joined(), "ABCÇDEFGĞHIİJKLMNOÖPRSŞTUÜVYZ")
    }

    func testTurkishInitialLetterDerivation() {
        XCTAssertEqual(TurkishLetter.initialLetter(in: "  istanbul"), .iDotted)
        XCTAssertEqual(TurkishLetter.initialLetter(in: "ışık"), .iDotless)
        XCTAssertEqual(TurkishLetter.initialLetter(in: "'çember"), .cCedilla)
    }
}
