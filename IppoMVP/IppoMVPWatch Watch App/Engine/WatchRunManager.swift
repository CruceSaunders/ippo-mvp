import Foundation
import Combine
import WatchKit
import HealthKit

enum WatchRunState {
    case idle
    case running
    case sprinting
    case summary
}

struct WatchPetEncounter {
    let petId: String
    let isNew: Bool
    let bonusXP: Int

    func toDictionary() -> [String: Any] {
        ["petId": petId, "isNew": isNew, "bonusXP": bonusXP]
    }
}

struct WatchRunSummary {
    let durationSeconds: Int
    let distanceMeters: Double
    let sprintsCompleted: Int
    let sprintsTotal: Int
    let coinsEarned: Int
    let xpEarned: Int
    let averageHR: Int
    let totalCalories: Double
    let petEncounters: [WatchPetEncounter]
    let sprintsSinceLastCatch: Int
}

@MainActor
final class WatchRunManager: NSObject, ObservableObject {
    static let shared = WatchRunManager()

    static var isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
    
    // MARK: - Published State
    @Published var runState: WatchRunState = .idle
    @Published var isPaused: Bool = false
    @Published var elapsedTime: TimeInterval = 0
    @Published var currentHR: Int = 0
    @Published var currentDistance: Double = 0
    @Published var currentCalories: Double = 0
    @Published var totalSprints: Int = 0
    @Published var sprintsCompleted: Int = 0
    @Published var isInRecovery: Bool = false
    @Published var recoveryRemaining: TimeInterval = 0
    @Published var sprintTimeRemaining: TimeInterval = 0
    @Published var sprintProgress: Double = 0
    @Published var runSummary: WatchRunSummary?
    @Published var lastSprintSuccess: Bool = false
    @Published var showSprintResult: Bool = false
    
    // MARK: - HealthKit Authorization State
    @Published var healthKitAuthorized: Bool = false
    @Published var healthKitError: String?
    
    // MARK: - Encounter feedback
    @Published var didCatchPet: Bool = false
    @Published var caughtPetName: String?
    @Published var lastEncounterWasDuplicate: Bool = false
    
    // MARK: - Internal State
    private var runStartTime: Date?
    private var runTimer: Timer?
    private var lastEncounterTime: Date?
    private var encounterCheckTimer: Timer?
    private var recoveryEndTime: Date?
    private var totalPausedDuration: TimeInterval = 0
    private var pauseStartTime: Date?
    private var sprintStartTime: Date?
    private var targetSprintDuration: TimeInterval = 35
    private var sprintTimer: Timer?
    private var baselineHR: Int = 0
    private var sprintHRSamples: [Int] = []
    private var peakHR: Int = 0
    private var allHRSamples: [Int] = []
    
    // HealthKit
    private let healthStore = HKHealthStore()
    private var workoutSession: HKWorkoutSession?
    private var workoutBuilder: HKLiveWorkoutBuilder?
    
    // Rewards accumulator
    private var earnedCoins: Int = 0
    private var earnedXP: Int = 0
    private var petEncounters: [WatchPetEncounter] = []
    private var sprintsSinceLastCatch: Int = 0
    
    // Daily limits (synced from phone at run start, updated during run)
    private var encountersToday: Int = 0
    private var newPetsToday: Int = 0
    
    // Config
    private let sprintConfig = WatchSprintConfig()
    private let encounterConfig = WatchEncounterConfig()
    private let catchConfig = WatchCatchConfig()
    
