import Foundation

/// RPDecaySystem — manages RP decay for inactive days
/// Called on app launch to apply any pending decay
@MainActor
final class RPDecaySystem {
    static let shared = RPDecaySystem()
    
    private init() {}
    
    /// Check and apply RP decay on app launch
    /// Decay is intentionally light to avoid discouraging users
    /// Bronze players are fully protected (no decay)
    func checkAndApplyDecay() {
        UserData.shared.applyRPDecayIfNeeded()
    }
    
    /// Get decay info for display
    func decayInfo(for rank: Rank) -> String {
        let range = rank.rpDecayPerDay
        if range.lowerBound == 0 && range.upperBound == 0 {
            return "No decay (protected)"
        }
        return "\(range.lowerBound)-\(range.upperBound) RP/day"
    }
}
