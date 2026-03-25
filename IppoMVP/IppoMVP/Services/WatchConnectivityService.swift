import Foundation
import WatchConnectivity
import Combine

@MainActor
final class WatchConnectivityService: NSObject, ObservableObject {
    static let shared = WatchConnectivityService()

    @Published var isReachable: Bool = false
    @Published var isPaired: Bool = false
    @Published var isWatchAppInstalled: Bool = false
    @Published var lastSyncDate: Date?

    private var session: WCSession?

    override init() {
        super.init()
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }

    func refreshStatus() {
        guard let session = session, session.activationState == .activated else { return }
        isPaired = session.isPaired
        isWatchAppInstalled = session.isWatchAppInstalled
        isReachable = session.isReachable
    }

    func pushProfileToWatch() {
        guard let session = session, session.isReachable else { return }
        let userData = UserData.shared
        var payload: [String: Any] = [
            "type": "profileSync",
            "estimatedMaxHR": userData.profile.estimatedMaxHR,
            "hasEncounterCharm": userData.inventory.activeEncounterCharm != nil,
            "sprintsSinceLastCatch": userData.profile.sprintsSinceLastCatch,
            "encountersToday": userData.encountersToday,
            "newPetsAddedToday": userData.newPetsAddedToday
        ]

        if let pet = userData.equippedPet, let def = pet.definition {
            payload["equippedPetName"] = def.name
            payload["equippedPetImageName"] = pet.currentImageName
            payload["equippedPetMood"] = pet.mood
            payload["equippedPetLevel"] = pet.level
            payload["equippedPetStageName"] = pet.stageName
        }

        let petIds = userData.ownedPets.map { $0.petDefinitionId }
        payload["ownedPetIds"] = petIds
        payload["catchablePetIds"] = GameData.catchablePetIds

        session.sendMessage(
            payload,
            replyHandler: nil,
            errorHandler: { error in
                print("Failed to push profile to Watch: \(error)")
            }
        )
    }

    func sendHapticBuzz() {
        guard let session = session, session.isReachable else { return }
        session.sendMessage(["type": "hapticBuzz"], replyHandler: nil, errorHandler: nil)
    }

    private func parseEncounters(from message: [String: Any]) -> [PetEncounterResult] {
        guard let rawEncounters = message["petEncounters"] as? [[String: Any]] else {
            // Legacy fallback: single petCaughtId
            if let legacyId = message["petCaughtId"] as? String {
                return [PetEncounterResult(petId: legacyId, isNew: true, bonusXP: 0)]
            }
            return []
        }
        return rawEncounters.compactMap { dict in
            guard let petId = dict["petId"] as? String,
                  let isNew = dict["isNew"] as? Bool,
                  let bonusXP = dict["bonusXP"] as? Int else { return nil }
            return PetEncounterResult(petId: petId, isNew: isNew, bonusXP: bonusXP)
        }
    }

    private func handleRunSummary(_ message: [String: Any]) {
        Task { @MainActor in
            let durationSeconds = message["durationSeconds"] as? Int ?? 0
            let distanceMeters = message["distanceMeters"] as? Double ?? 0
            let sprintsCompleted = message["sprintsCompleted"] as? Int ?? 0
            let coinsEarned = message["coinsEarned"] as? Int ?? 0
            let xpEarned = message["xpEarned"] as? Int ?? 0
            let encounters = parseEncounters(from: message)

            let run = CompletedRun(
                durationSeconds: durationSeconds,
                distanceMeters: distanceMeters,
                sprintsCompleted: sprintsCompleted,
                coinsEarned: coinsEarned,
                xpEarned: xpEarned,
                petEncounters: encounters
            )

            let userData = UserData.shared

            for encounter in encounters {
                if encounter.isNew {
                    userData.addPet(definitionId: encounter.petId)
                } else {
                    userData.addXPToPet(definitionId: encounter.petId, amount: encounter.bonusXP)
                }
            }

            userData.completeRun(run)

            if let pityCount = message["sprintsSinceLastCatch"] as? Int {
                userData.profile.sprintsSinceLastCatch = pityCount
                userData.save()
            }

            userData.pendingRunSummary = run
        }
    }

    private func buildSyncResponse() -> [String: Any] {
        let userData = UserData.shared
        var response: [String: Any] = [
            "status": "ok",
            "estimatedMaxHR": userData.profile.estimatedMaxHR,
            "hasEncounterCharm": userData.inventory.activeEncounterCharm != nil,
            "sprintsSinceLastCatch": userData.profile.sprintsSinceLastCatch,
            "encountersToday": userData.encountersToday,
            "newPetsAddedToday": userData.newPetsAddedToday
        ]
        let petIds = userData.ownedPets.map { $0.petDefinitionId }
        response["ownedPetIds"] = petIds
        response["catchablePetIds"] = GameData.catchablePetIds

        if let pet = userData.equippedPet, let def = pet.definition {
            response["equippedPetName"] = def.name
            response["equippedPetImageName"] = pet.currentImageName
            response["equippedPetMood"] = pet.mood
            response["equippedPetLevel"] = pet.level
            response["equippedPetStageName"] = pet.stageName
        }

        return response
    }
}

// MARK: - WCSessionDelegate
extension WatchConnectivityService: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            if activationState == .activated {
                isReachable = session.isReachable
                isPaired = session.isPaired
                isWatchAppInstalled = session.isWatchAppInstalled
            }
        }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            isReachable = session.isReachable
            isPaired = session.isPaired
            isWatchAppInstalled = session.isWatchAppInstalled
        }
    }

    #if os(iOS)
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}
    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    #endif

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        Task { @MainActor in
            if let type = message["type"] as? String, type == "runEnded" {
                handleRunSummary(message)
            }
            lastSyncDate = Date()
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        Task { @MainActor in
            if let type = userInfo["type"] as? String, type == "runEnded" {
                handleRunSummary(userInfo)
            }
            lastSyncDate = Date()
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        Task { @MainActor in
            if let type = message["type"] as? String, type == "syncRequest" {
                replyHandler(buildSyncResponse())
            } else {
                replyHandler([:])
            }
        }
    }
}
