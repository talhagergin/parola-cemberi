import Foundation

struct AnswerValidator: Sendable {
    private let locale = Locale(identifier: "tr_TR")

    func isCorrect(_ userAnswer: String, for question: Question) -> Bool {
        let expected = [question.answer] + (question.acceptedAnswers ?? [])
        let candidate = normalize(userAnswer)
        return !candidate.isEmpty && expected.contains { normalize($0) == candidate }
    }

    func normalize(_ value: String) -> String {
        let apostropheNormalized = value
            .replacingOccurrences(of: "’", with: "'")
            .replacingOccurrences(of: "`", with: "'")
        let allowed = apostropheNormalized.unicodeScalars.filter {
            CharacterSet.letters.contains($0) || CharacterSet.decimalDigits.contains($0) ||
            CharacterSet.whitespaces.contains($0) || $0 == "'"
        }
        return String(String.UnicodeScalarView(allowed))
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
            .trimmingCharacters(in: CharacterSet(charactersIn: "'"))
            .uppercased(with: locale)
    }
}
