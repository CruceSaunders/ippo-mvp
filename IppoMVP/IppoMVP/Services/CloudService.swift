import Foundation
import FirebaseFirestore

@MainActor
final class CloudService {
    static let shared = CloudService()
    
    private let db = Firestore.firestore()
    
    private init() {}
    
    // MARK: - Save User Data to Firestore
    func saveUserData(_ userData: UserData) async {
        guard AuthService.shared.isAuthenticated,
              let uid = AuthService.shared.userId else { return }
        
        let saveable = SaveableUserData(
            profile: userData.profile,
            pendingRPBoxes: userData.pendingRPBoxes,
            runHistory: userData.runHistory,
            friends: userData.friends,
            friendRequests: userData.friendRequests
        )
        
        do {
            let data = try JSONEncoder().encode(saveable)
            guard var dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }
            
            // Write flat search fields for efficient Firestore querying (rank roster, leaderboards)
            dict["rankSearchFields"] = [
                "rp": userData.profile.rp,
                "displayName": userData.profile.displayName,
                "username": userData.profile.username,
                "level": userData.profile.level
            ] as [String: Any]
            
            try await db.collection("users").document(uid).setData(dict, merge: true)
        } catch {
            print("CloudService: Failed to save - \(error)")
        }
    }
    
    // MARK: - Load User Data from Firestore
    func loadUserData() async -> SaveableUserData? {
        guard AuthService.shared.isAuthenticated,
              let uid = AuthService.shared.userId else { return nil }
        
        do {
            let doc = try await db.collection("users").document(uid).getDocument()
            guard let data = doc.data() else { return nil }
            
            let jsonData = try JSONSerialization.data(withJSONObject: data)
            return try JSONDecoder().decode(SaveableUserData.self, from: jsonData)
        } catch {
            print("CloudService: Failed to load - \(error)")
            return nil
        }
    }
    
    // MARK: - Save on Every Local Save (fire-and-forget)
    func syncToCloud(_ userData: UserData) {
        Task {
            await saveUserData(userData)
        }
    }
    
    // MARK: - Delete User Data
    func deleteUserData(uid: String) async {
        do {
            try await db.collection("users").document(uid).delete()
        } catch {
            print("CloudService: Failed to delete - \(error)")
        }
    }
    
    // MARK: - Merge Strategy
    func mergeData(local: SaveableUserData, cloud: SaveableUserData) -> SaveableUserData {
        var mergedProfile = local.profile
        mergedProfile.rp = max(local.profile.rp, cloud.profile.rp)
        mergedProfile.xp = max(local.profile.xp, cloud.profile.xp)
        mergedProfile.level = max(local.profile.level, cloud.profile.level)
        mergedProfile.totalRuns = max(local.profile.totalRuns, cloud.profile.totalRuns)
        mergedProfile.totalSprints = max(local.profile.totalSprints, cloud.profile.totalSprints)
        mergedProfile.totalSprintsValid = max(local.profile.totalSprintsValid, cloud.profile.totalSprintsValid)
        mergedProfile.longestStreak = max(local.profile.longestStreak, cloud.profile.longestStreak)
        mergedProfile.totalDistanceMeters = max(local.profile.totalDistanceMeters, cloud.profile.totalDistanceMeters)
        
        // Use whichever username/displayName is non-empty
        if mergedProfile.username.isEmpty { mergedProfile.username = cloud.profile.username }
        if mergedProfile.displayName == "Runner" && cloud.profile.displayName != "Runner" {
            mergedProfile.displayName = cloud.profile.displayName
        }
        
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
