import XCTest
@testable import KelimeCemberi

final class AnswerValidatorTests: XCTestCase {
    private let validator = AnswerValidator()

    func testTurkishCaseWhitespaceAndFinalPunctuation() {
        let question = TestFixtures.question(letter: .d, answer: "DİZ")
        XCTAssertTrue(validator.isCorrect("  diz.  ", for: question))
        XCTAssertTrue(validator.isCorrect("DİZ", for: question))
    }

    func testDotlessAndDottedIAreNotMerged() {
        let question = TestFixtures.question(letter: .s, answer: "SIS")
        XCTAssertTrue(validator.isCorrect("sıs", for: question))
        XCTAssertFalse(validator.isCorrect("sis", for: question))
    }

    func testTurkishCharactersArePreserved() {
        let question = TestFixtures.question(letter: .sCedilla, answer: "ŞİŞ")
        XCTAssertFalse(validator.isCorrect("SIS", for: question))
        XCTAssertTrue(validator.isCorrect("şiş!", for: question))
    }

    func testSpacesApostrophesAndAlternativeAnswers() {
        let question = TestFixtures.question(
            letter: .t, answer: "TÜRKİYE BÜYÜK MİLLET MECLİSİ", acceptedAnswers: ["TBMM"]
        )
        XCTAssertTrue(validator.isCorrect("Türkiye   Büyük Millet Meclisi", for: question))
        XCTAssertTrue(validator.isCorrect("tbmm", for: question))
    }
}
