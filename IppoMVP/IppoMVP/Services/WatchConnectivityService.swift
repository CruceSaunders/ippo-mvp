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

    func pushProfileToWatch() {
        guard let session = session, session.isReachable else { return }
        let maxHR = UserData.shared.profile.estimatedMaxHR
        session.sendMessage(
            ["type": "profileSync", "estimatedMaxHR": maxHR],
            replyHandler: nil,
            errorHandler: { error in
                print("Failed to push profile to Watch: \(error)")
            }
        )
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
            userData.completeRun(run)

            if let petId = petCaughtId {
                userData.addPet(definitionId: petId)
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

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        Task { @MainActor in
            if let type = message["type"] as? String, type == "syncRequest" {
                var response: [String: Any] = [
                    "status": "ok",
                    "estimatedMaxHR": UserData.shared.profile.estimatedMaxHR
                ]
                let petIds = UserData.shared.ownedPets.map { $0.petDefinitionId }
                response["ownedPetIds"] = petIds
                replyHandler(response)
            } else {
                replyHandler([:])
            }
        }
    }
}
