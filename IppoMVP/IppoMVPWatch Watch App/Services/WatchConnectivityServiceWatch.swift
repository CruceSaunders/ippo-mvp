import Foundation
import WatchConnectivity

@MainActor
final class WatchConnectivityServiceWatch: NSObject, ObservableObject {
    static let shared = WatchConnectivityServiceWatch()
    
    @Published var equippedPetName: String?
    @Published var equippedPetEmoji: String = "🐾"
    @Published var isConnected: Bool = false
    
    private var session: WCSession?
    
    override init() {
        super.init()
        
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }
    
    // MARK: - Send Run Summary
    func sendRunSummary(_ summary: WatchRunSummary) {
        guard let session = session, session.isReachable else {
            // Queue for later
            return
        }
        
        let payload: [String: Any] = [
            "type": "runEnded",
            "durationSeconds": summary.durationSeconds,
            "distanceMeters": summary.distanceMeters,
            "sprintsCompleted": summary.sprintsCompleted,
            "sprintsTotal": summary.sprintsTotal,
            "rpEarned": summary.rpEarned,
            "xpEarned": summary.xpEarned,
            "coinsEarned": summary.coinsEarned,
            "petCaught": summary.petCaught as Any,
            "lootBoxesEarned": summary.lootBoxesEarned
        ]
        
        session.sendMessage(payload, replyHandler: nil) { error in
            print("❌ Failed to send run summary: \(error)")
        }
    }
    
    // MARK: - Request Sync
    func requestSync() {
        guard let session = session, session.isReachable else { return }
        
        session.sendMessage(["type": "syncRequest"], replyHandler: { [weak self] response in
            Task { @MainActor in
                if let petName = response["equippedPetName"] as? String {
                    self?.equippedPetName = petName
                }
                if let emoji = response["equippedPetEmoji"] as? String {
                    self?.equippedPetEmoji = emoji
                }
            }
        }, errorHandler: { error in
            print("❌ Sync request failed: \(error)")
        })
    }
}

// MARK: - WCSessionDelegate
extension WatchConnectivityServiceWatch: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            isConnected = activationState == .activated
            if isConnected {
                requestSync()
            }
        }
    }
    
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        Task { @MainActor in
            if let type = message["type"] as? String {
                switch type {
                case "profileUpdate":
                    if let petName = message["equippedPetName"] as? String {
                        equippedPetName = petName
                    }
                    if let emoji = message["equippedPetEmoji"] as? String {
                        equippedPetEmoji = emoji
                    }
                default:
                    break
                }
            }
        }
    }
}
