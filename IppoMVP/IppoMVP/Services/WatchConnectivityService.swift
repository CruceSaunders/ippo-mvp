import Foundation
import WatchConnectivity
import Combine

// MARK: - Watch Connectivity Service (iOS Side)
@MainActor
final class WatchConnectivityService: NSObject, ObservableObject {
    static let shared = WatchConnectivityService()
    
    @Published var isReachable: Bool = false
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
    
    // MARK: - Handle Incoming Run Summary
    private func handleRunSummary(_ message: [String: Any]) {
        Task { @MainActor in
            let durationSeconds = message["durationSeconds"] as? Int ?? 0
            let distanceMeters = message["distanceMeters"] as? Double ?? 0
            let sprintsCompleted = message["sprintsCompleted"] as? Int ?? 0
            let sprintsTotal = message["sprintsTotal"] as? Int ?? 0
            let rpBoxesEarned = message["rpBoxesEarned"] as? Int ?? 0
            let xpEarned = message["xpEarned"] as? Int ?? 0
            let averageHR = message["averageHR"] as? Int ?? 0
            let totalCalories = message["totalCalories"] as? Double ?? 0
            
            // Create run record
            let run = CompletedRun(
                durationSeconds: durationSeconds,
                distanceMeters: distanceMeters,
                sprintsCompleted: sprintsCompleted,
                sprintsTotal: sprintsTotal,
                rpBoxesEarned: rpBoxesEarned,
                xpEarned: xpEarned,
                averageHR: averageHR,
                totalCalories: totalCalories
            )
            
            // Apply to user data
            let userData = UserData.shared
            userData.completeRun(run)
            
            // Add RP boxes
            userData.addRPBoxes(count: rpBoxesEarned)
        }
    }
}

// MARK: - WCSessionDelegate
extension WatchConnectivityService: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            if activationState == .activated {
                isReachable = session.isReachable
            }
        }
    }
    
    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            isReachable = session.isReachable
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
            if let type = message["type"] as? String {
                switch type {
                case "runEnded":
                    handleRunSummary(message)
                default:
                    break
                }
            }
            
            lastSyncDate = Date()
        }
    }
    
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        Task { @MainActor in
            if let type = message["type"] as? String {
                switch type {
                case "syncRequest":
                    var response: [String: Any] = ["status": "ok"]
                    if let maxHR = UserData.shared.profile.estimatedMaxHR {
                        response["estimatedMaxHR"] = maxHR
                    }
                    replyHandler(response)
                default:
                    replyHandler([:])
                }
            } else {
                replyHandler([:])
            }
        }
    }
}
