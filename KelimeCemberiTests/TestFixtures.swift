import Foundation
@testable import KelimeCemberi

enum TestFixtures {
    static func question(
        letter: TurkishLetter,
        answer: String? = nil,
        extendedClue: String? = "Ek ipucu",
        acceptedAnswers: [String]? = nil
    ) -> Question {
        let resolvedAnswer = answer ?? letter.rawValue + "KELİME"
        return Question(
            id: UUID(), clue: "\(letter.rawValue) sorusu", extendedClue: extendedClue,
            answer: resolvedAnswer, difficulty: 1, category: "Test",
            letterCount: resolvedAnswer.count, initialLetter: letter,
            acceptedAnswers: acceptedAnswers
        )
    }

    @MainActor
    static func engine(
        letters: [TurkishLetter] = [.a, .b, .c],
        duration: Int = 120,
        maximumPassCount: Int = 2
    ) -> GameEngine {
        let questions = Dictionary(uniqueKeysWithValues: letters.map { ($0, question(letter: $0)) })
        let session = GameSession(
            configuration: GameConfiguration(
                letters: letters, durationSeconds: duration, maximumPassCount: maximumPassCount
            ),
            questions: questions
        )
        return GameEngine(session: session)
    }
}
