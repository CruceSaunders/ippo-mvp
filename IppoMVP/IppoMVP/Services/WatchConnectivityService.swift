import Foundation
import WatchConnectivity
import Combine

// MARK: - Message Types
enum WatchMessageType: String, Codable {
    case runStarted
    case runEnded
    case sprintResult
    case petCaught
    case syncRequest
    case syncResponse
    case profileUpdate
}

struct WatchMessage: Codable {
    let type: WatchMessageType
    let payload: Data?
    let timestamp: Date
    
    init(type: WatchMessageType, payload: Data? = nil) {
        self.type = type
        self.payload = payload
        self.timestamp = Date()
    }
}

// MARK: - Run Summary (from Watch)
struct RunSummaryPayload: Codable {
    let durationSeconds: Int
    let distanceMeters: Double
    let sprintsCompleted: Int
    let sprintsTotal: Int
    let rpEarned: Int
    let xpEarned: Int
    let coinsEarned: Int
    let petCaught: String?
    let lootBoxesEarned: [String]  // Rarity raw values
}

// MARK: - Watch Connectivity Service
@MainActor
final class WatchConnectivityService: NSObject, ObservableObject {
    static let shared = WatchConnectivityService()
    
    @Published var isReachable: Bool = false
    @Published var lastSyncDate: Date?
    @Published var pendingMessages: [WatchMessage] = []
    
    private var session: WCSession?
    
    override init() {
        super.init()
        
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }
    
    // MARK: - Send Message
    func send(_ message: WatchMessage, replyHandler: ((Data?) -> Void)? = nil) {
        guard let session = session, session.isReachable else {
            // Queue for later
            pendingMessages.append(message)
            return
        }
        
        do {
            let data = try JSONEncoder().encode(message)
            let dict: [String: Any] = ["message": data]
            
            if let handler = replyHandler {
                session.sendMessage(dict, replyHandler: { reply in
                    if let replyData = reply["response"] as? Data {
                        handler(replyData)
                    }
                }, errorHandler: { error in
                    print("❌ Watch message failed: \(error)")
                })
            } else {
                session.sendMessage(dict, replyHandler: nil, errorHandler: { error in
                    print("❌ Watch message failed: \(error)")
                })
            }
        } catch {
            print("❌ Failed to encode message: \(error)")
        }
    }
    
    // MARK: - Send Queued Messages
    func sendPendingMessages() {
        guard let session = session, session.isReachable else { return }
        
        let messages = pendingMessages
        pendingMessages.removeAll()
        
        for message in messages {
            send(message)
        }
    }
    
    // MARK: - Sync Profile to Watch
    func syncProfileToWatch() {
        Task { @MainActor in
            let userData = UserData.shared
            let profileData = try? JSONEncoder().encode(userData.profile)
            let message = WatchMessage(type: .profileUpdate, payload: profileData)
            send(message)
        }
    }
    
    // MARK: - Handle Incoming Run Summary
    private func handleRunSummary(_ data: Data) {
        Task { @MainActor in
            guard let payload = try? JSONDecoder().decode(RunSummaryPayload.self, from: data) else { return }
            
            // Convert loot boxes
            let lootBoxes = payload.lootBoxesEarned.compactMap { Rarity(rawValue: $0) }
            
            // Create run record
            let run = CompletedRun(
                durationSeconds: payload.durationSeconds,
                distanceMeters: payload.distanceMeters,
                sprintsCompleted: payload.sprintsCompleted,
                sprintsTotal: payload.sprintsTotal,
                rpEarned: payload.rpEarned,
                xpEarned: payload.xpEarned,
                coinsEarned: payload.coinsEarned,
                petCaught: payload.petCaught,
                lootBoxesEarned: lootBoxes
            )
            
            // Apply to user data
            let userData = UserData.shared
            userData.completeRun(run)
            userData.addRP(payload.rpEarned)
            userData.addXP(payload.xpEarned)
            userData.addCoins(payload.coinsEarned)
            
            for rarity in lootBoxes {
                userData.addLootBox(rarity)
            }
            
            // Handle pet catch
            if let petId = payload.petCaught {
                _ = userData.addPet(petId)
            }
        }
    }
}

// MARK: - WCSessionDelegate
extension WatchConnectivityService: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            if activationState == .activated {
                isReachable = session.isReachable
                sendPendingMessages()
            }
        }
    }
    
    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            isReachable = session.isReachable
            if isReachable {
                sendPendingMessages()
            }
        }
    }
    
    #if os(iOS)
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}
    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    #endif
    
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        guard let data = message["message"] as? Data,
              let watchMessage = try? JSONDecoder().decode(WatchMessage.self, from: data) else { return }
        
        Task { @MainActor in
            switch watchMessage.type {
            case .runEnded:
                if let payload = watchMessage.payload {
                    handleRunSummary(payload)
                }
            case .petCaught:
                if let payload = watchMessage.payload,
                   let petId = String(data: payload, encoding: .utf8) {
                    _ = UserData.shared.addPet(petId)
                }
            case .syncRequest:
                syncProfileToWatch()
            default:
                break
            }
            
            lastSyncDate = Date()
        }
    }
    
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        // Handle messages that expect a reply
        Task { @MainActor in
            guard let data = message["message"] as? Data,
                  let watchMessage = try? JSONDecoder().decode(WatchMessage.self, from: data) else {
                replyHandler([:])
                return
            }
            
            switch watchMessage.type {
            case .syncRequest:
                // Send back user profile
                if let profileData = try? JSONEncoder().encode(UserData.shared.profile) {
                    replyHandler(["response": profileData])
                } else {
                    replyHandler([:])
                }
            default:
                replyHandler([:])
            }
        }
    }
}
