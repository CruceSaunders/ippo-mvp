import Foundation

/// CloudService stub - Firebase Firestore sync
/// NOTE: Requires Firebase SDK and GoogleService-Info.plist to be configured.
/// See MVP_Firebase_Setup.md for setup instructions.
///
/// Data structure in Firestore:
/// /users/{userId} -> SaveableUserData (JSON)
/// /users/{userId}/friends/{friendId} -> friend relationship
/// /groups/{groupId} -> group data with members and leaderboard

@MainActor
final class CloudService {
    static let shared = CloudService()
    
    private init() {}
    
    // MARK: - Save to Cloud
    func saveUserData(_ userData: UserData) async {
        guard AuthService.shared.isAuthenticated,
              let _userId = AuthService.shared.userId else { return }
        
        // TODO: Implement when Firebase is configured
        // let db = Firestore.firestore()
        // let saveable = SaveableUserData(...)
        // let data = try JSONEncoder().encode(saveable)
        // let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        // try await db.collection("users").document(_userId).setData(dict ?? [:])
        
        print("CloudService: Save not yet configured. Data saved locally only.")
    }
    
    // MARK: - Load from Cloud
    func loadUserData() async -> SaveableUserData? {
        guard AuthService.shared.isAuthenticated,
              let _userId = AuthService.shared.userId else { return nil }
        
        // TODO: Implement when Firebase is configured
        print("CloudService: Load not yet configured. Loading from local only.")
        return nil
    }
    
    // MARK: - Merge Strategy
    /// Merges local and cloud data, keeping the most progressed values
    func mergeData(local: SaveableUserData, cloud: SaveableUserData) -> SaveableUserData {
        // Keep highest progression values
        var mergedProfile = local.profile
        mergedProfile.rp = max(local.profile.rp, cloud.profile.rp)
        mergedProfile.xp = max(local.profile.xp, cloud.profile.xp)
        mergedProfile.level = max(local.profile.level, cloud.profile.level)
        mergedProfile.totalRuns = max(local.profile.totalRuns, cloud.profile.totalRuns)
        mergedProfile.totalSprints = max(local.profile.totalSprints, cloud.profile.totalSprints)
        mergedProfile.totalSprintsValid = max(local.profile.totalSprintsValid, cloud.profile.totalSprintsValid)
        mergedProfile.longestStreak = max(local.profile.longestStreak, cloud.profile.longestStreak)
        mergedProfile.totalDistanceMeters = max(local.profile.totalDistanceMeters, cloud.profile.totalDistanceMeters)
        
        // Merge RP boxes (union by ID)
        let localBoxIds = Set(local.pendingRPBoxes.map { $0.id })
        var mergedBoxes = local.pendingRPBoxes
        for cloudBox in cloud.pendingRPBoxes {
            if !localBoxIds.contains(cloudBox.id) {
                mergedBoxes.append(cloudBox)
            }
        }
        
        // Merge run history (union by ID)
        let localRunIds = Set(local.runHistory.map { $0.id })
        var mergedRuns = local.runHistory
        for cloudRun in cloud.runHistory {
            if !localRunIds.contains(cloudRun.id) {
                mergedRuns.append(cloudRun)
            }
        }
        mergedRuns.sort { $0.date > $1.date }
        
        // Merge friends (union)
        let mergedFriends = Array(Set(local.friends + cloud.friends))
        let mergedRequests = Array(Set(local.friendRequests + cloud.friendRequests))
        
        return SaveableUserData(
            profile: mergedProfile,
            pendingRPBoxes: mergedBoxes,
            runHistory: mergedRuns,
            friends: mergedFriends,
            friendRequests: mergedRequests
        )
    }
}
