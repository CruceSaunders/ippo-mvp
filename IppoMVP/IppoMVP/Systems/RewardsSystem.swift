import Foundation

@MainActor
final class RewardsSystem: ObservableObject {
    static let shared = RewardsSystem()
    
    private let config = RewardsConfig.shared
    
    private init() {}
    
    // MARK: - Calculate Sprint Rewards
    /// Every valid sprint earns 1 RP Box
    func calculateSprintRewards(result: SprintResult) -> SprintRewards {
        guard result.isValid else { return .empty }
        return SprintRewards(rpBoxEarned: true, xp: 0)
    }
    
    // MARK: - Apply Rewards
    func applyRewards(_ rewards: SprintRewards) {
        let userData = UserData.shared
        
        if rewards.rpBoxEarned {
            userData.addRPBox()
        }
        
        if rewards.xp > 0 {
            userData.addXP(rewards.xp)
        }
    }
}
