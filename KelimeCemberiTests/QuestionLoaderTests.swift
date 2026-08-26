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
            XCTAssertEqual(questions.count, 240, language.title)
            XCTAssertEqual(Set(questions.map(\.id)).count, 240, language.title)
            for level in CEFRLevel.allCases {
                XCTAssertEqual(questions.count { $0.cefrLevel == level }, 40, "\(language.title) \(level.rawValue)")
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
}
