import Foundation

struct PetConfig: Sendable {
    static let shared = PetConfig()

    // MARK: - Stages
    let maxStages = 3

    let stageNames: [String] = [
        "Baby", "Teen", "Adult"
    ]

    // MARK: - Pet Levels

    let petMaxLevel = 30

    /// Default levels at which the pet evolves to the next stage.
    /// Per-pet overrides in GameData.swift take precedence.
    /// Baby -> Teen at level 6 (~80 XP, achievable in 1-3 runs + daily care)
    /// Teen -> Adult at level 18 (~2,160 XP, long-term goal over 2-4 weeks)
    let evolutionLevels: [Int: Int] = [
        2: 6,
        3: 18
    ]

    /// Cumulative XP to reach a given pet level.
    /// Uses a cubic curve (Pokemon-inspired): `floor(10 * n^3 / 27)`.
    /// Early levels cost almost nothing; late levels require serious grinding.
    ///
    /// Approximate totals:
    ///   Lv 10 →    370 XP   (~2-3 runs)
    ///   Lv 16 →  1,517 XP   (~10 runs, first evolution)
    ///   Lv 25 →  5,787 XP   (~39 runs, second evolution)
    ///   Lv 30 → 10,000 XP   (~67 runs)
    func xpRequiredForLevel(_ level: Int) -> Int {
        guard level > 1 else { return 0 }
        return (10 * level * level * level) / 27
    }

    /// Compute pet level from cumulative XP.
    func levelForXP(_ xp: Int) -> Int {
        var level = 1
        while level < petMaxLevel && xpRequiredForLevel(level + 1) <= xp {
            level += 1
        }
        return level
    }

    /// Derive evolution stage from pet level.
    func stageForLevel(_ level: Int) -> Int {
        var stage = 1
        for (stageNum, triggerLevel) in evolutionLevels.sorted(by: { $0.key < $1.key }) {
            if level >= triggerLevel {
                stage = stageNum
            }
        }
        return min(stage, maxStages)
    }

    // MARK: - XP Sources
    let xpPerFeeding: Int = 5
    let xpPerWatering: Int = 5
    let xpPerPetting: Int = 2

    // MARK: - Mood
    let happyMultiplier: Double = 1.0
    let contentMultiplier: Double = 0.85
    let sadMultiplier: Double = 0.6

    // MARK: - Runaway
    let runawayDaysSad: Int = 14
    let runawayDaysNoInteraction: Int = 14

    // MARK: - Rescue Costs
    func rescueCost(forStage stage: Int) -> Int {
        switch stage {
        case 1: return 50
        case 2: return 100
        default: return 200
        }
    }

    // MARK: - Helpers
    func stageName(for stage: Int) -> String {
        stageNames[safe: stage - 1] ?? "Unknown"
    }

    func xpMultiplier(forMood mood: Int) -> Double {
        switch mood {
        case 3: return happyMultiplier
        case 2: return contentMultiplier
        default: return sadMultiplier
        }
    }
}
