import Foundation
import FirebaseFirestore

@MainActor
final class CloudService {
    static let shared = CloudService()

    private let db = Firestore.firestore()

    private init() {}

    // MARK: - Save
    func saveUserData(_ userData: UserData) async {
        guard AuthService.shared.isAuthenticated,
              let uid = AuthService.shared.userId else { return }

        let saveable = SaveableUserData(
            profile: userData.profile,
            ownedPets: userData.ownedPets,
            inventory: userData.inventory,
            runHistory: userData.runHistory
        )

        do {
            let data = try JSONEncoder().encode(saveable)
            guard var dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }

            dict["searchFields"] = [
                "displayName": userData.profile.displayName,
                "username": userData.profile.username.lowercased(),
                "level": userData.profile.level,
                "petsOwned": userData.activePets.count
            ] as [String: Any]

            try await db.collection("users").document(uid).setData(dict, merge: true)
        } catch {
            print("CloudService: Failed to save - \(error)")
        }
    }

    func syncToCloud(_ userData: UserData) {
        Task { await saveUserData(userData) }
    }

    // MARK: - Load
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

    // MARK: - Merge
    func mergeData(local: SaveableUserData, cloud: SaveableUserData) -> SaveableUserData {
        // Pick the profile that reflects the most recent activity.
        // Use totalRuns as primary, lastRunDate as tiebreaker, and always
        // carry forward whichever has the higher cumulative stats.
        let mergedProfile: PlayerProfile
        if local.profile.totalRuns >= cloud.profile.totalRuns {
            var p = local.profile
            p.longestStreak = max(local.profile.longestStreak, cloud.profile.longestStreak)
            p.totalDistanceMeters = max(local.profile.totalDistanceMeters, cloud.profile.totalDistanceMeters)
            p.totalDurationSeconds = max(local.profile.totalDurationSeconds, cloud.profile.totalDurationSeconds)
            mergedProfile = p
        } else {
            var p = cloud.profile
            p.longestStreak = max(local.profile.longestStreak, cloud.profile.longestStreak)
            // Preserve local lastRunDate if it's more recent
            if let localDate = local.profile.lastRunDate,
               let cloudDate = cloud.profile.lastRunDate,
               localDate > cloudDate {
                p.lastRunDate = localDate
                p.currentStreak = max(local.profile.currentStreak, cloud.profile.currentStreak)
            }
            if let localInteraction = local.profile.lastInteractionDate,
               let cloudInteraction = cloud.profile.lastInteractionDate,
               localInteraction > cloudInteraction {
                p.lastInteractionDate = localInteraction
            }
            mergedProfile = p
        }

        var mergedPets = local.ownedPets
        for cloudPet in cloud.ownedPets {
            if !mergedPets.contains(where: { $0.petDefinitionId == cloudPet.petDefinitionId }) {
                var pet = cloudPet
                pet.isEquipped = false
                mergedPets.append(pet)
            }
        }
        if let equippedId = mergedProfile.equippedPetId {
            for i in mergedPets.indices {
                mergedPets[i].isEquipped = (mergedPets[i].id == equippedId)
            }
        } else {
            for i in mergedPets.indices {
                mergedPets[i].isEquipped = false
            }
        }

        var mergedBoosts = local.inventory.activeBoosts
        for cloudBoost in cloud.inventory.activeBoosts {
            if !mergedBoosts.contains(where: { $0.type == cloudBoost.type }) {
                mergedBoosts.append(cloudBoost)
            } else if let idx = mergedBoosts.firstIndex(where: { $0.type == cloudBoost.type }),
                      cloudBoost.expiresAt > mergedBoosts[idx].expiresAt {
                mergedBoosts[idx] = cloudBoost
            }
        }

        let mergedInventory = PlayerInventory(
            food: max(local.inventory.food, cloud.inventory.food),
            water: max(local.inventory.water, cloud.inventory.water),
            activeBoosts: mergedBoosts,
            hibernationEndsAt: local.inventory.hibernationEndsAt ?? cloud.inventory.hibernationEndsAt,
            streakFreezeEndsAt: local.inventory.streakFreezeEndsAt ?? cloud.inventory.streakFreezeEndsAt
        )

        var mergedRuns = local.runHistory
        for cloudRun in cloud.runHistory {
            if !mergedRuns.contains(where: { $0.id == cloudRun.id }) {
                mergedRuns.append(cloudRun)
            }
        }
        mergedRuns.sort { $0.date > $1.date }
        if mergedRuns.count > 50 { mergedRuns = Array(mergedRuns.prefix(50)) }

        return SaveableUserData(
            profile: mergedProfile,
            ownedPets: mergedPets,
            inventory: mergedInventory,
            runHistory: mergedRuns
        )
    }

    // MARK: - Username Uniqueness

    func isUsernameTaken(_ username: String) async -> Bool {
        let normalized = username.lowercased().trimmingCharacters(in: .whitespaces)
        guard !normalized.isEmpty else { return true }

        do {
            let snapshot = try await db.collection("usernames")
                .document(normalized)
                .getDocument()
            let exists = snapshot.exists
            let data = snapshot.data()
            let ownerUid = data?["uid"] as? String
            let myUid = AuthService.shared.userId
            let isTaken: Bool
            if exists, let ownerUid {
                isTaken = ownerUid != myUid
            } else {
                isTaken = false
            }
            return isTaken
        } catch {
            print("CloudService: Failed to check username - \(error)")
            return true
        }
    }

    func reserveUsername(_ username: String) async -> Bool {
        let normalized = username.lowercased().trimmingCharacters(in: .whitespaces)
        guard !normalized.isEmpty,
              let uid = AuthService.shared.userId else { return false }

        do {
            let oldUsername = await loadCurrentUsername(uid: uid)
            let batch = db.batch()

            if let old = oldUsername, !old.isEmpty, old != normalized {
                let oldRef = db.collection("usernames").document(old)
                batch.deleteDocument(oldRef)
            }

            let newRef = db.collection("usernames").document(normalized)
            batch.setData([
                "uid": uid,
                "createdAt": FieldValue.serverTimestamp()
            ], forDocument: newRef)

            try await batch.commit()
            return true
        } catch {
            print("CloudService: Failed to reserve username - \(error)")
            return false
        }
    }

    private func loadCurrentUsername(uid: String) async -> String? {
        do {
            let doc = try await db.collection("users").document(uid).getDocument()
            guard let data = doc.data(),
                  let searchFields = data["searchFields"] as? [String: Any],
                  let username = searchFields["username"] as? String else { return nil }
            return username
        } catch {
            return nil
        }
    }

    // MARK: - Delete
    func deleteUserData(uid: String? = nil) async {
        let targetUid = uid ?? AuthService.shared.userId
        guard let targetUid else { return }
        do {
            try await db.collection("users").document(targetUid).delete()
        } catch {
            print("CloudService: Failed to delete - \(error)")
        }
    }
}
