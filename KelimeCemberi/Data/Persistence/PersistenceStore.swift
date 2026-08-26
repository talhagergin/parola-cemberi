import Foundation
import Observation
import SwiftData

struct PerformanceItem: Identifiable, Equatable {
    let id: String
    let title: String
    let attempts: Int
    let correct: Int
    let wrong: Int
    let passed: Int

    var accuracy: Int {
        let answered = correct + wrong
        return answered == 0 ? 0 : Int((Double(correct) / Double(answered) * 100).rounded())
    }
}

struct StatisticsSnapshot: Equatable {
    var totalGames = 0
    var totalCorrect = 0
    var totalWrong = 0
    var totalPassed = 0
    var totalHints = 0
    var highScore = 0
    var longestStreak = 0
    var dailyStreak = 0
    var letters: [PerformanceItem] = []
    var categories: [PerformanceItem] = []

    var accuracy: Int {
        let answered = totalCorrect + totalWrong
        return answered == 0 ? 0 : Int((Double(totalCorrect) / Double(answered) * 100).rounded())
    }

    var bestCategory: PerformanceItem? { categories.filter { $0.attempts > 0 }.max { $0.accuracy < $1.accuracy } }
    var hardestCategory: PerformanceItem? { categories.filter { $0.attempts > 0 }.min { $0.accuracy < $1.accuracy } }
}

@MainActor @Observable
final class PersistenceStore {
    // Retaining the container keeps model instances valid when the store is used outside SwiftUI.
    private let container: ModelContainer
    private let context: ModelContext
    private(set) var snapshot = StatisticsSnapshot()
    private(set) var settings: AppSettings
    private(set) var lastErrorMessage: String?
    private(set) var lastEarnedCoins = 0

    init(context: ModelContext) {
        container = context.container
        self.context = context
        if let existing = try? context.fetch(FetchDescriptor<AppSettings>()).first {
            settings = existing
        } else {
            let created = AppSettings()
            context.insert(created)
            settings = created
            try? context.save()
        }
        refresh()
    }

