import Foundation

@MainActor
final class DataPersistence {
    static let shared = DataPersistence()
    
    private let userDataKey = "com.cruce.IppoMVP.userData.v2"
    private let legacyUserDataKey = "com.cruce.IppoMVP.userData"
    private let defaults = UserDefaults.standard
    
    private init() {}
    
    // MARK: - Save
    func saveUserData(_ userData: UserData) {
        let saveable = SaveableUserData(
            profile: userData.profile,
            pendingRPBoxes: userData.pendingRPBoxes,
            runHistory: userData.runHistory,
            friends: userData.friends,
            friendRequests: userData.friendRequests
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
        // Try v2 format first
        if let data = defaults.data(forKey: userDataKey) {
            do {
                return try JSONDecoder().decode(SaveableUserData.self, from: data)
            } catch {
                print("Failed to load v2 user data: \(error)")
            }
        }
        
        // No legacy migration for this scoped-down version
        // Old data from v1 is incompatible with new structure
        return nil
    }
    
    // MARK: - Clear
    func clearUserData() {
        defaults.removeObject(forKey: userDataKey)
        defaults.removeObject(forKey: legacyUserDataKey)
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
