import Foundation
import WatchConnectivity
import Combine

@MainActor
final class WatchConnectivityServiceWatch: NSObject, ObservableObject {
    static let shared = WatchConnectivityServiceWatch()
    
    @Published var isConnected: Bool = false
    @Published var estimatedMaxHR: Int = 0
    @Published var equippedPetName: String?
    @Published var equippedPetImageName: String?
    @Published var equippedPetMood: Int = 3
    @Published var equippedPetLevel: Int = 1
    @Published var equippedPetStageName: String = "Baby"
    var ownedPetIds: Set<String> = []
    var catchablePetIds: [String] = []
    var hasEncounterCharm: Bool = false
    var sprintsSinceLastCatch: Int = 0
    
    private var session: WCSession?
    
    override init() {
        super.init()
        
        estimatedMaxHR = UserDefaults.standard.integer(forKey: "ippo.estimatedMaxHR")
        
        #if targetEnvironment(simulator)
        isConnected = true
        #else
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
        #endif
    }
    
    // MARK: - Send Run Summary
    func sendRunSummary(_ summary: WatchRunSummary) {
        #if targetEnvironment(simulator)
        print("[Ippo Sim] Run summary: \(summary.durationSeconds)s, \(summary.sprintsCompleted) sprints, \(summary.coinsEarned) coins")
        #else
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
        payload["sprintsSinceLastCatch"] = summary.sprintsSinceLastCatch

        session.sendMessage(payload, replyHandler: nil) { error in
            print("Failed to send run summary: \(error)")
        }
        #endif
    }

    // MARK: - Request Sync (gets maxHR + pet data from phone)
    func requestSync() {
        #if targetEnvironment(simulator)
        return
        #else
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
                if let catchable = response["catchablePetIds"] as? [String] {
                    self?.catchablePetIds = catchable
                }
                if let charm = response["hasEncounterCharm"] as? Bool {
                    self?.hasEncounterCharm = charm
                }
                if let pity = response["sprintsSinceLastCatch"] as? Int {
                    self?.sprintsSinceLastCatch = pity
                }
                if let name = response["equippedPetName"] as? String {
                    self?.equippedPetName = name
                }
                if let img = response["equippedPetImageName"] as? String {
                    self?.equippedPetImageName = img
                }
                if let mood = response["equippedPetMood"] as? Int {
                    self?.equippedPetMood = mood
                }
                if let level = response["equippedPetLevel"] as? Int {
                    self?.equippedPetLevel = level
                }
                if let stage = response["equippedPetStageName"] as? String {
                    self?.equippedPetStageName = stage
                }
            }
        }, errorHandler: { error in
            print("Sync request failed: \(error)")
        })
        #endif
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
            guard let type = message["type"] as? String else { return }
            switch type {
            case "profileSync":
                if let maxHR = message["estimatedMaxHR"] as? Int, maxHR > 0 {
                    estimatedMaxHR = maxHR
                    UserDefaults.standard.set(maxHR, forKey: "ippo.estimatedMaxHR")
                }
                if let petIds = message["ownedPetIds"] as? [String] {
                    ownedPetIds = Set(petIds)
                }
                if let catchable = message["catchablePetIds"] as? [String] {
                    catchablePetIds = catchable
                }
                if let charm = message["hasEncounterCharm"] as? Bool {
                    hasEncounterCharm = charm
                }
                if let pity = message["sprintsSinceLastCatch"] as? Int {
                    sprintsSinceLastCatch = pity
                }
                if let name = message["equippedPetName"] as? String {
                    equippedPetName = name
                }
                if let img = message["equippedPetImageName"] as? String {
                    equippedPetImageName = img
                }
                if let mood = message["equippedPetMood"] as? Int {
                    equippedPetMood = mood
                }
                if let level = message["equippedPetLevel"] as? Int {
                    equippedPetLevel = level
                }
                if let stage = message["equippedPetStageName"] as? String {
                    equippedPetStageName = stage
                }
            case "hapticBuzz":
                WatchHapticsManager.shared.playSprintStart()
            default:
                break
            }
        }
    }
}
