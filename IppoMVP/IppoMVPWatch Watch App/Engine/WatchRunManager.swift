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

struct WatchRunSummary {
    let durationSeconds: Int
    let distanceMeters: Double
    let sprintsCompleted: Int
    let sprintsTotal: Int
    let rpEarned: Int
    let xpEarned: Int
    let coinsEarned: Int
    let petCaught: String?
    let lootBoxesEarned: [String]
}

@MainActor
final class WatchRunManager: NSObject, ObservableObject {
    static let shared = WatchRunManager()
    
    // MARK: - Published State
    @Published var runState: WatchRunState = .idle
    @Published var isPaused: Bool = false
    @Published var elapsedTime: TimeInterval = 0
    @Published var currentHR: Int = 0
    @Published var currentCadence: Int = 0
    @Published var totalSprints: Int = 0
    @Published var sprintsCompleted: Int = 0
    @Published var isInRecovery: Bool = false
    @Published var recoveryRemaining: TimeInterval = 0
    @Published var sprintTimeRemaining: TimeInterval = 0
    @Published var sprintProgress: Double = 0
    @Published var runSummary: WatchRunSummary?
    
    // MARK: - Internal State
    private var runStartTime: Date?
    private var runTimer: Timer?
    private var lastEncounterTime: Date?
    private var encounterCheckTimer: Timer?
    private var recoveryEndTime: Date?
    private var sprintStartTime: Date?
    private var targetSprintDuration: TimeInterval = 35
    private var sprintTimer: Timer?
    private var baselineHR: Int = 0
    private var sprintHRSamples: [Int] = []
    private var sprintCadenceSamples: [Int] = []
    private var peakHR: Int = 0
    private var peakCadence: Int = 0
    
    // HealthKit
    private let healthStore = HKHealthStore()
    private var workoutSession: HKWorkoutSession?
    private var workoutBuilder: HKLiveWorkoutBuilder?
    
    // Rewards accumulator
    private var earnedRP: Int = 0
    private var earnedXP: Int = 0
    private var earnedCoins: Int = 0
    private var earnedLootBoxes: [String] = []
    private var caughtPetId: String?
    
    // Config
    private let sprintConfig = WatchSprintConfig()
    private let encounterConfig = WatchEncounterConfig()
    
    // MARK: - Computed
    var formattedDuration: String {
        let minutes = Int(elapsedTime) / 60
        let seconds = Int(elapsedTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: - Init
    override init() {
        super.init()
        requestHealthKitPermissions()
    }
    
    // MARK: - HealthKit
    private func requestHealthKitPermissions() {
        let typesToShare: Set<HKSampleType> = [HKWorkoutType.workoutType()]
        let typesToRead: Set<HKObjectType> = [
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .stepCount)!,
            HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
        ]
        
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, error in
            if let error = error {
                print("❌ HealthKit auth error: \(error)")
            }
        }
    }
    
