import Foundation

enum QuestionLoadingError: LocalizedError {
    case fileNotFound(String), unreadableFile, emptyPool

    var errorDescription: String? {
        switch self {
        case .fileNotFound: "Soru paketi bulunamadı. Uygulamayı yeniden yüklemeyi deneyin."
        case .unreadableFile: "Soru paketi okunamadı."
        case .emptyPool: "Soru paketinde oynanabilir soru bulunamadı."
        }
    }
}

struct QuestionLoader: Sendable {
    private struct RawRecord: Decodable {
        let id: String?
        let clue: String?
        let extendedClue: String?
        let answer: String?
        let difficulty: Int?
        let category: String?
        let letterCount: Int?
        let initialLetter: String?
        let letterRule: String?
        let acceptedAnswers: [String]?
    }

    func load(from url: URL) throws -> QuestionValidationReport {
        guard let data = try? Data(contentsOf: url) else { throw QuestionLoadingError.unreadableFile }
        let records = try JSONDecoder().decode([RawRecord].self, from: data)
        var questions: [Question] = [], invalid: [String] = [], mismatches: [UUID] = []

        for (index, record) in records.enumerated() {
            guard let idText = record.id, let id = UUID(uuidString: idText),
                  let clue = record.clue, !clue.isEmpty,
                  let rawAnswer = record.answer,
                  let difficulty = record.difficulty,
                  let category = record.category,
                  let letterCount = record.letterCount else {
                invalid.append("Kayıt \(index + 1): zorunlu alan eksik veya UUID geçersiz")
                continue
            }
            let answer = rawAnswer.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !answer.isEmpty, let derived = TurkishLetter.initialLetter(in: answer) else {
                invalid.append("Kayıt \(index + 1): boş/geçersiz cevap")
                continue
            }
            let letter = record.initialLetter.flatMap(TurkishLetter.init(rawValue:)) ?? derived
            let actualCount = answer.filter(\.isLetter).count
            if actualCount != letterCount { mismatches.append(id) }
            questions.append(Question(id: id, clue: clue, extendedClue: record.extendedClue,
                                      answer: answer, difficulty: difficulty, category: category,
                                      letterCount: letterCount, initialLetter: letter, letterRule: record.letterRule,
                                      acceptedAnswers: record.acceptedAnswers))
        }

        guard !questions.isEmpty else { throw QuestionLoadingError.emptyPool }
        let ids = Dictionary(grouping: questions, by: \.id)
        let pairs = Dictionary(grouping: questions) { "\($0.clue)|\($0.normalizedAnswer)" }
        return QuestionValidationReport(
            totalRecords: records.count,
            validQuestions: questions,
            invalidRecords: invalid,
            letterCountMismatches: mismatches,
            duplicateIDs: ids.compactMap { $0.value.count > 1 ? $0.key : nil },
            duplicateQuestionAnswers: pairs.compactMap { $0.value.count > 1 ? $0.key : nil }
        )
    }

    func loadBundledQuestions(bundle: Bundle = .main) throws -> QuestionValidationReport {
        guard let url = bundle.url(forResource: "parola_cemberi_5000_soru", withExtension: "json") else {
            throw QuestionLoadingError.fileNotFound("parola_cemberi_5000_soru.json")
        }
        return try load(from: url)
    }
}
