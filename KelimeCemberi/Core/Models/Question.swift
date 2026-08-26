import Foundation

struct Question: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let clue: String
    let extendedClue: String?
    let answer: String
    let difficulty: Int
    let category: String
    let letterCount: Int
    let initialLetter: TurkishLetter
    let letterRule: String?
    let acceptedAnswers: [String]?

    var normalizedAnswer: String {
        answer.trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased(with: Locale(identifier: "tr_TR"))
    }

    enum CodingKeys: String, CodingKey {
        case id, clue, extendedClue, answer, difficulty, category, letterCount, initialLetter, letterRule, acceptedAnswers
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(UUID.self, forKey: .id)
        clue = try values.decode(String.self, forKey: .clue)
        extendedClue = try values.decodeIfPresent(String.self, forKey: .extendedClue)
        answer = try values.decode(String.self, forKey: .answer).trimmingCharacters(in: .whitespacesAndNewlines)
        difficulty = try values.decode(Int.self, forKey: .difficulty)
        category = try values.decode(String.self, forKey: .category)
        letterCount = try values.decode(Int.self, forKey: .letterCount)
        letterRule = try values.decodeIfPresent(String.self, forKey: .letterRule)
        acceptedAnswers = try values.decodeIfPresent([String].self, forKey: .acceptedAnswers)
        initialLetter = try values.decodeIfPresent(TurkishLetter.self, forKey: .initialLetter)
            ?? TurkishLetter.initialLetter(in: answer)
            ?? { throw DecodingError.dataCorruptedError(forKey: .answer, in: values, debugDescription: "Cevap Türk alfabesiyle başlamıyor.") }()
    }

    init(id: UUID, clue: String, extendedClue: String?, answer: String, difficulty: Int,
         category: String, letterCount: Int, initialLetter: TurkishLetter, letterRule: String? = nil,
         acceptedAnswers: [String]? = nil) {
        self.id = id; self.clue = clue; self.extendedClue = extendedClue; self.answer = answer
        self.difficulty = difficulty; self.category = category; self.letterCount = letterCount
        self.initialLetter = initialLetter; self.letterRule = letterRule
        self.acceptedAnswers = acceptedAnswers
    }
}
