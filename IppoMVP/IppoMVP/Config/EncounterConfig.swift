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
    
    // MARK: - Helpers
    func probability(forTimeSinceLastSprint time: TimeInterval) -> Double {
        for tier in probabilityTiers {
            if tier.range.contains(time) {
                return tier.probability
            }
        }
        return time >= pityTimerMax ? 1.0 : maxProbability
    }
}