    // MARK: - Computed Properties
    var formattedDuration: String {
        let hours = Int(elapsedTime) / 3600
        let minutes = (Int(elapsedTime) % 3600) / 60
        let seconds = Int(elapsedTime) % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var formattedDistance: String {
        let miles = currentDistance / 1609.34
        if miles < 0.01 { return "0.00 mi" }
        return String(format: "%.2f mi", miles)
    }
    
    var formattedPace: String {
        guard currentDistance > 80 else { return "--:--" }
        let miles = currentDistance / 1609.34
        let minutesPerMile = (elapsedTime / 60.0) / miles
        guard minutesPerMile.isFinite && minutesPerMile > 0 && minutesPerMile < 60 else { return "--:--" }
        let paceMinutes = Int(minutesPerMile)
        let paceSeconds = Int((minutesPerMile - Double(paceMinutes)) * 60)
        return String(format: "%d:%02d", paceMinutes, paceSeconds)
    }
    
    var formattedCalories: String {
        if currentCalories < 1 { return "0" }
        return String(format: "%.0f", currentCalories)
    }
    
    var averageHR: Int {
        guard !allHRSamples.isEmpty else { return 0 }
        return allHRSamples.reduce(0, +) / allHRSamples.count
    }
    
    // MARK: - Init
    override init() {
        super.init()
        checkAndRequestHealthKit()
    }
    
    // MARK: - HealthKit Authorization
    
    func checkAndRequestHealthKit() {
        if Self.isSimulator {
            healthKitAuthorized = true
            healthKitError = nil
            return
        }

        let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let distType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
        let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        
        let hrStatus = healthStore.authorizationStatus(for: hrType)
        let distStatus = healthStore.authorizationStatus(for: distType)
        let energyStatus = healthStore.authorizationStatus(for: energyType)
        
        if hrStatus == .sharingAuthorized && distStatus == .sharingAuthorized && energyStatus == .sharingAuthorized {
            healthKitAuthorized = true
            return
        }
        
        requestHealthKitPermissions()
    }
    
    func requestHealthKitPermissions() {
        if Self.isSimulator {
            healthKitAuthorized = true
            healthKitError = nil
            return
        }

        let typesToShare: Set<HKSampleType> = [
            HKWorkoutType.workoutType(),
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        ]
        let typesToRead: Set<HKObjectType> = [
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        ]
        
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, error in
            let errorMessage = error?.localizedDescription
            Task { @MainActor [weak self] in
                guard let self else { return }
                if success {
                    let hrStatus = self.healthStore.authorizationStatus(for: HKQuantityType.quantityType(forIdentifier: .heartRate)!)
                    self.healthKitAuthorized = (hrStatus == .sharingAuthorized)
                    
                    if !self.healthKitAuthorized {
                        self.healthKitError = "Please enable Health access in Settings > Privacy > Health > Ippo"
                    } else {
                        self.healthKitError = nil
                    }
                } else {
                    self.healthKitAuthorized = false
                    self.healthKitError = errorMessage ?? "Health access denied"
                }
            }
        }
    }
    
