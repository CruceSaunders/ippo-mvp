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
    var encountersToday: Int = 0
    var newPetsAddedToday: Int = 0
    
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
        print("[Ippo Sim] Run summary: \(summary.durationSeconds)s, \(summary.sprintsCompleted) sprints, \(summary.coinsEarned) coins, \(summary.petEncounters.count) encounters")
        #else
        guard let session = session else { return }

        var payload: [String: Any] = [
            "type": "runEnded",
            "durationSeconds": summary.durationSeconds,
            "distanceMeters": summary.distanceMeters,
            "sprintsCompleted": summary.sprintsCompleted,
            "sprintsTotal": summary.sprintsTotal,
            "coinsEarned": summary.coinsEarned,
            "xpEarned": summary.xpEarned,
            "averageHR": summary.averageHR,
            "totalCalories": summary.totalCalories,
            "sprintsSinceLastCatch": summary.sprintsSinceLastCatch,
            "petEncounters": summary.petEncounters.map { $0.toDictionary() }
        ]

        if session.isReachable {
            session.sendMessage(payload, replyHandler: nil) { [weak self] error in
                print("sendMessage failed, falling back to transferUserInfo: \(error)")
                self?.session?.transferUserInfo(payload)
            }
        } else {
            session.transferUserInfo(payload)
        }
        #endif
    }

    // MARK: - Request Sync (gets maxHR + pet data from phone)
    private var syncRetryCount = 0
    private let maxSyncRetries = 3

    func requestSync() {
        #if targetEnvironment(simulator)
        return
        #else
        guard let session = session else { return }
        guard session.isReachable else {
            retrySyncAfterDelay()
            return
        }

        session.sendMessage(["type": "syncRequest"], replyHandler: { [weak self] response in
            Task { @MainActor in
                self?.syncRetryCount = 0
                self?.applySyncResponse(response)
            }
        }, errorHandler: { [weak self] error in
            print("Sync request failed: \(error)")
            Task { @MainActor in
                self?.retrySyncAfterDelay()
            }
        })
        #endif
    }

    private func retrySyncAfterDelay() {
        guard syncRetryCount < maxSyncRetries else {
            syncRetryCount = 0
            return
        }
        syncRetryCount += 1
        let delay = Double(syncRetryCount) * 5.0
        Task {
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            await MainActor.run { requestSync() }
        }
    }

    private func applySyncResponse(_ response: [String: Any]) {
        if let maxHR = response["estimatedMaxHR"] as? Int, maxHR > 0 {
            estimatedMaxHR = maxHR
            UserDefaults.standard.set(maxHR, forKey: "ippo.estimatedMaxHR")
        }
        if let petIds = response["ownedPetIds"] as? [String] {
            ownedPetIds = Set(petIds)
        }
        if let catchable = response["catchablePetIds"] as? [String] {
            catchablePetIds = catchable
        }
        if let charm = response["hasEncounterCharm"] as? Bool {
            hasEncounterCharm = charm
        }
        if let pity = response["sprintsSinceLastCatch"] as? Int {
            sprintsSinceLastCatch = pity
        }
        if let enc = response["encountersToday"] as? Int {
            encountersToday = enc
        }
        if let newPets = response["newPetsAddedToday"] as? Int {
            newPetsAddedToday = newPets
        }
        if let name = response["equippedPetName"] as? String {
            equippedPetName = name
        }
        if let img = response["equippedPetImageName"] as? String {
            equippedPetImageName = img
        }
        if let mood = response["equippedPetMood"] as? Int {
            equippedPetMood = mood
        }
        if let level = response["equippedPetLevel"] as? Int {
            equippedPetLevel = level
        }
        if let stage = response["equippedPetStageName"] as? String {
            equippedPetStageName = stage
        }
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
                applySyncResponse(message)
            case "hapticBuzz":
                WatchHapticsManager.shared.playSprintStart()
            default:
                break
            }
        }
    }
}
