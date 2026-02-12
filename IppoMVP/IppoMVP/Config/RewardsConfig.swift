import Foundation

struct RewardsConfig: Sendable {
    static let shared = RewardsConfig()
    
    // MARK: - Sprint Rewards (Base amounts before bonuses)
    let rpPerSprint: ClosedRange<Int> = 15...25
    let xpPerSprint: ClosedRange<Int> = 30...50
    let coinsPerSprint: ClosedRange<Int> = 40...80
    
    // MARK: - Passive Rewards (Per minute while running)
    let rpPerMinute: ClosedRange<Int> = 1...2
    let xpPerMinute: ClosedRange<Int> = 2...4
    
    // MARK: - Pet Catch Bonus
    let bonusCoinsForPetCatch: Int = 500
    let bonusRPForPetCatch: Int = 100
    let bonusXPForPetCatch: Int = 200
    
    // MARK: - Streak Bonuses
    let streakBonuses: [(range: ClosedRange<Int>, bonus: Double)] = [
        (1...3, 0.05),    // +5%
        (4...7, 0.10),    // +10%
        (8...14, 0.15),   // +15%
    ]
    let maxStreakBonus: Double = 0.20  // +20% for 15+ days
    
    // MARK: - Starting Resources
    let startingCoins: Int = 500
    let startingGems: Int = 0
    
    // MARK: - Helpers
    func baseSprintRewards() -> (rp: Int, xp: Int, coins: Int) {
        (
            rp: Int.random(in: rpPerSprint),
            xp: Int.random(in: xpPerSprint),
            coins: Int.random(in: coinsPerSprint)
        )
    }
    
    func streakBonus(forDays days: Int) -> Double {
        for tier in streakBonuses {
            if tier.range.contains(days) {
                return tier.bonus
            }
        }
        return days >= 15 ? maxStreakBonus : 0.0
    }
    
    func applyBonuses(
        base: (rp: Int, xp: Int, coins: Int),
        rpBonus: Double = 0,
        xpBonus: Double = 0,
        coinBonus: Double = 0,
        allBonus: Double = 0,
        streakDays: Int = 0
    ) -> (rp: Int, xp: Int, coins: Int) {
        let streakMultiplier = 1.0 + streakBonus(forDays: streakDays)
        let rpMultiplier = (1.0 + rpBonus + allBonus) * streakMultiplier
        let xpMultiplier = (1.0 + xpBonus + allBonus) * streakMultiplier
        let coinMultiplier = (1.0 + coinBonus + allBonus) * streakMultiplier
        
        return (
            rp: Int(Double(base.rp) * rpMultiplier),
            xp: Int(Double(base.xp) * xpMultiplier),
            coins: Int(Double(base.coins) * coinMultiplier)
        )
    }
}