    // MARK: - Run Lifecycle
    func startRun() {
        guard healthKitAuthorized else {
            healthKitError = "Health access required. Please grant permissions."
            requestHealthKitPermissions()
            return
        }
        
        runStartTime = Date()
        elapsedTime = 0
        currentDistance = 0
        currentCalories = 0
        currentHR = 0
        allHRSamples = []
        totalSprints = 0
        sprintsCompleted = 0
        earnedCoins = 0
        earnedXP = 0
        petEncounters = []
        didCatchPet = false
        caughtPetName = nil
        lastEncounterWasDuplicate = false
        isPaused = false
        lastEncounterTime = nil
        isInRecovery = false
        recoveryRemaining = 0
        totalPausedDuration = 0
        pauseStartTime = nil
        encounterCheckTimer?.invalidate()

        let connectivity = WatchConnectivityServiceWatch.shared
        sprintsSinceLastCatch = connectivity.sprintsSinceLastCatch
        encountersToday = connectivity.encountersToday
        newPetsToday = connectivity.newPetsAddedToday
        
        runState = .running
        
        if !Self.isSimulator {
            startWorkoutSession()
        }
        
        runTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor [weak self] in
                self?.updateRunTimer()
            }
        }
        
        let warmup = Self.isSimulator ? 5.0 : (encounterConfig.warmupDuration)
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(warmup) * 1_000_000_000)
            self?.startEncounterChecks()
        }
        
        WatchHapticsManager.shared.playRunStart()
    }
    
    func pauseRun() {
        isPaused.toggle()
        if isPaused {
            pauseStartTime = Date()
            runTimer?.invalidate()
            encounterCheckTimer?.invalidate()
        } else {
            if let start = pauseStartTime {
                totalPausedDuration += Date().timeIntervalSince(start)
                pauseStartTime = nil
            }
            runTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                guard let self else { return }
                Task { @MainActor [weak self] in
                    self?.updateRunTimer()
                }
            }
            startEncounterChecks()
        }
    }
    
    func endRun() {
        runTimer?.invalidate()
        encounterCheckTimer?.invalidate()
        sprintTimer?.invalidate()
        
        let finalDistance = readFinalDistance()
        let finalCalories = readFinalCalories()
        
        if !Self.isSimulator {
            endWorkoutSession()
        }
        
        runSummary = WatchRunSummary(
            durationSeconds: Int(elapsedTime),
            distanceMeters: finalDistance,
            sprintsCompleted: sprintsCompleted,
            sprintsTotal: totalSprints,
            coinsEarned: earnedCoins,
            xpEarned: earnedXP,
            averageHR: averageHR,
            totalCalories: finalCalories,
            petEncounters: petEncounters,
            sprintsSinceLastCatch: sprintsSinceLastCatch
        )
        
        WatchConnectivityServiceWatch.shared.sendRunSummary(runSummary!)
        
        runState = .summary
        WatchHapticsManager.shared.playRunEnd()
    }
    
    func resetToIdle() {
        runState = .idle
        runSummary = nil
        elapsedTime = 0
        currentDistance = 0
        currentCalories = 0
        currentHR = 0
        allHRSamples = []
    }
    
    // MARK: - Read Final Metrics
    private func readFinalDistance() -> Double {
        guard let builder = workoutBuilder else { return currentDistance }
        let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
        if let stats = builder.statistics(for: distanceType),
           let sum = stats.sumQuantity() {
            return sum.doubleValue(for: .meter())
        }
        return currentDistance
    }
    
    private func readFinalCalories() -> Double {
        guard let builder = workoutBuilder else { return currentCalories }
        let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        if let stats = builder.statistics(for: energyType),
           let sum = stats.sumQuantity() {
            return sum.doubleValue(for: .kilocalorie())
        }
        return currentCalories
    }
    
    // MARK: - Workout Session
    private func startWorkoutSession() {
        let config = HKWorkoutConfiguration()
        config.activityType = .running
        config.locationType = .outdoor
        
        do {
            workoutSession = try HKWorkoutSession(healthStore: healthStore, configuration: config)
            workoutBuilder = workoutSession?.associatedWorkoutBuilder()
            workoutBuilder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: config)
            
            workoutSession?.delegate = self
            workoutBuilder?.delegate = self
            
            workoutSession?.startActivity(with: Date())
            workoutBuilder?.beginCollection(withStart: Date()) { success, error in
                if let error = error {
                    print("[Ippo] Failed to begin workout collection: \(error)")
                } else {
                    print("[Ippo] Workout collection started successfully: \(success)")
                }
            }
        } catch {
            print("[Ippo] Failed to start workout session: \(error)")
        }
    }
    
    private func endWorkoutSession() {
        workoutSession?.end()
        let builder = workoutBuilder
        builder?.endCollection(withEnd: Date()) { success, error in
            builder?.finishWorkout { workout, error in
                if let error = error {
                    print("[Ippo] Failed to finish workout: \(error)")
                }
            }
        }
    }
    
    // MARK: - Timer Updates
    private func updateRunTimer() {
        guard !isPaused, let startTime = runStartTime else { return }
        elapsedTime = Date().timeIntervalSince(startTime) - totalPausedDuration

        if currentHR > 0 {
            allHRSamples.append(currentHR)
        }

        if isInRecovery, let endTime = recoveryEndTime {
            recoveryRemaining = max(0, endTime.timeIntervalSinceNow)
            if recoveryRemaining <= 0 {
                isInRecovery = false
            }
        }
    }
    
    // MARK: - Encounter System
    private func startEncounterChecks() {
        encounterCheckTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor [weak self] in
                self?.checkForEncounter()
            }
        }
    }
    
    private func checkForEncounter() {
        guard runState == .running && !isInRecovery && !isPaused else { return }
        
        let timeSinceLast: TimeInterval
        if let lastTime = lastEncounterTime {
            timeSinceLast = Date().timeIntervalSince(lastTime)
        } else {
            timeSinceLast = elapsedTime
        }
        
        let probability = encounterConfig.probability(forTimeSinceLastSprint: timeSinceLast)
        let roll = Double.random(in: 0...1)
        
        if roll < probability || timeSinceLast >= encounterConfig.pityTimerMax {
            triggerSprint()
        }
    }
    
    // MARK: - Sprint System
    private func triggerSprint() {
        encounterCheckTimer?.invalidate()
        lastEncounterTime = Date()
        totalSprints += 1
        
        targetSprintDuration = TimeInterval.random(in: sprintConfig.minDuration...sprintConfig.maxDuration)
        sprintTimeRemaining = targetSprintDuration
        sprintProgress = 0
        baselineHR = currentHR
        sprintHRSamples = []
        peakHR = 0
        
        runState = .sprinting
        sprintStartTime = Date()
        
        WatchHapticsManager.shared.playSprintStart()
        
        sprintTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor [weak self] in
                self?.updateSprint()
            }
        }
    }
    
    private func updateSprint() {
        guard let startTime = sprintStartTime else { return }
        
        let elapsed = Date().timeIntervalSince(startTime)
        sprintTimeRemaining = max(0, targetSprintDuration - elapsed)
        sprintProgress = min(1.0, elapsed / targetSprintDuration)
        
        sprintHRSamples.append(currentHR)
        peakHR = max(peakHR, currentHR)
        
        if sprintTimeRemaining <= 5 && sprintTimeRemaining > 0 && Int(sprintTimeRemaining * 10) % 10 == 0 {
            WatchHapticsManager.shared.playTick()
        }
        
        if sprintTimeRemaining <= 0 {
            completeSprint()
        }
    }
    
    private func completeSprint() {
        sprintTimer?.invalidate()

        let isValid = validateSprint()
        lastSprintSuccess = isValid
        didCatchPet = false
        caughtPetName = nil
        lastEncounterWasDuplicate = false

        if isValid {
            sprintsCompleted += 1
            let sprintCoins = Int.random(in: 8...12)
            let sprintXP = Int.random(in: 15...25)
            earnedCoins += sprintCoins
            earnedXP += sprintXP

            sprintsSinceLastCatch += 1

            if encountersToday < catchConfig.maxEncountersPerDay {
                let starterIds: Set<String> = ["pet_01", "pet_02", "pet_03"]
                let hasOnlyStarters = WatchConnectivityServiceWatch.shared.ownedPetIds.subtracting(starterIds).isEmpty
                let isFirstRunEver = hasOnlyStarters && petEncounters.isEmpty && totalSprints <= 1

                let baseCatch: Double = WatchConnectivityServiceWatch.shared.hasEncounterCharm
                    ? catchConfig.charmCatchRate
                    : catchConfig.baseCatchRate

                let catchRate: Double
                if isFirstRunEver {
                    catchRate = 1.0
                } else if sprintsSinceLastCatch >= catchConfig.pityGuaranteedAt {
                    catchRate = 1.0
                } else if sprintsSinceLastCatch >= catchConfig.pityEscalationStart {
                    let progress = Double(sprintsSinceLastCatch - catchConfig.pityEscalationStart)
                        / Double(catchConfig.pityGuaranteedAt - catchConfig.pityEscalationStart)
                    catchRate = baseCatch + (1.0 - baseCatch) * progress
                } else {
                    catchRate = baseCatch
                }

                let roll = Double.random(in: 0...1)
                if roll < catchRate {
                    attemptCatch()
                }
            }

            if !didCatchPet {
                WatchHapticsManager.shared.playSprintSuccess()
            }
        } else {
            WatchHapticsManager.shared.playSprintFail()
        }

        WatchHapticsManager.shared.playSprintEnd()
        runState = .running
        showSprintResult = true

        startRecovery()
        startEncounterChecks()

        let delay: UInt64 = didCatchPet ? 5_000_000_000 : (isValid ? 4_000_000_000 : 3_000_000_000)
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: delay)
            showSprintResult = false
            didCatchPet = false
            lastEncounterWasDuplicate = false
        }
    }

    private func attemptCatch() {
        let connectivity = WatchConnectivityServiceWatch.shared

        guard let caughtId = selectRandomPet() else { return }

        let isOwned = connectivity.ownedPetIds.contains(caughtId)

        if isOwned {
            let encounter = WatchPetEncounter(
                petId: caughtId,
                isNew: false,
                bonusXP: catchConfig.duplicateBonusXP
            )
            petEncounters.append(encounter)
            earnedXP += catchConfig.duplicateBonusXP
            encountersToday += 1
            sprintsSinceLastCatch = 0
            didCatchPet = true
            lastEncounterWasDuplicate = true
            WatchHapticsManager.shared.playPetCatch()
        } else if newPetsToday < catchConfig.maxNewPetsPerDay {
            let encounter = WatchPetEncounter(petId: caughtId, isNew: true, bonusXP: 0)
            petEncounters.append(encounter)
            encountersToday += 1
            newPetsToday += 1
            sprintsSinceLastCatch = 0
            earnedCoins += 25
            connectivity.ownedPetIds.insert(caughtId)
            didCatchPet = true
            lastEncounterWasDuplicate = false
            WatchHapticsManager.shared.playPetCatch()
        } else {
            // New-pet daily limit reached — treat as duplicate for XP
            let encounter = WatchPetEncounter(
                petId: caughtId,
                isNew: false,
                bonusXP: catchConfig.duplicateBonusXP
            )
            petEncounters.append(encounter)
            earnedXP += catchConfig.duplicateBonusXP
            encountersToday += 1
            sprintsSinceLastCatch = 0
            didCatchPet = true
            lastEncounterWasDuplicate = true
            WatchHapticsManager.shared.playPetCatch()
        }
    }

    private func selectRandomPet() -> String? {
        let catchable = WatchConnectivityServiceWatch.shared.catchablePetIds
        guard !catchable.isEmpty else { return nil }
        return catchable.randomElement()
    }
    
    private func validateSprint() -> Bool {
        if Self.isSimulator { return true }
        guard !sprintHRSamples.isEmpty else { return false }
        
        var zone4Threshold = WatchConnectivityServiceWatch.shared.hrZone4Threshold
        if zone4Threshold <= 0 {
            zone4Threshold = Int(Double(220 - 25) * 0.80)
        }
        return peakHR >= zone4Threshold
    }
    
    private func startRecovery() {
        isInRecovery = true
        recoveryEndTime = Date().addingTimeInterval(sprintConfig.recoveryDuration)
        recoveryRemaining = sprintConfig.recoveryDuration
    }
}

