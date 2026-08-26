import Foundation
import Observation

@MainActor
@Observable
final class AppViewModel {
    enum State { case loading, ready(QuestionValidationReport), failed(String) }
    private(set) var state: State = .loading

    func prepare() async {
        do {
            async let minimumSplash: Void = Task.sleep(for: .milliseconds(900))
            let report = try await Task.detached { try QuestionLoader().loadBundledQuestions() }.value
            try await minimumSplash
            state = .ready(report)
#if DEBUG
            print("Soru doğrulama: \(report.validQuestions.count)/\(report.totalRecords) geçerli")
#endif
        } catch {
            state = .failed((error as? LocalizedError)?.errorDescription ?? "Beklenmeyen bir sorun oluştu.")
        }
    }
}
