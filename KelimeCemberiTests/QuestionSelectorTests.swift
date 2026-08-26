import XCTest
@testable import KelimeCemberi

private actor MockQuestionRepository: QuestionRepository {
    let values: [Question]

    init(_ values: [Question]) { self.values = values }

    func loadQuestions() async throws -> [Question] { values }

    func questions(for letter: TurkishLetter, category: String?, difficulty: Int?) async throws -> [Question] {
        values.filter {
            $0.initialLetter == letter && (category == nil || $0.category == category) &&
            (difficulty == nil || $0.difficulty == difficulty)
        }
    }
}

final class QuestionSelectorTests: XCTestCase {
    func testRepositoryFiltersRealBundleByLetterCategoryAndDifficulty() async throws {
        let repository = LocalQuestionRepository(bundle: Bundle(for: Self.self))
        let questions = try await repository.questions(for: .a, category: "Teknoloji", difficulty: 1)
        XCTAssertFalse(questions.isEmpty)
        XCTAssertTrue(questions.allSatisfy {
            $0.initialLetter == .a && $0.category == "Teknoloji" && $0.difficulty == 1
        })
    }

    func testSelectorAvoidsRecentlyAskedQuestion() async throws {
        let recent = TestFixtures.question(letter: .a, answer: "AKIL")
        let fresh = TestFixtures.question(letter: .a, answer: "ALAN")
        let selector = QuestionSelector(repository: MockQuestionRepository([recent, fresh]))
        let selected = try await selector.selectQuestions(for: [.a], excluding: [recent.id])
        XCTAssertEqual(selected[.a]?.id, fresh.id)
    }

    func testSelectorRelaxesFiltersWhenNoMatchExists() async throws {
        let question = TestFixtures.question(letter: .a)
        let selector = QuestionSelector(repository: MockQuestionRepository([question]))
        let selected = try await selector.selectQuestions(for: [.a], category: "Olmayan", difficulty: 3)
        XCTAssertEqual(selected[.a]?.id, question.id)
    }

    func testDailySelectionIsStableForSameSeed() async throws {
        let values = (0..<8).map { _ in TestFixtures.question(letter: .a) }
        let selector = QuestionSelector(repository: MockQuestionRepository(values))
        let first = try await selector.selectQuestions(for: [.a], deterministicSeed: 42)
        let second = try await selector.selectQuestions(for: [.a], deterministicSeed: 42)
        XCTAssertEqual(first[.a]?.id, second[.a]?.id)
    }
}