    // MARK: - Run Lifecycle
    func startRun() {
        runStartTime = Date()
        elapsedTime = 0
        totalSprints = 0
        sprintsCompleted = 0
        earnedRP = 0
        earnedXP = 0
        earnedCoins = 0
        earnedLootBoxes = []
        caughtPetId = nil
        isPaused = false
        
        runState = .running
        
        // Start workout session
        startWorkoutSession()
        
        // Start timers
        runTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor [weak self] in
                self?.updateRunTimer()
            }
        }
        
        // Start encounter checks after warmup
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(self?.encounterConfig.warmupDuration ?? 60) * 1_000_000_000)
            self?.startEncounterChecks()
        }
        
        // Play start haptic
        WatchHapticsManager.shared.playRunStart()
    }
    
    func pauseRun() {
        isPaused.toggle()
        if isPaused {
            runTimer?.invalidate()
            encounterCheckTimer?.invalidate()
        } else {
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
        
        // End workout
        endWorkoutSession()
        
        // Calculate passive rewards
        let minutes = Int(elapsedTime / 60)
        let passiveRP = minutes * Int.random(in: 1...2)
        let passiveXP = minutes * Int.random(in: 2...4)
        earnedRP += passiveRP
        earnedXP += passiveXP
        
        // Create summary
        runSummary = WatchRunSummary(
            durationSeconds: Int(elapsedTime),
            distanceMeters: 0,  // Would come from workout
            sprintsCompleted: sprintsCompleted,
            sprintsTotal: totalSprints,
            rpEarned: earnedRP,
            xpEarned: earnedXP,
            coinsEarned: earnedCoins,
            petCaught: caughtPetId,
            lootBoxesEarned: earnedLootBoxes
        )
        
        // Send to phone
        WatchConnectivityServiceWatch.shared.sendRunSummary(runSummary!)
        
        runState = .summary
        WatchHapticsManager.shared.playRunEnd()
    }
    
    func resetToIdle() {
        runState = .idle
        runSummary = nil
        elapsedTime = 0
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
                    print("❌ Failed to begin workout: \(error)")
                }
            }
        } catch {
            print("❌ Failed to start workout: \(error)")
        }
    }
    
    private func endWorkoutSession() {
        workoutSession?.end()
        let builder = workoutBuilder
        builder?.endCollection(withEnd: Date()) { success, error in
            builder?.finishWorkout { workout, error in
                if let error = error {
                    print("❌ Failed to finish workout: \(error)")
                }
            }
        }
    }
    
    // MARK: - Timer Updates
    private func updateRunTimer() {
        guard !isPaused else { return }
        elapsedTime += 1
        
        // Update recovery
        if isInRecovery, let endTime = recoveryEndTime {
            recoveryRemaining = max(0, endTime.timeIntervalSinceNow)
            if recoveryRemaining <= 0 {
                isInRecovery = false
            }
        }
    }
    
    // MARK: - Encounter System
    private func startEncounterChecks() {
        encounterCheckTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
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
        
        // Get probability
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
        sprintCadenceSamples = []
        peakHR = 0
        peakCadence = 0
        
        runState = .sprinting
        sprintStartTime = Date()
        
        // Play sprint start haptic
        WatchHapticsManager.shared.playSprintStart()
        
        // Start sprint timer
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
        
        // Collect samples
        sprintHRSamples.append(currentHR)
        sprintCadenceSamples.append(currentCadence)
        peakHR = max(peakHR, currentHR)
        peakCadence = max(peakCadence, currentCadence)
        
        // Last 5 seconds tick
        if sprintTimeRemaining <= 5 && sprintTimeRemaining > 0 && Int(sprintTimeRemaining * 10) % 10 == 0 {
            WatchHapticsManager.shared.playTick()
        }
        
        if sprintTimeRemaining <= 0 {
            completeSprint()
        }
    }
    
    private func completeSprint() {
        sprintTimer?.invalidate()
        
        // Validate sprint
        let isValid = validateSprint()
        
        if isValid {
            sprintsCompleted += 1
            
            // Calculate rewards
            let rp = Int.random(in: 15...25)
            let xp = Int.random(in: 30...50)
            let coins = Int.random(in: 40...80)
            earnedRP += rp
            earnedXP += xp
            earnedCoins += coins
            
            // Roll for loot box
            if Double.random(in: 0...1) < 0.70 {
                let rarity = rollLootBoxRarity()
                earnedLootBoxes.append(rarity)
            }
            
            // Check for pet catch
            checkForPetCatch()
            
            WatchHapticsManager.shared.playSprintSuccess()
        } else {
            WatchHapticsManager.shared.playSprintFail()
        }
        
        // Play sprint end haptic
        WatchHapticsManager.shared.playSprintEnd()
        
        // Start recovery
        startRecovery()
        
        // Return to running state
        runState = .running
        startEncounterChecks()
    }
    
    private func validateSprint() -> Bool {
        guard !sprintHRSamples.isEmpty else { return false }
        
        // HR Score
        let hrIncrease = peakHR - baselineHR
        let hrScore = min(1.0, Double(hrIncrease) / 20.0)
        
        // Cadence Score (using peak cadence for validation)
        let cadenceScore = min(1.0, Double(peakCadence) / 160.0)
        
        // Combined score
        let totalScore = (hrScore * 0.50 + cadenceScore * 0.35 + 0.15) * 100
        
        return totalScore >= 60
    }
    
    private func rollLootBoxRarity() -> String {
        let roll = Double.random(in: 0...1)
        if roll < 0.55 { return "common" }
        if roll < 0.80 { return "uncommon" }
        if roll < 0.92 { return "rare" }
        if roll < 0.98 { return "epic" }
        return "legendary"
    }
    
    private func checkForPetCatch() {
        // Simplified catch check - would need pet count from phone
        let catchRate = 0.03  // Default rate
        if Double.random(in: 0...1) < catchRate {
            // Random pet ID
            let petIds = ["pet_01", "pet_02", "pet_03", "pet_04", "pet_05",
                         "pet_06", "pet_07", "pet_08", "pet_09", "pet_10"]
            caughtPetId = petIds.randomElement()
            
            if caughtPetId != nil {
                WatchHapticsManager.shared.playPetCatch()
                earnedRP += 100
                earnedXP += 200
                earnedCoins += 500
            }
        }
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
        // Handle state changes
    }
    
    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("❌ Workout session failed: \(error)")
    }
}

// MARK: - HKLiveWorkoutBuilderDelegate
extension WatchRunManager: HKLiveWorkoutBuilderDelegate {
    nonisolated func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        // Handle events
    }
    
    nonisolated func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType else { continue }
            
            let statistics = workoutBuilder.statistics(for: quantityType)
            
            Task { @MainActor in
                if quantityType == HKQuantityType.quantityType(forIdentifier: .heartRate) {
                    let value = statistics?.mostRecentQuantity()?.doubleValue(for: HKUnit.count().unitDivided(by: .minute())) ?? 0
                    self.currentHR = Int(value)
                }
            }
        }
    }
}

// MARK: - Watch Configs
struct WatchSprintConfig {
    let minDuration: TimeInterval = 30
    let maxDuration: TimeInterval = 45
    let recoveryDuration: TimeInterval = 45
}

struct WatchEncounterConfig {
    let warmupDuration: TimeInterval = 60
    let pityTimerMax: TimeInterval = 180
    
    func probability(forTimeSinceLastSprint time: TimeInterval) -> Double {
        switch time {
        case 60..<90: return 0.02
        case 90..<120: return 0.05
        case 120..<150: return 0.08
        case 150..<180: return 0.12
        default: return time >= 180 ? 1.0 : 0.15
        }
    }
}
