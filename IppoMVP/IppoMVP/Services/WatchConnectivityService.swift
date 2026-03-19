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
            "sprintsSinceLastCatch": userData.profile.sprintsSinceLastCatch
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

    private func handleRunSummary(_ message: [String: Any]) {
        Task { @MainActor in
            let durationSeconds = message["durationSeconds"] as? Int ?? 0
            let distanceMeters = message["distanceMeters"] as? Double ?? 0
            let sprintsCompleted = message["sprintsCompleted"] as? Int ?? 0
            let coinsEarned = message["coinsEarned"] as? Int ?? 0
            let xpEarned = message["xpEarned"] as? Int ?? 0
            let petCaughtId = message["petCaughtId"] as? String

            let run = CompletedRun(
                durationSeconds: durationSeconds,
                distanceMeters: distanceMeters,
                sprintsCompleted: sprintsCompleted,
                coinsEarned: coinsEarned,
                xpEarned: xpEarned,
                petCaughtId: petCaughtId
            )

            let userData = UserData.shared
            // Add pet BEFORE completeRun so firstCatch milestone (ownedPets.count == 2) triggers correctly
            if let petId = petCaughtId {
                userData.addPet(definitionId: petId)
            }
            userData.completeRun(run)

            if let pityCount = message["sprintsSinceLastCatch"] as? Int {
                userData.profile.sprintsSinceLastCatch = pityCount
                userData.save()
            }

            userData.pendingRunSummary = run
        }
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
                let userData = UserData.shared
                var response: [String: Any] = [
                    "status": "ok",
                    "estimatedMaxHR": userData.profile.estimatedMaxHR
                ]
                let petIds = userData.ownedPets.map { $0.petDefinitionId }
                response["ownedPetIds"] = petIds
                response["catchablePetIds"] = GameData.catchablePetIds
                response["hasEncounterCharm"] = userData.inventory.activeEncounterCharm != nil
                response["sprintsSinceLastCatch"] = userData.profile.sprintsSinceLastCatch

                if let pet = userData.equippedPet, let def = pet.definition {
                    response["equippedPetName"] = def.name
                    response["equippedPetImageName"] = pet.currentImageName
                    response["equippedPetMood"] = pet.mood
                    response["equippedPetLevel"] = pet.level
                    response["equippedPetStageName"] = pet.stageName
                }

                replyHandler(response)
            } else {
                replyHandler([:])
            }
        }
    }
}