// MARK: - HKWorkoutSessionDelegate
extension WatchRunManager: HKWorkoutSessionDelegate {
    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        print("[Ippo] Workout state: \(fromState.rawValue) -> \(toState.rawValue)")
    }
    
    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("[Ippo] Workout session failed: \(error)")
    }
}

// MARK: - HKLiveWorkoutBuilderDelegate
extension WatchRunManager: HKLiveWorkoutBuilderDelegate {
    nonisolated func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}
    
    nonisolated func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType else { continue }
            
            let statistics = workoutBuilder.statistics(for: quantityType)
            let identifier = quantityType.identifier
            
            Task { @MainActor in
                if identifier == HKQuantityTypeIdentifier.heartRate.rawValue {
                    let value = statistics?.mostRecentQuantity()?.doubleValue(
                        for: HKUnit.count().unitDivided(by: .minute())
                    ) ?? 0
                    if value > 0 {
                        self.currentHR = Int(value)
                    }
                } else if identifier == HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue {
                    if let sum = statistics?.sumQuantity() {
                        self.currentDistance = sum.doubleValue(for: .meter())
                    }
                } else if identifier == HKQuantityTypeIdentifier.activeEnergyBurned.rawValue {
                    if let sum = statistics?.sumQuantity() {
                        self.currentCalories = sum.doubleValue(for: .kilocalorie())
                    }
                }
            }
        }
    }
}

// MARK: - Watch Configs
struct WatchSprintConfig {
    let minDuration: TimeInterval = 25
    let maxDuration: TimeInterval = 40
    let recoveryDuration: TimeInterval = 45
}

struct WatchEncounterConfig {
    let warmupDuration: TimeInterval = 60
    let pityTimerMax: TimeInterval = 180

    func probability(forTimeSinceLastSprint time: TimeInterval) -> Double {
        switch time {
        case ..<60:     return 0.0
        case 60..<90:   return 0.002
        case 90..<120:  return 0.005
        case 120..<150: return 0.0083
        case 150..<180: return 0.0128
        default:        return time >= 180 ? 1.0 : 0.0
        }
    }
}

struct WatchCatchConfig {
    let baseCatchRate: Double = 0.20
    let charmCatchRate: Double = 0.25
    let pityEscalationStart: Int = 8
    let pityGuaranteedAt: Int = 10
    let duplicateBonusXP: Int = 30
    let maxEncountersPerDay: Int = 3
    let maxNewPetsPerDay: Int = 2
}
