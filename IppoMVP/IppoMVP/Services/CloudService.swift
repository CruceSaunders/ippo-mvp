import Foundation

/// CloudService stub - Firebase Firestore sync
/// NOTE: Requires Firebase SDK and GoogleService-Info.plist to be configured.
/// See MVP_Firebase_Setup.md for setup instructions.
///
/// Data structure in Firestore:
/// /users/{userId} -> SaveableUserData (JSON)
///
/// Sync strategy:
/// - On sign in: merge local data with cloud data (keep highest values)
/// - On every save: write to both local and cloud
/// - On app launch (if signed in): load from cloud, merge with local

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
              let userId = AuthService.shared.userId else { return nil }
        
        // TODO: Implement when Firebase is configured
        // let db = Firestore.firestore()
        // let doc = try await db.collection("users").document(userId).getDocument()
        // guard let data = doc.data() else { return nil }
        // let jsonData = try JSONSerialization.data(withJSONObject: data)
        // return try JSONDecoder().decode(SaveableUserData.self, from: jsonData)
        
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
        
        // Merge pets (union of both)
        let localPetIds = Set(local.ownedPets.map { $0.petDefinitionId })
        let cloudPetIds = Set(cloud.ownedPets.map { $0.petDefinitionId })
        var mergedPets = local.ownedPets
        for cloudPet in cloud.ownedPets {
            if !localPetIds.contains(cloudPet.petDefinitionId) {
                mergedPets.append(cloudPet)
            }
        }
        
        // Keep higher currencies
        let mergedCoins = max(local.coins, cloud.coins)
        let mergedGems = max(local.gems, cloud.gems)
        
        // Merge abilities (union of unlocked)
        var mergedAbilities = local.abilities
        mergedAbilities.unlockedPlayerAbilities = local.abilities.unlockedPlayerAbilities.union(cloud.abilities.unlockedPlayerAbilities)
        mergedAbilities.abilityPoints = max(local.abilities.abilityPoints, cloud.abilities.abilityPoints)
        mergedAbilities.petPoints = max(local.abilities.petPoints, cloud.abilities.petPoints)
        
        // Keep longer run history (union by ID)
        let localRunIds = Set(local.runHistory.map { $0.id })
        var mergedRuns = local.runHistory
        for cloudRun in cloud.runHistory {
            if !localRunIds.contains(cloudRun.id) {
                mergedRuns.append(cloudRun)
            }
        }
        mergedRuns.sort { $0.date > $1.date }
        
        return SaveableUserData(
            profile: mergedProfile,
            ownedPets: mergedPets,
            abilities: mergedAbilities,
            inventory: local.inventory, // Use local inventory
            coins: mergedCoins,
            gems: mergedGems,
            runHistory: mergedRuns,
            dailyRewards: local.dailyRewards ?? cloud.dailyRewards,
            challengeData: local.challengeData ?? cloud.challengeData,
            achievements: local.achievements ?? cloud.achievements
        )
    }
}
