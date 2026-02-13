import Foundation
import WatchConnectivity
import Combine

@MainActor
final class WatchConnectivityServiceWatch: NSObject, ObservableObject {
    static let shared = WatchConnectivityServiceWatch()
    
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
            "rpBoxesEarned": summary.rpBoxesEarned,
            "xpEarned": summary.xpEarned
        ]
        
        session.sendMessage(payload, replyHandler: nil) { error in
            print("Failed to send run summary: \(error)")
        }
    }
    
    // MARK: - Request Sync
    func requestSync() {
        guard let session = session, session.isReachable else { return }
        
        session.sendMessage(["type": "syncRequest"], replyHandler: { _ in
            // No pet data to sync anymore
        }, errorHandler: { error in
            print("Sync request failed: \(error)")
        })
    }
}

// MARK: - WCSessionDelegate
extension WatchConnectivityServiceWatch: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            isConnected = activationState == .activated
        }
    }
    
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        // Handle incoming messages from phone if needed
    }
}
