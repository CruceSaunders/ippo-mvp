import Foundation

@MainActor
final class DataPersistence {
    static let shared = DataPersistence()
    
    private let userDataKey = "com.cruce.IppoMVP.userData"
    private let defaults = UserDefaults.standard
    
    private init() {}
    
    // MARK: - Save
    func saveUserData(_ userData: UserData) {
        let saveable = SaveableUserData(
            profile: userData.profile,
            ownedPets: userData.ownedPets,
            abilities: userData.abilities,
            inventory: userData.inventory,
            coins: userData.coins,
            gems: userData.gems,
            runHistory: userData.runHistory,
            dailyRewards: userData.dailyRewards,
            challengeData: userData.challengeData,
            achievements: userData.achievements
        )
        
        do {
            let data = try JSONEncoder().encode(saveable)
            defaults.set(data, forKey: userDataKey)
        } catch {
            print("Failed to save user data: \(error)")
        }
    }
    
    // MARK: - Load
    func loadUserData() -> SaveableUserData? {
        guard let data = defaults.data(forKey: userDataKey) else { return nil }
        
        do {
            return try JSONDecoder().decode(SaveableUserData.self, from: data)
        } catch {
            print("Failed to load user data: \(error)")
            // Try loading legacy format without new fields
            return loadLegacyUserData(data: data)
        }
    }
    
    // MARK: - Legacy Migration
    private func loadLegacyUserData(data: Data) -> SaveableUserData? {
        // Try to decode the old format and migrate
        struct LegacySaveableUserData: Codable {
            let profile: PlayerProfile
            let ownedPets: [OwnedPet]
            let abilities: UserAbilities
            let inventory: Inventory
            let coins: Int
            let gems: Int
            let runHistory: [CompletedRun]
        }
        
        do {
            let legacy = try JSONDecoder().decode(LegacySaveableUserData.self, from: data)
            return SaveableUserData(
                profile: legacy.profile,
                ownedPets: legacy.ownedPets,
                abilities: legacy.abilities,
                inventory: legacy.inventory,
                coins: legacy.coins,
                gems: legacy.gems,
                runHistory: legacy.runHistory,
                dailyRewards: nil,
                challengeData: nil,
                achievements: nil
            )
        } catch {
            print("Failed to load legacy user data: \(error)")
            return nil
        }
    }
    
    // MARK: - Clear
    func clearUserData() {
        defaults.removeObject(forKey: userDataKey)
    }
    
    // MARK: - Export/Import (for debugging)
    func exportUserData() -> Data? {
        return defaults.data(forKey: userDataKey)
    }
    
    func importUserData(_ data: Data) -> Bool {
        do {
            _ = try JSONDecoder().decode(SaveableUserData.self, from: data)
            defaults.set(data, forKey: userDataKey)
            return true
        } catch {
            print("Failed to import user data: \(error)")
            return false
        }
    }
}
