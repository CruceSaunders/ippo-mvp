import Foundation

struct EncounterConfig: Sendable {
    static let shared = EncounterConfig()

    // MARK: - Timing
    let minimumTimeBetweenEncounters: TimeInterval = 90.0
    let pityTimerMax: TimeInterval = 210.0

    // MARK: - Probability (increases with time since last sprint)
    // Checked every 1 second. Probabilities are derived from the original
    // 10-second-interval values via p_1s = 1 - (1 - p_10s)^(1/10), then
    // shifted +30s to increase the average gap between encounters by 30s.
    let probabilityTiers: [(range: ClosedRange<TimeInterval>, probability: Double)] = [
        (90...120,  0.002),     // ~0.2% per second  (was 2% per 10s at 60-90s)
        (120...150, 0.005),     // ~0.5% per second  (was 5% per 10s at 90-120s)
        (150...180, 0.0083),    // ~0.8% per second  (was 8% per 10s at 120-150s)
        (180...210, 0.0128),    // ~1.3% per second  (was 12% per 10s at 150-180s)
    ]
    let maxProbability: Double = 0.0162

    // MARK: - Check Interval
    let probabilityCheckInterval: TimeInterval = 1.0

    // MARK: - Minimum Run Time Before First Encounter
    let warmupDuration: TimeInterval = 60.0

    // MARK: - Helpers
    func probability(forTimeSinceLastSprint time: TimeInterval) -> Double {
        for tier in probabilityTiers {
            if tier.range.contains(time) {
                return tier.probability
            }
        }
        return time >= pityTimerMax ? 1.0 : (time < minimumTimeBetweenEncounters ? 0.0 : maxProbability)
    }
}
