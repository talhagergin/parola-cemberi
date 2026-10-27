import Foundation

enum LearningLanguage: String, CaseIterable, Identifiable, Codable, Sendable {
    case english, italian, german, dutch, spanish, azerbaijani
    var id: String { rawValue }
    var title: String { switch self { case .english: "İngilizce"; case .italian: "İtalyanca"; case .german: "Almanca"; case .dutch: "Felemenkçe"; case .spanish: "İspanyolca"; case .azerbaijani: "Azerbaycanca" } }
    var nativeTitle: String { switch self { case .english: "English"; case .italian: "Italiano"; case .german: "Deutsch"; case .dutch: "Nederlands"; case .spanish: "Español"; case .azerbaijani: "Azərbaycanca" } }
    var resourceName: String { "parola_cemberi_\(rawValue)_cefr" }
    var alphabet: [String] {
        switch self {
        case .english: "ABCDEFGHIJKLMNOPQRSTUVWYZ".map(String.init)
        case .italian: "ABCDEFGHILMNOPQRSTUVZ".map(String.init)
        case .german: "ABCDEFGHIJKLMNOPQRSTUVWYZÄÖÜ".map(String.init)
        case .dutch: "ABCDEFGHIJKLMNOPRSTUVWZ".map(String.init)
        case .spanish: "ABCDEFGHIJKLMNÑOPQRSTUVWYZ".map(String.init)
        case .azerbaijani: "ABCÇDEƏFGHIİJKQLMNOÖPRSŞTUÜVYZ".map(String.init)
        }
    }

    var locale: Locale {
        let identifier: String = switch self {
        case .english: "en_US"; case .italian: "it_IT"; case .german: "de_DE"
        case .dutch: "nl_NL"; case .spanish: "es_ES"; case .azerbaijani: "az_AZ"
        }
        return Locale(identifier: identifier)
    }

    func roundAlphabet(for questions: [LanguageLearningQuestion]) -> [String] {
        let available = Set(questions.map(\.initialLetter))
        return alphabet.filter { available.contains($0) }
    }
}

enum CEFRLevel: String, CaseIterable, Identifiable, Codable, Sendable {
    case a1 = "A1", a2 = "A2", b1 = "B1", b2 = "B2", c1 = "C1", c2 = "C2"
    var id: String { rawValue }
    var isUnlocked: Bool { self == .a1 || self == .b1 || self == .c1 }
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
        normalizedAnswer(input) == normalizedAnswer(answer)
    }

    private func normalizedAnswer(_ value: String) -> String {
        // Azerbaijani I/İ and Spanish N/Ñ are distinct letters, not optional accents.
        let targetLocale = Locale(identifier: locale)
        let lower = value.lowercased(with: targetLocale)
            .split(whereSeparator: \.isWhitespace).joined(separator: " ")
            .trimmingCharacters(in: .punctuationCharacters)
        if locale.hasPrefix("az") { return lower.precomposedStringWithCanonicalMapping }
        if locale.hasPrefix("es") {
            return lower.replacingOccurrences(of: "ñ", with: "\u{E000}")
                .folding(options: .diacriticInsensitive, locale: targetLocale)
                .replacingOccurrences(of: "\u{E000}", with: "ñ")
        }
        return lower.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: targetLocale)
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
