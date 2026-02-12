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
    private let petConfig = PetConfig.shared
    
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
    var onPetCaught: ((String) -> Void)?
    
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
        checkTimer = Timer.scheduledTimer(withTimeInterval: config.probabilityCheckInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
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
            timeSince = runDuration  // First encounter considers full run time
        }
        
        timeSinceLastEncounter = timeSince
        
        // Check minimum time between encounters
        guard timeSince >= config.minimumTimeBetweenEncounters else { return }
        
        // Get probability and roll
        let probability = config.probability(forTimeSinceLastSprint: timeSince)
        let roll = Double.random(in: 0...1)
        
        // Apply Zephyr bonus if equipped
        var modifiedProbability = probability
        if let equippedPet = UserData.shared.equippedPet,
           let def = equippedPet.definition,
           def.id == "pet_04" {
            // Zephyr's Tailwind: +10% encounter chance
            let effectiveness = equippedPet.abilityEffectiveness
            modifiedProbability += 0.10 * effectiveness
        }
        
        if roll < modifiedProbability || timeSince >= config.pityTimerMax {
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
            rewards = calculateRewards(for: result)
            encounter.rewards = rewards
            
            // Check for pet catch
            if let petCatch = checkForPetCatch() {
                encounter.petCaught = petCatch
                rewards?.petCaught = petCatch
                onPetCaught?(petCatch)
            }
        }
        
        currentEncounter = encounter
        isEncounterActive = false
        
        // Apply rewards to user data
        if let r = rewards {
            applyRewards(r)
        }
        
        onEncounterComplete?(result, rewards)
        
        // Start recovery period
        startRecovery()
    }
    
    // MARK: - Calculate Rewards
    private func calculateRewards(for result: SprintResult) -> SprintRewards {
        let baseRewards = RewardsConfig.shared.baseSprintRewards()
        let userData = UserData.shared
        
        // Gather bonuses
        var rpBonus = userData.abilities.rpBonusTotal
        var xpBonus = userData.abilities.xpBonusTotal
        var coinBonus = userData.abilities.coinBonusTotal
        let allBonus = 0.0  // From Champion ability, already included
        
        // Pet ability bonuses
        if let equippedPet = userData.equippedPet,
           let def = equippedPet.definition {
            let effectiveness = equippedPet.abilityEffectiveness
            
            switch def.id {
            case "pet_01":  // Ember: +15% RP on short sprints
                if result.duration < 35 {
                    rpBonus += 0.15 * effectiveness
                }
            case "pet_09":  // Blaze: +30% RP on long sprints
                if result.duration > 40 {
                    rpBonus += 0.30 * effectiveness
                }
            default:
                break
            }
        }
        
        // Apply bonuses
        let finalRewards = RewardsConfig.shared.applyBonuses(
            base: baseRewards,
            rpBonus: rpBonus,
            xpBonus: xpBonus,
            coinBonus: coinBonus,
            allBonus: allBonus,
            streakDays: userData.profile.currentStreak
        )
        
        // Roll for loot box
        let lootBox = config.rollLootBoxRarity()
        
        return SprintRewards(
            rp: finalRewards.rp,
            xp: finalRewards.xp,
            coins: finalRewards.coins,
            lootBox: lootBox
        )
    }
    
    // MARK: - Pet Catch
    private func checkForPetCatch() -> String? {
        let userData = UserData.shared
        let petsOwned = userData.petsOwnedCount
        
        // Check if all pets owned
        guard petsOwned < 10 else { return nil }
        
        // Calculate catch rate with bonuses
        var bonusCatchRate = userData.abilities.catchRateBonusTotal
        
        // Shadow's Stealth: +5% catch rate
        if let equippedPet = userData.equippedPet,
           let def = equippedPet.definition,
           def.id == "pet_07" {
            let effectiveness = equippedPet.abilityEffectiveness
            bonusCatchRate += 0.05 * effectiveness
        }
        
        // Roll for catch
        if petConfig.shouldCatchPet(petsOwned: petsOwned, bonusCatchRate: bonusCatchRate) {
            // Select random unowned pet
            if let petDef = GameData.shared.randomUnownedPet(ownedPetIds: userData.ownedPetIds) {
                return petDef.id
            }
        }
        
        return nil
    }
    
    // MARK: - Apply Rewards
    private func applyRewards(_ rewards: SprintRewards) {
        let userData = UserData.shared
        
        userData.addRP(rewards.rp)
        userData.addXP(rewards.xp)
        userData.addCoins(rewards.coins)
        
        if let lootBox = rewards.lootBox {
            userData.addLootBox(lootBox)
        }
        
        if let petId = rewards.petCaught {
            _ = userData.addPet(petId)
        }
        
        // Add XP to equipped pet
        if let petId = userData.equippedPet?.id {
            userData.addPetXP(petId, xp: PetConfig.shared.xpPerCompletedSprint)
        }
    }
    
    // MARK: - Recovery Period
    private func startRecovery() {
        isInRecovery = true
        recoveryEndTime = Date().addingTimeInterval(SprintConfig.shared.recoveryDuration)
        recoveryTimeRemaining = SprintConfig.shared.recoveryDuration
        
        recoveryTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
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
