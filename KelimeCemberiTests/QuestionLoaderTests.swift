import XCTest
@testable import KelimeCemberi

final class QuestionLoaderTests: XCTestCase {
    func testFullQuestionPackageValidation() throws {
        let bundle = Bundle(for: Self.self)
        let url = try XCTUnwrap(bundle.url(forResource: "parola_cemberi_5000_soru", withExtension: "json"))
        let report = try QuestionLoader().load(from: url)
        XCTAssertEqual(report.totalRecords, 5_000)
        XCTAssertEqual(report.validQuestions.count, 5_000)
        XCTAssertTrue(report.invalidRecords.isEmpty)
        XCTAssertTrue(report.duplicateIDs.isEmpty)
        XCTAssertTrue(report.letterCountMismatches.isEmpty)
        XCTAssertTrue(report.missingLetters.isEmpty)
    }

    func testLanguageLearningPackagesHaveBalancedCEFRLevels() throws {
        for language in LearningLanguage.allCases {
            let questions = try LanguageQuestionLoader().load(language)
            let expectedTotal: Int = switch language {
            case .english: 3_612
            case .italian: 874
            case .german: 740
            case .spanish, .azerbaijani: 180
            case .dutch: 500
            }
            XCTAssertEqual(questions.count, expectedTotal, language.title)
            XCTAssertEqual(Set(questions.map(\.id)).count, expectedTotal, language.title)
            for level in CEFRLevel.allCases {
                let levelQuestions = questions.filter { $0.cefrLevel == level }
                XCTAssertGreaterThanOrEqual(levelQuestions.count, 30, "\(language.title) \(level.rawValue)")
                XCTAssertEqual(Set(levelQuestions.map { $0.answer.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: $0.locale)) }).count, levelQuestions.count, "\(language.title) \(level.rawValue) cevapları benzersiz olmalı")
                let roundAlphabet = language.roundAlphabet(for: levelQuestions)
                XCTAssertFalse(roundAlphabet.isEmpty)
                XCTAssertTrue(roundAlphabet.allSatisfy { letter in levelQuestions.contains { $0.initialLetter == letter } })
                XCTAssertFalse(roundAlphabet.contains("X"))
                XCTAssertFalse(roundAlphabet.contains("Ğ"))
            }
            XCTAssertTrue(questions.allSatisfy { $0.letterCount == $0.answer.filter(\.isLetter).count })
        }
    }

    func testLanguageAnswerMatchingUsesTargetLocaleAndIgnoresCase() throws {
        let english = try LanguageQuestionLoader().load(.english)
        let angry = try XCTUnwrap(english.first { $0.clue == "Sinirli" })
        XCTAssertTrue(angry.matches("angry"))
        XCTAssertFalse(angry.matches("sad"))
    }

    func testOnlyAlternatingCEFRLevelsAreUnlocked() {
        XCTAssertEqual(CEFRLevel.allCases.filter(\.isUnlocked), [.a1, .b1, .c1])
    }

    func testAzerbaijaniAndSpanishDistinctLettersAreNotMerged() {
        func question(_ answer: String, locale: String) -> LanguageLearningQuestion {
            LanguageLearningQuestion(id: UUID(), clue: "Test", extendedClue: nil, answer: answer,
                difficulty: 1, category: "Test", letterCount: answer.count,
                initialLetter: String(answer.prefix(1)), letterRule: "startsWith",
                sourceLanguage: "Turkish", targetLanguage: "Test", locale: locale, cefrLevel: .a1)
        }
        XCTAssertTrue(question("İŞIQ", locale: "az_AZ").matches("işıq"))
        XCTAssertFalse(question("İŞIQ", locale: "az_AZ").matches("isiq"))
        XCTAssertFalse(question("AÑO", locale: "es_ES").matches("ano"))
        XCTAssertTrue(question("ÁRBOL", locale: "es_ES").matches("  arbol! "))
        XCTAssertTrue(question("STRASSE", locale: "de_DE").matches("straße"))
    }

    func testRoundAlphabetOmitsUnavailableAndRemovedLetters() {
        let question = LanguageLearningQuestion(id: UUID(), clue: "Elma", extendedClue: nil,
            answer: "APPLE", difficulty: 1, category: "Yiyecek", letterCount: 5,
            initialLetter: "A", letterRule: "startsWith", sourceLanguage: "Turkish",
            targetLanguage: "English", locale: "en_US", cefrLevel: .a1)
        XCTAssertEqual(LearningLanguage.english.roundAlphabet(for: [question]), ["A"])
        XCTAssertEqual(LearningLanguage.english.roundAlphabet(for: []), [])
    }
}
