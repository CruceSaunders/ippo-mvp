import Foundation

struct RewardsConfig: Sendable {
    static let shared = RewardsConfig()
    
    // MARK: - XP Per Minute (1 XP per minute of running)
    let xpPerMinute: Int = 1
    
    // MARK: - RP Box Drop
    // Every valid sprint earns exactly 1 RP Box
    let rpBoxGuaranteedOnValidSprint: Bool = true
    
    // MARK: - Streak Bonuses (applied to RP box opening results)
    let streakBonuses: [(range: ClosedRange<Int>, bonus: Double)] = [
        (1...3, 0.05),    // +5%
        (4...7, 0.10),    // +10%
        (8...14, 0.15),   // +15%
    ]
    let maxStreakBonus: Double = 0.20  // +20% for 15+ days
    
    // MARK: - Helpers
    func streakBonus(forDays days: Int) -> Double {
        for tier in streakBonuses {
            if tier.range.contains(days) {
                return tier.bonus
            }
        }
        return days >= 15 ? maxStreakBonus : 0.0
    }
}
