import Foundation

enum LearningLanguage: String, CaseIterable, Identifiable, Codable, Sendable {
    case english, italian, german
    var id: String { rawValue }
    var title: String { switch self { case .english: "İngilizce"; case .italian: "İtalyanca"; case .german: "Almanca" } }
    var nativeTitle: String { switch self { case .english: "English"; case .italian: "Italiano"; case .german: "Deutsch" } }
    var flag: String { switch self { case .english: "🇬🇧"; case .italian: "🇮🇹"; case .german: "🇩🇪" } }
    var resourceName: String { "parola_cemberi_\(rawValue)_cefr" }
    var alphabet: [String] {
        switch self {
        case .english: "ABCDEFGHIJKLMNOPQRSTUVWXYZ".map(String.init)
        case .italian: "ABCDEFGHILMNOPQRSTUVZ".map(String.init)
        case .german: "ABCDEFGHIJKLMNOPQRSTUVWXYZÄÖÜ".map(String.init)
        }
    }
}

enum CEFRLevel: String, CaseIterable, Identifiable, Codable, Sendable {
    case a1 = "A1", a2 = "A2", b1 = "B1", b2 = "B2", c1 = "C1", c2 = "C2"
    var id: String { rawValue }
    var subtitle: String {
        switch self { case .a1: "Başlangıç"; case .a2: "Temel"; case .b1: "Orta"; case .b2: "Orta üstü"; case .c1: "İleri"; case .c2: "Ustalık" }
    }
}

struct LanguageLearningQuestion: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let clue: String
    let extendedClue: String?
    let answer: String
    let difficulty: Int
    let category: String
    let letterCount: Int
    let initialLetter: String
    let letterRule: String
    let sourceLanguage: String
    let targetLanguage: String
    let locale: String
    let cefrLevel: CEFRLevel

    func matches(_ input: String) -> Bool {
        input.trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: locale)) ==
        answer.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: locale))
    }
}

struct LanguageQuestionLoader: Sendable {
    func load(_ language: LearningLanguage, bundle: Bundle = .main) throws -> [LanguageLearningQuestion] {
        guard let url = bundle.url(forResource: language.resourceName, withExtension: "json") else {
            throw QuestionLoadingError.fileNotFound("\(language.resourceName).json")
        }
        return try JSONDecoder().decode([LanguageLearningQuestion].self, from: Data(contentsOf: url))
    }
}
