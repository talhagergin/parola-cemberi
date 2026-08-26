import Foundation

struct QuestionValidationReport: Sendable {
    let totalRecords: Int
    let validQuestions: [Question]
    let invalidRecords: [String]
    let letterCountMismatches: [UUID]
    let duplicateIDs: [UUID]
    let duplicateQuestionAnswers: [String]

    var letterDistribution: [TurkishLetter: Int] {
        Dictionary(grouping: validQuestions, by: \.initialLetter).mapValues(\.count)
    }

    var categoryDistribution: [String: Int] {
        Dictionary(grouping: validQuestions, by: \.category).mapValues(\.count)
    }

    var difficultyDistribution: [Int: Int] {
        Dictionary(grouping: validQuestions, by: \.difficulty).mapValues(\.count)
    }

    var missingLetters: [TurkishLetter] {
        TurkishLetter.allCases.filter { letterDistribution[$0, default: 0] == 0 }
    }
}
