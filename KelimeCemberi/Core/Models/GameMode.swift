import Foundation

enum GameMode: String, CaseIterable, Identifiable, Sendable {
    case classic, quick, category, daily

    var id: String { rawValue }
    var title: String {
        switch self {
        case .classic: "Klasik Çember"
        case .quick: "Hızlı Tur"
        case .category: "Kategori"
        case .daily: "Günlük Çember"
        }
    }
    var subtitle: String {
        switch self {
        case .classic: "29 harf • 120 saniye"
        case .quick: "10 harf • 60 saniye"
        case .category: "Sevdiğin konuda yarış"
        case .daily: "Her gün aynı özel çember"
        }
    }
    var icon: String {
        switch self {
        case .classic: "circle.hexagongrid.fill"
        case .quick: "bolt.fill"
        case .category: "square.grid.2x2.fill"
        case .daily: "calendar.badge.clock"
        }
    }
    var configuration: GameConfiguration {
        switch self {
        case .quick:
            GameConfiguration(letters: Array(TurkishLetter.allCases.shuffled().prefix(10)), durationSeconds: 60, maximumPassCount: 1)
        default: .classic
        }
    }
    var scoringConfiguration: ScoringConfiguration {
        switch self { case .quick: .quick; case .daily: .daily; default: .standard }
    }
    var isAvailable: Bool { true }
}

struct GameLaunchRequest: Sendable {
    let mode: GameMode
    let configuration: GameConfiguration
    let category: String?
    let dailyDayKey: String?
    let dailySeed: UInt64?

    init(mode: GameMode, category: String? = nil, date: Date = .now, calendar: Calendar = .turkey) {
        self.mode = mode
        configuration = mode.configuration
        self.category = category
        if mode == .daily {
            dailyDayKey = DailyChallengeSeed.dayKey(for: date, calendar: calendar)
            dailySeed = DailyChallengeSeed.seed(for: date, calendar: calendar)
        } else {
            dailyDayKey = nil
            dailySeed = nil
        }
    }
}

enum DailyChallengeSeed {
    static func dayKey(for date: Date, calendar: Calendar = .turkey) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", components.year ?? 0, components.month ?? 0, components.day ?? 0)
    }

    static func seed(for date: Date, calendar: Calendar = .turkey) -> UInt64 {
        dayKey(for: date, calendar: calendar).utf8.reduce(14_695_981_039_346_656_037) { ($0 ^ UInt64($1)) &* 1_099_511_628_211 }
    }
}

extension Calendar {
    static var turkey: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "tr_TR")
        calendar.timeZone = TimeZone(identifier: "Europe/Istanbul") ?? .current
        return calendar
    }
}
