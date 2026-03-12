import Foundation

struct EncounterConfig: Sendable {
    static let shared = EncounterConfig()

    // MARK: - Timing
    let minimumTimeBetweenEncounters: TimeInterval = 60.0
    let pityTimerMax: TimeInterval = 180.0

    // MARK: - Probability (increases with time since last sprint)
    // Checked every 1 second. Values derived from original 10s-interval
    // probabilities via p_1s = 1 - (1 - p_10s)^(1/10).
    let probabilityTiers: [(range: ClosedRange<TimeInterval>, probability: Double)] = [
        (60...90,   0.002),     // ~0.2% per second  (equivalent to 2% per 10s)
        (90...120,  0.005),     // ~0.5% per second  (equivalent to 5% per 10s)
        (120...150, 0.0083),    // ~0.8% per second  (equivalent to 8% per 10s)
        (150...180, 0.0128),    // ~1.3% per second  (equivalent to 12% per 10s)
    ]
    let maxProbability: Double = 0.0162

    // MARK: - Check Interval
    let probabilityCheckInterval: TimeInterval = 1.0

    // MARK: - Minimum Run Time Before First Encounter
    let warmupDuration: TimeInterval = 60.0

    // MARK: - Helpers
    func probability(forTimeSinceLastSprint time: TimeInterval) -> Double {
        guard time >= minimumTimeBetweenEncounters else { return 0.0 }
        for tier in probabilityTiers {
            if tier.range.contains(time) {
                return tier.probability
            }
        }
        return time >= pityTimerMax ? 1.0 : 0.0
    }
}
