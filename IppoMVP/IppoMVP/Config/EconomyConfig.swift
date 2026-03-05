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
    let xpBoostCost: Int = 40         // +30% XP for 2 hours
    let encounterCharmCost: Int = 25  // +3% catch rate for 1 run
    let coinBoostCost: Int = 30       // +40% coins for 1 run
    let hibernationCost: Int = 80     // 7 days freeze
    let streakFreezeCost: Int = 50    // 3 days streak protection

    // MARK: - Boost Values
    let xpBoostDurationHours: Int = 2
    let xpBoostMultiplier: Double = 0.30     // +30%
    let encounterCharmBonus: Double = 0.03   // 8% -> 11% catch rate
    let coinBoostMultiplier: Double = 0.40   // +40% coins
    let hibernationDays: Int = 7
    let streakFreezeDays: Int = 3

    // MARK: - Streak XP Bonus
    let maxStreakBonusPercent: Double = 0.10  // 10% max XP bonus from streak
    let streakBonusCap: Int = 30             // Caps at 30-day streak

    // MARK: - Starting Coins
    let startingCoins: Int = 20
    let startingFood: Int = 3
    let startingWater: Int = 3
}
