import Foundation

protocol QuestionRepository: Sendable {
    func loadQuestions() async throws -> [Question]
    func questions(for letter: TurkishLetter, category: String?, difficulty: Int?) async throws -> [Question]
}

actor LocalQuestionRepository: QuestionRepository {
    private let loader: QuestionLoader
    private let bundle: Bundle
    private var cache: [Question]?

    init(loader: QuestionLoader = QuestionLoader(), bundle: Bundle = .main) {
        self.loader = loader; self.bundle = bundle
    }

    func loadQuestions() async throws -> [Question] {
        if let cache { return cache }
        let loaded = try loader.loadBundledQuestions(bundle: bundle).validQuestions
        cache = loaded
        return loaded
    }

    func questions(for letter: TurkishLetter, category: String?, difficulty: Int?) async throws -> [Question] {
        try await loadQuestions().filter {
            $0.initialLetter == letter && (category == nil || $0.category == category) &&
            (difficulty == nil || $0.difficulty == difficulty)
        }
    }
}
