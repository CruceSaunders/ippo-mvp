import Foundation

struct PetConfig: Sendable {
    static let shared = PetConfig()

    // MARK: - Stages
    let maxStages = 3

    let stageNames: [String] = [
        "Baby", "Teen", "Adult"
    ]

    // MARK: - Pet Levels

    let petMaxLevel = 20

    /// Levels at which the pet evolves to the next stage.
    /// Key = new stage number, Value = level that triggers it.
    let evolutionLevels: [Int: Int] = [
        2: 8,   // Baby -> Teen at level 8  (~2,170 XP, ~3 hrs running)
        3: 14   // Teen -> Adult at level 14 (~5,590 XP, ~9.5 hrs total)
    ]

    /// Cumulative XP required to reach a given pet level.
    /// Level 1 = 0 XP. Uses a quadratic curve so each level takes progressively more XP.
    ///
    /// Approximate totals:
    ///   Lv  8 → 2,170 XP  (~3 hrs running, first evolution)
    ///   Lv 14 → 5,590 XP  (~9.5 hrs running, second evolution)
    ///   Lv 20 → 10,450 XP
    func xpRequiredForLevel(_ level: Int) -> Int {
        guard level > 1 else { return 0 }
        var total = 0
        for lv in 2...level {
            total += xpToReachNextLevel(from: lv - 1)
        }
        return total
    }

    /// XP needed to go from `level` to `level + 1`.
    func xpToReachNextLevel(from level: Int) -> Int {
        guard level >= 1 else { return 0 }
        let base = 150
        let growth = 40
        return base + (level - 1) * growth
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
    let xpPerMinuteRunning: Int = 5
    let xpPerSprint: ClosedRange<Int> = 15...25
    let xpPerFeeding: Int = 5
    let xpPerWatering: Int = 5
    let xpPerPetting: Int = 2

    // MARK: - Mood
    let happyMultiplier: Double = 1.0
    let contentMultiplier: Double = 0.85
    let sadMultiplier: Double = 0.6

    // MARK: - Catch Rate
    let baseCatchRate: Double = 0.08
    let encounterCharmRate: Double = 0.11  // 8% + 3% from charm
    let pityTimerSprints: Int = 15

    // MARK: - Runaway
    let runawayDaysSad: Int = 14
    let runawayDaysNoInteraction: Int = 14
    let runawayDaysAccelerated: Int = 10

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
