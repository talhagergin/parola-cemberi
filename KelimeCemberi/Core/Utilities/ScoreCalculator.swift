import Foundation

struct ScoringConfiguration: Hashable, Sendable {
    let correctAnswer: Int
    let hintedAnswer: Int
    let streakBonuses: [Int: Int]
    let remainingSecondBonus: Int
    let revisitMultiplier: Double

    static let standard = ScoringConfiguration(
        correctAnswer: 100,
        hintedAnswer: 60,
        streakBonuses: [3: 25, 5: 50, 10: 100],
        remainingSecondBonus: 2,
        revisitMultiplier: 0.8
    )

    static let quick = ScoringConfiguration(
        correctAnswer: 120,
        hintedAnswer: 70,
        streakBonuses: [3: 30, 5: 70, 10: 150],
        remainingSecondBonus: 3,
        revisitMultiplier: 0.75
    )

    static let daily = ScoringConfiguration(
        correctAnswer: 100,
        hintedAnswer: 55,
        streakBonuses: [3: 25, 5: 50, 10: 100],
        remainingSecondBonus: 2,
        revisitMultiplier: 0.8
    )
}

struct ScoreAward: Equatable, Sendable {
    let base: Int
    let streakBonus: Int
    var total: Int { base + streakBonus }
}

struct ScoreCalculator: Sendable {
    let configuration: ScoringConfiguration

    init(configuration: ScoringConfiguration = .standard) {
        self.configuration = configuration
    }

    func award(hintUsed: Bool, streak: Int, passCount: Int) -> ScoreAward {
        let rawBase = hintUsed ? configuration.hintedAnswer : configuration.correctAnswer
        let adjustedBase = passCount > 0 ? Int((Double(rawBase) * configuration.revisitMultiplier).rounded()) : rawBase
        return ScoreAward(base: adjustedBase, streakBonus: configuration.streakBonuses[streak, default: 0])
    }

    func timeBonus(remainingSeconds: Int) -> Int {
        max(0, remainingSeconds) * configuration.remainingSecondBonus
    }
}
