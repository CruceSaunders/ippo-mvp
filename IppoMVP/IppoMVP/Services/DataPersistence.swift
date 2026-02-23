import Foundation

@MainActor
final class DataPersistence {
    static let shared = DataPersistence()

    private let userDataKey = "com.cruce.IppoMVP.userData.v3"
    private let defaults = UserDefaults.standard

    private init() {}

    func saveUserData(_ userData: UserData) {
        let saveable = SaveableUserData(
            profile: userData.profile,
            ownedPets: userData.ownedPets,
            inventory: userData.inventory,
            runHistory: userData.runHistory
        )
        do {
            let data = try JSONEncoder().encode(saveable)
            defaults.set(data, forKey: userDataKey)
        } catch {
            print("Failed to save user data: \(error)")
        }
    }

    func loadUserData() -> SaveableUserData? {
        guard let data = defaults.data(forKey: userDataKey) else { return nil }
        do {
            return try JSONDecoder().decode(SaveableUserData.self, from: data)
        } catch {
            print("Failed to load user data: \(error)")
            return nil
        }
    }

    func clearUserData() {
        defaults.removeObject(forKey: userDataKey)
    }
}
