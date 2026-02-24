import Foundation
import Combine

@MainActor
final class EncounterManager: ObservableObject {
    static let shared = EncounterManager()
    
    // MARK: - Published State
    @Published private(set) var isEncounterActive: Bool = false
    @Published private(set) var currentEncounter: Encounter?
    @Published private(set) var timeSinceLastEncounter: TimeInterval = 0
    @Published private(set) var isInRecovery: Bool = false
    @Published private(set) var recoveryTimeRemaining: TimeInterval = 0
    
    // MARK: - Dependencies
    private let config = EncounterConfig.shared
    
    // MARK: - Internal State
    private var runStartTime: Date?
    private var lastEncounterTime: Date?
    private var lastCheckTime: Date?
    private var recoveryEndTime: Date?
    private var checkTimer: Timer?
    private var recoveryTimer: Timer?
    
    // Callbacks
    var onEncounterTriggered: (() -> Void)?
    var onEncounterComplete: ((SprintResult, SprintRewards?) -> Void)?
    
    // MARK: - Init
    private init() {}
    
    // MARK: - Run Lifecycle
    func startRun() {
        runStartTime = Date()
        lastEncounterTime = nil
        lastCheckTime = Date()
        isEncounterActive = false
        isInRecovery = false
        
        // Start probability check timer
        checkTimer = Timer.scheduledTimer(withTimeInterval: config.probabilityCheckInterval, repeats: true) { _ in
            Task { @MainActor [weak self] in
                self?.checkForEncounter()
            }
        }
    }
    
    func endRun() {
        checkTimer?.invalidate()
        recoveryTimer?.invalidate()
        checkTimer = nil
        recoveryTimer = nil
        runStartTime = nil
        isEncounterActive = false
        isInRecovery = false
    }
    
    // MARK: - Encounter Check
    private func checkForEncounter() {
        guard !isEncounterActive && !isInRecovery else { return }
        guard let runStart = runStartTime else { return }
        
        let runDuration = Date().timeIntervalSince(runStart)
        
        // Must complete warmup first
        guard runDuration >= config.warmupDuration else { return }
        
        // Calculate time since last encounter
        let timeSince: TimeInterval
        if let lastEnc = lastEncounterTime {
            timeSince = Date().timeIntervalSince(lastEnc)
        } else {
            timeSince = runDuration
        }
        
        timeSinceLastEncounter = timeSince
        
        // Check minimum time between encounters
        guard timeSince >= config.minimumTimeBetweenEncounters else { return }
        
        // Get probability and roll
        let probability = config.probability(forTimeSinceLastSprint: timeSince)
        let roll = Double.random(in: 0...1)
        
        if roll < probability || timeSince >= config.pityTimerMax {
            triggerEncounter()
        }
    }
    
    // MARK: - Trigger Encounter
    func triggerEncounter() {
        guard !isEncounterActive else { return }
        
        currentEncounter = Encounter()
        isEncounterActive = true
        lastEncounterTime = Date()
        
        onEncounterTriggered?()
    }
    
    // MARK: - Complete Encounter
    func completeEncounter(result: SprintResult) {
        guard isEncounterActive, var encounter = currentEncounter else { return }
        
        encounter.sprintResult = result
        
        var rewards: SprintRewards?

        if result.isValid {
            let coins = Int.random(in: 8...12)
            let xp = Int.random(in: 15...25)
            rewards = SprintRewards(coins: coins, xp: xp)
            encounter.coinsEarned = coins
            encounter.xpEarned = xp
        }

        currentEncounter = encounter
        isEncounterActive = false

        if let r = rewards {
            applyRewards(r)
        }

        onEncounterComplete?(result, rewards)
        
        // Start recovery period
        startRecovery()
    }
    
    // MARK: - Apply Rewards
    private func applyRewards(_ rewards: SprintRewards) {
        let userData = UserData.shared
        if rewards.coins > 0 {
            userData.addCoins(rewards.coins)
        }
        if rewards.xp > 0 {
            userData.addXP(rewards.xp)
        }
    }
    
    // MARK: - Recovery Period
    private func startRecovery() {
        isInRecovery = true
        recoveryEndTime = Date().addingTimeInterval(SprintConfig.shared.recoveryDuration)
        recoveryTimeRemaining = SprintConfig.shared.recoveryDuration
        
        recoveryTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor [weak self] in
                self?.updateRecovery()
            }
        }
    }
    
    private func updateRecovery() {
        guard let endTime = recoveryEndTime else { return }
        
        recoveryTimeRemaining = endTime.timeIntervalSinceNow
        
        if recoveryTimeRemaining <= 0 {
            endRecovery()
        }
    }
    
    private func endRecovery() {
        recoveryTimer?.invalidate()
        recoveryTimer = nil
        isInRecovery = false
        recoveryTimeRemaining = 0
    }
    
    // MARK: - Debug
    #if DEBUG
    func debugTriggerEncounter() {
        triggerEncounter()
    }
    #endif
}
