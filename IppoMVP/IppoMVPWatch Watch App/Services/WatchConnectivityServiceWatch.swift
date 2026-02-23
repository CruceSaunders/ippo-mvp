import Foundation
import WatchConnectivity
import Combine

@MainActor
final class WatchConnectivityServiceWatch: NSObject, ObservableObject {
    static let shared = WatchConnectivityServiceWatch()
    
    @Published var isConnected: Bool = false
    @Published var estimatedMaxHR: Int = 0
    var ownedPetIds: Set<String> = []
    
    private var session: WCSession?
    
    override init() {
        super.init()
        
        // Load cached maxHR
        estimatedMaxHR = UserDefaults.standard.integer(forKey: "ippo.estimatedMaxHR")
        
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }
    
    // MARK: - Send Run Summary
    func sendRunSummary(_ summary: WatchRunSummary) {
        guard let session = session, session.isReachable else { return }
        
        var payload: [String: Any] = [
            "type": "runEnded",
            "durationSeconds": summary.durationSeconds,
            "distanceMeters": summary.distanceMeters,
            "sprintsCompleted": summary.sprintsCompleted,
            "sprintsTotal": summary.sprintsTotal,
            "coinsEarned": summary.coinsEarned,
            "xpEarned": summary.xpEarned,
            "averageHR": summary.averageHR,
            "totalCalories": summary.totalCalories
        ]
        if let petId = summary.petCaughtId {
            payload["petCaughtId"] = petId
        }
        
        session.sendMessage(payload, replyHandler: nil) { error in
            print("Failed to send run summary: \(error)")
        }
    }
    
    // MARK: - Request Sync (gets maxHR from phone)
    func requestSync() {
        guard let session = session, session.isReachable else { return }
        
        session.sendMessage(["type": "syncRequest"], replyHandler: { [weak self] response in
            Task { @MainActor in
                if let maxHR = response["estimatedMaxHR"] as? Int, maxHR > 0 {
                    self?.estimatedMaxHR = maxHR
                    UserDefaults.standard.set(maxHR, forKey: "ippo.estimatedMaxHR")
                }
                if let petIds = response["ownedPetIds"] as? [String] {
                    self?.ownedPetIds = Set(petIds)
                }
            }
        }, errorHandler: { error in
            print("Sync request failed: \(error)")
        })
    }
    
    /// HR Zone 4 threshold (80% of max HR)
    var hrZone4Threshold: Int {
        guard estimatedMaxHR > 0 else { return 0 }
        return Int(Double(estimatedMaxHR) * 0.80)
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
            if let type = message["type"] as? String, type == "profileSync" {
                if let maxHR = message["estimatedMaxHR"] as? Int, maxHR > 0 {
                    estimatedMaxHR = maxHR
                    UserDefaults.standard.set(maxHR, forKey: "ippo.estimatedMaxHR")
                }
            }
        }
    }
}