    @discardableResult func record(session: GameSession, request: GameLaunchRequest) -> Int {
        do {
            let sessionID = session.id
            var descriptor = FetchDescriptor<GameSessionRecord>(predicate: #Predicate { $0.sessionID == sessionID })
            descriptor.fetchLimit = 1
            guard try context.fetch(descriptor).isEmpty else { return 0 }

            context.insert(GameSessionRecord(session: session, request: request))
            if request.mode == .daily, let dayKey = request.dailyDayKey, try dailyRecord(for: dayKey) == nil {
                context.insert(DailyChallengeRecord(dayKey: dayKey, completedAt: session.finishedAt ?? .now, score: session.score, sessionID: session.id))
            }
            let profile = try profileRecord()
            profile.totalGames += 1
            profile.totalCorrect += session.letters.count { $0.status == .correct }
            profile.totalWrong += session.letters.count { $0.status == .wrong }
            profile.totalPassed += session.letters.count { $0.status == .passed }
            profile.totalHints += session.hintsUsed
            profile.highScore = max(profile.highScore, session.score)
            profile.longestStreak = max(profile.longestStreak, session.longestStreak)
            let earnedCoins = max(20, session.letters.count { $0.status == .correct } * 8)
            settings.coinBalance += earnedCoins
            settings.completedRoundsSinceAd += 1
            lastEarnedCoins = earnedCoins

            for state in session.letters where state.question != nil {
                let letter = try letterRecord(for: state.letter)
                apply(state.status, attempts: &letter.attempts, correct: &letter.correct, wrong: &letter.wrong, passed: &letter.passed)

                if let question = state.question {
                    let category = try categoryRecord(for: question.category)
                    apply(state.status, attempts: &category.attempts, correct: &category.correct, wrong: &category.wrong, passed: &category.passed)
                    category.totalScore += state.awardedPoints
                }
            }
            try context.save()
            lastErrorMessage = nil
            refresh()
            return earnedCoins
        } catch {
            lastErrorMessage = "Oyun sonucu kaydedilemedi. İstatistikler daha sonra yeniden güncellenebilir."
            lastEarnedCoins = 0
            return 0
        }
    }

    func purchase(_ avatar: PlayerAvatar) -> Bool {
        guard !settings.owns(avatar), settings.coinBalance >= avatar.price else { return false }
        settings.coinBalance -= avatar.price
        var owned = settings.ownedAvatarRawValues ?? [PlayerAvatar.robot.rawValue]
        owned.append(avatar.rawValue); settings.ownedAvatarRawValues = Array(Set(owned))
        settings.selectedAvatar = avatar
        saveSettings(); return true
    }

    func purchase(_ theme: CircleTheme) -> Bool {
        guard !settings.owns(theme), settings.coinBalance >= theme.price else { return false }
        settings.coinBalance -= theme.price
        var owned = settings.ownedCircleThemeRawValues ?? [CircleTheme.classic.rawValue]
        owned.append(theme.rawValue); settings.ownedCircleThemeRawValues = Array(Set(owned))
        settings.selectedCircleTheme = theme
        saveSettings(); return true
    }

    func select(_ avatar: PlayerAvatar) { guard settings.owns(avatar) else { return }; settings.selectedAvatar = avatar; saveSettings() }
    func select(_ theme: CircleTheme) { guard settings.owns(theme) else { return }; settings.selectedCircleTheme = theme; saveSettings() }

    func consumeInterstitialMilestone() -> Bool {
        guard settings.completedRoundsSinceAd >= 3 else { return false }
        settings.completedRoundsSinceAd = 0
        saveSettings()
        return true
    }

    func saveSettings() {
        do { try context.save(); lastErrorMessage = nil }
        catch { lastErrorMessage = "Ayarlar kaydedilemedi." }
    }

    func resetProgress() {
        do {
            try context.fetch(FetchDescriptor<GameSessionRecord>()).forEach(context.delete)
            try context.fetch(FetchDescriptor<LetterPerformanceRecord>()).forEach(context.delete)
            try context.fetch(FetchDescriptor<CategoryPerformanceRecord>()).forEach(context.delete)
            try context.fetch(FetchDescriptor<DailyChallengeRecord>()).forEach(context.delete)
            try context.fetch(FetchDescriptor<PlayerProfile>()).forEach(context.delete)
            try context.save()
            lastErrorMessage = nil
            refresh()
        } catch {
            lastErrorMessage = "İlerleme verileri sıfırlanamadı."
        }
    }

    func refresh() {
        do {
            let profile = try context.fetch(FetchDescriptor<PlayerProfile>()).first
            let letterRecords = try context.fetch(FetchDescriptor<LetterPerformanceRecord>())
            let categoryRecords = try context.fetch(FetchDescriptor<CategoryPerformanceRecord>())
            let dailyRecords = try context.fetch(FetchDescriptor<DailyChallengeRecord>())
            snapshot = StatisticsSnapshot(
                totalGames: profile?.totalGames ?? 0,
                totalCorrect: profile?.totalCorrect ?? 0,
                totalWrong: profile?.totalWrong ?? 0,
                totalPassed: profile?.totalPassed ?? 0,
                totalHints: profile?.totalHints ?? 0,
                highScore: profile?.highScore ?? 0,
                longestStreak: profile?.longestStreak ?? 0,
                dailyStreak: Self.dailyStreak(from: dailyRecords.map(\.completedAt)),
                letters: letterRecords.map { PerformanceItem(id: $0.letterRawValue, title: $0.letterRawValue, attempts: $0.attempts, correct: $0.correct, wrong: $0.wrong, passed: $0.passed) }.sorted { TurkishLetter.sortIndex($0.id) < TurkishLetter.sortIndex($1.id) },
                categories: categoryRecords.map { PerformanceItem(id: $0.category, title: $0.category, attempts: $0.attempts, correct: $0.correct, wrong: $0.wrong, passed: $0.passed) }.sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
            )
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = "İstatistikler şu anda yüklenemiyor."
        }
    }

    func isDailyCompleted(dayKey: String = DailyChallengeSeed.dayKey(for: .now)) -> Bool {
        (try? dailyRecord(for: dayKey)) != nil
    }

    func dailyCompletionCount() -> Int {
        (try? context.fetchCount(FetchDescriptor<DailyChallengeRecord>())) ?? 0
    }

    func recentQuestionIDs(sessionLimit: Int = 5) -> Set<UUID> {
        var descriptor = FetchDescriptor<GameSessionRecord>(sortBy: [SortDescriptor(\.playedAt, order: .reverse)])
        descriptor.fetchLimit = max(0, sessionLimit)
        let records = (try? context.fetch(descriptor)) ?? []
        return Set(records.flatMap(\.questionIDs).compactMap(UUID.init(uuidString:)))
    }

    static func dailyStreak(from dates: [Date], calendar: Calendar = Calendar(identifier: .gregorian), now: Date = .now) -> Int {
        let days = Set(dates.map { calendar.startOfDay(for: $0) })
        guard !days.isEmpty else { return 0 }
        var cursor = calendar.startOfDay(for: now)
        if !days.contains(cursor) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: cursor), days.contains(yesterday) else { return 0 }
            cursor = yesterday
        }
        var streak = 0
        while days.contains(cursor) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return streak
    }

    private func profileRecord() throws -> PlayerProfile {
        if let record = try context.fetch(FetchDescriptor<PlayerProfile>()).first { return record }
        let record = PlayerProfile(); context.insert(record); return record
    }

    private func letterRecord(for letter: TurkishLetter) throws -> LetterPerformanceRecord {
        let rawValue = letter.rawValue
        var descriptor = FetchDescriptor<LetterPerformanceRecord>(predicate: #Predicate { $0.letterRawValue == rawValue })
        descriptor.fetchLimit = 1
        if let record = try context.fetch(descriptor).first { return record }
        let record = LetterPerformanceRecord(letter: letter); context.insert(record); return record
    }

    private func categoryRecord(for category: String) throws -> CategoryPerformanceRecord {
        var descriptor = FetchDescriptor<CategoryPerformanceRecord>(predicate: #Predicate { $0.category == category })
        descriptor.fetchLimit = 1
        if let record = try context.fetch(descriptor).first { return record }
        let record = CategoryPerformanceRecord(category: category); context.insert(record); return record
    }

    private func dailyRecord(for dayKey: String) throws -> DailyChallengeRecord? {
        var descriptor = FetchDescriptor<DailyChallengeRecord>(predicate: #Predicate { $0.dayKey == dayKey })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private func apply(_ status: LetterStatus, attempts: inout Int, correct: inout Int, wrong: inout Int, passed: inout Int) {
        switch status {
        case .correct: attempts += 1; correct += 1
        case .wrong: attempts += 1; wrong += 1
        case .passed: attempts += 1; passed += 1
        case .waiting, .active, .unavailable: break
        }
    }
}

private extension TurkishLetter {
    static func sortIndex(_ rawValue: String) -> Int {
        allCases.firstIndex { $0.rawValue == rawValue } ?? Int.max
    }
}
