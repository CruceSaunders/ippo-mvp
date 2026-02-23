import Foundation

struct PetConfig: Sendable {
    static let shared = PetConfig()

    let maxStages = 10

    // Cumulative XP thresholds for each stage (index 0 = stage 1 threshold)
    let xpThresholds: [Int] = [
        0,       // Stage 1: Newborn
        200,     // Stage 2: Sprout
        500,     // Stage 3: Seedling
        1_000,   // Stage 4: Bloom
        1_800,   // Stage 5: Juvenile
        3_000,   // Stage 6: Adolescent
        4_500,   // Stage 7: Young
        6_500,   // Stage 8: Mature
        9_000,   // Stage 9: Prime
        12_000   // Stage 10: Elder
    ]

    let stageNames: [String] = [
        "Newborn", "Sprout", "Seedling", "Bloom", "Juvenile",
        "Adolescent", "Young", "Mature", "Prime", "Elder"
    ]

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
    let baseCatchRate: Double = 0.08         // 8% per sprint
    let encounterBoostRate: Double = 0.12    // 12% with boost
    let pityTimerSprints: Int = 15           // guaranteed after 15 dry sprints

    // MARK: - Runaway
    let runawayDaysSad: Int = 14
    let runawayDaysNoInteraction: Int = 14
    let runawayDaysAccelerated: Int = 10     // sad + no care + no run

    // MARK: - Rescue Costs
    func rescueCost(forStage stage: Int) -> Int {
        switch stage {
        case 1...3: return 50
        case 4...6: return 100
        case 7...9: return 200
        default: return 300
        }
    }

    // MARK: - Helpers
    func stageName(for stage: Int) -> String {
        stageNames[safe: stage - 1] ?? "Unknown"
    }

    func currentStage(forXP xp: Int) -> Int {
        var stage = 1
        for i in 1..<xpThresholds.count {
            if xp >= xpThresholds[i] {
                stage = i + 1
            }
        }
        return min(stage, maxStages)
    }

    func xpMultiplier(forMood mood: Int) -> Double {
        switch mood {
        case 3: return happyMultiplier
        case 2: return contentMultiplier
        default: return sadMultiplier
        }
    }
}
