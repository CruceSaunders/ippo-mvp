import Foundation

struct EconomyConfig: Sendable {
    static let shared = EconomyConfig()

    // MARK: - Coin Income
    let coinsPerMinuteRunning: Int = 1
    let coinsPerSprint: ClosedRange<Int> = 8...12
    let coinsForCatchingPet: Int = 25

    // MARK: - Shop Prices
    let foodCost: Int = 3
    let waterCost: Int = 2
    let foodPackCount: Int = 5
    let foodPackCost: Int = 12
    let waterPackCount: Int = 5
    let waterPackCost: Int = 8
    let xpBoostCost: Int = 40        // +30% XP for 2 hours
    let encounterBoostCost: Int = 60 // +50% catch rate for 1 run
    let hibernationCost: Int = 80    // 7 days freeze

    // MARK: - Boost Durations
    let xpBoostDurationHours: Int = 2
    let xpBoostMultiplier: Double = 0.30  // +30%
    let encounterBoostMultiplier: Double = 0.50  // +50% to catch rate
    let hibernationDays: Int = 7

    // MARK: - Starting Coins
    let startingCoins: Int = 20
    let startingFood: Int = 3
    let startingWater: Int = 3
}
