import Foundation

struct EncounterConfig: Sendable {
    static let shared = EncounterConfig()
    
    // MARK: - Timing
    let minimumTimeBetweenEncounters: TimeInterval = 60.0
    let pityTimerMax: TimeInterval = 180.0  // Guaranteed after 3 minutes
    
    // MARK: - Probability (increases with time since last sprint)
    // Checked every 10 seconds
    let probabilityTiers: [(range: ClosedRange<TimeInterval>, probability: Double)] = [
        (60...90, 0.02),    // 60-90s: 2%
        (90...120, 0.05),   // 90-120s: 5%
        (120...150, 0.08),  // 120-150s: 8%
        (150...180, 0.12),  // 150-180s: 12%
    ]
    let maxProbability: Double = 0.15  // Cap at 15%
    
    // MARK: - Check Interval
    let probabilityCheckInterval: TimeInterval = 10.0
    
    // MARK: - Minimum Run Time Before First Encounter
    let warmupDuration: TimeInterval = 60.0  // 1 minute warmup
    
    // MARK: - Loot Box Probability
    let lootBoxDropChance: Double = 0.70  // 70% chance per valid sprint
    
    // MARK: - Loot Box Rarity Distribution
    let lootBoxRarityDistribution: [(rarity: Rarity, probability: Double)] = [
        (.common, 0.55),
        (.uncommon, 0.25),
        (.rare, 0.12),
        (.epic, 0.06),
        (.legendary, 0.02)
    ]
    
    // MARK: - Helpers
    func probability(forTimeSinceLastSprint time: TimeInterval) -> Double {
        for tier in probabilityTiers {
            if tier.range.contains(time) {
                return tier.probability
            }
        }
        return time >= pityTimerMax ? 1.0 : maxProbability
    }
    
    func rollLootBoxRarity() -> Rarity? {
        rollLootBoxRarity(luckBonus: 0)
    }
    
    func rollLootBoxRarity(luckBonus: Double) -> Rarity? {
        guard Double.random(in: 0...1) < lootBoxDropChance else { return nil }
        
        let roll = Double.random(in: 0...1)
        var cumulative: Double = 0
        
        // Luck bonus shifts probability toward rarer items
        for (rarity, prob) in lootBoxRarityDistribution {
            var adjustedProb = prob
            // Increase rare+ probabilities, decrease common
            switch rarity {
            case .common:
                adjustedProb = max(0.10, prob - luckBonus)
            case .uncommon:
                adjustedProb = prob + luckBonus * 0.3
            case .rare:
                adjustedProb = prob + luckBonus * 0.3
            case .epic:
                adjustedProb = prob + luckBonus * 0.25
            case .legendary:
                adjustedProb = prob + luckBonus * 0.15
            }
            cumulative += adjustedProb
            if roll <= cumulative {
                return rarity
            }
        }
        return .common
    }
}
