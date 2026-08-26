import Foundation

struct QuestionSelector: Sendable {
    let repository: any QuestionRepository

    func selectQuestions(
        for letters: [TurkishLetter],
        category: String? = nil,
        difficulty: Int? = nil,
        excluding recentQuestionIDs: Set<UUID> = [],
        deterministicSeed: UInt64? = nil
    ) async throws -> [TurkishLetter: Question] {
        var result: [TurkishLetter: Question] = [:]
        var usedIDs = Set<UUID>()

        for letter in letters {
            var candidates = try await repository.questions(for: letter, category: category, difficulty: difficulty)
            if candidates.isEmpty, category != nil || difficulty != nil {
                candidates = try await repository.questions(for: letter, category: nil, difficulty: nil)
            }
            let fresh = candidates.filter { !recentQuestionIDs.contains($0.id) && !usedIDs.contains($0.id) }
            let available = fresh.isEmpty ? candidates.filter { !usedIDs.contains($0.id) } : fresh
            let selected: Question?
            if let deterministicSeed, !available.isEmpty {
                let ordered = available.sorted { $0.id.uuidString < $1.id.uuidString }
                let letterSalt = UInt64(letter.rawValue.unicodeScalars.first?.value ?? 0)
                selected = ordered[Int((deterministicSeed ^ (letterSalt &* 1_099_511_628_211)) % UInt64(ordered.count))]
            } else {
                selected = available.randomElement()
            }
            if let selected {
                result[letter] = selected
                usedIDs.insert(selected.id)
            }
        }
        return result
    }
}
