import SwiftData

enum PersistenceContainer {
    static let schema = Schema([
        PlayerProfile.self,
        GameSessionRecord.self,
        LetterPerformanceRecord.self,
        CategoryPerformanceRecord.self,
        DailyChallengeRecord.self,
        AppSettings.self
    ])

    static func make() -> ModelContainer {
        do {
            return try ModelContainer(for: schema)
        } catch {
            // A corrupt or incompatible local store must not prevent the game from opening.
            let fallback = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            do { return try ModelContainer(for: schema, configurations: [fallback]) }
            catch { fatalError("SwiftData geçici deposu oluşturulamadı: \(error.localizedDescription)") }
        }
    }
}
