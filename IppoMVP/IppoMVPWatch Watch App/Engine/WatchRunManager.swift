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
    let rpBoxesEarned: Int
    let xpEarned: Int
    let averageHR: Int
    let totalCalories: Double
}

@MainActor
final class WatchRunManager: NSObject, ObservableObject {
    static let shared = WatchRunManager()
    
    // MARK: - Published State
    @Published var runState: WatchRunState = .idle
    @Published var isPaused: Bool = false
    @Published var elapsedTime: TimeInterval = 0
    @Published var currentHR: Int = 0
    @Published var currentDistance: Double = 0      // meters
    @Published var currentCalories: Double = 0      // kcal
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
    private var peakHR: Int = 0
    private var allHRSamples: [Int] = []
    
    // HealthKit
    private let healthStore = HKHealthStore()
    private var workoutSession: HKWorkoutSession?
    private var workoutBuilder: HKLiveWorkoutBuilder?
    
    // Rewards accumulator
    private var earnedRPBoxes: Int = 0
    private var earnedXP: Int = 0
    
    // Config
    private let sprintConfig = WatchSprintConfig()
    private let encounterConfig = WatchEncounterConfig()
    
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
    
    /// Distance in miles
    var formattedDistance: String {
        let miles = currentDistance / 1609.34
        if miles < 0.01 { return "0.00 mi" }
        return String(format: "%.2f mi", miles)
    }
    
    /// Current pace in min/mile
    var formattedPace: String {
        guard currentDistance > 80 else { return "--:--" } // Need ~0.05 mi for meaningful pace
        let miles = currentDistance / 1609.34
        let minutesPerMile = (elapsedTime / 60.0) / miles
        guard minutesPerMile.isFinite && minutesPerMile > 0 && minutesPerMile < 60 else { return "--:--" }
        let paceMinutes = Int(minutesPerMile)
        let paceSeconds = Int((minutesPerMile - Double(paceMinutes)) * 60)
        return String(format: "%d:%02d", paceMinutes, paceSeconds)
    }
    
    /// Formatted calories
    var formattedCalories: String {
        if currentCalories < 1 { return "0" }
        return String(format: "%.0f", currentCalories)
    }
    
    /// Average HR from all samples during the run
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
    
    /// Check current authorization and request if needed
    func checkAndRequestHealthKit() {
        let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let distType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
        let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        
        // Check if already authorized
        let hrStatus = healthStore.authorizationStatus(for: hrType)
        let distStatus = healthStore.authorizationStatus(for: distType)
        let energyStatus = healthStore.authorizationStatus(for: energyType)
        
        if hrStatus == .sharingAuthorized && distStatus == .sharingAuthorized && energyStatus == .sharingAuthorized {
            healthKitAuthorized = true
            return
        }
        
        // Request authorization
        requestHealthKitPermissions()
    }
    
    /// Request HealthKit permissions
    func requestHealthKitPermissions() {
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
        
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { [weak self] success, error in
            Task { @MainActor in
                if success {
                    // Re-check actual status (requestAuthorization returns true even if user denied)
                    let hrStatus = self?.healthStore.authorizationStatus(for: HKQuantityType.quantityType(forIdentifier: .heartRate)!)
                    self?.healthKitAuthorized = (hrStatus == .sharingAuthorized)
                    
                    if self?.healthKitAuthorized == false {
                        self?.healthKitError = "Please enable Health access in Settings > Privacy > Health > Ippo"
                    } else {
                        self?.healthKitError = nil
                    }
                } else {
                    self?.healthKitAuthorized = false
                    self?.healthKitError = error?.localizedDescription ?? "Health access denied"
                }
            }
        }
    }
    
    // MARK: - Run Lifecycle
    func startRun() {
        // Gate on HealthKit authorization
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
        earnedRPBoxes = 0
        earnedXP = 0
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
        
        // Grab final metrics from workout builder before ending
        let finalDistance = readFinalDistance()
        let finalCalories = readFinalCalories()
        
        // End workout
        endWorkoutSession()
        
        let minutes = Int(elapsedTime / 60)
        earnedXP = minutes
        
        runSummary = WatchRunSummary(
            durationSeconds: Int(elapsedTime),
            distanceMeters: finalDistance,
            sprintsCompleted: sprintsCompleted,
            sprintsTotal: totalSprints,
            rpBoxesEarned: earnedRPBoxes,
            xpEarned: earnedXP,
            averageHR: averageHR,
            totalCalories: finalCalories
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
        guard !isPaused else { return }
        elapsedTime += 1
        
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
        
        if isValid {
            sprintsCompleted += 1
            earnedRPBoxes += 1
            WatchHapticsManager.shared.playSprintSuccess()
        } else {
            WatchHapticsManager.shared.playSprintFail()
        }
        
        WatchHapticsManager.shared.playSprintEnd()
        
        // Go back to running immediately
        runState = .running
        
        // Show the overlay on top of running view
        showSprintResult = true
        
        // Only successful sprints get recovery period
        if isValid {
            startRecovery()
        }
        
        // Start encounter checks (recovery will block them if active)
        startEncounterChecks()
        
        // Auto-hide overlay after delay: 5s for success, 3s for fail
        let delay: UInt64 = isValid ? 5_000_000_000 : 3_000_000_000
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: delay)
            showSprintResult = false
        }
    }
    
    private func validateSprint() -> Bool {
        guard !sprintHRSamples.isEmpty else { return false }
        
        let zone4Threshold = WatchConnectivityServiceWatch.shared.hrZone4Threshold
        
        if zone4Threshold > 0 {
            let validSamples = sprintHRSamples.filter { $0 > 0 }
            guard !validSamples.isEmpty else { return false }
            let samplesInZone4 = validSamples.filter { $0 >= zone4Threshold }.count
            let zone4Ratio = Double(samplesInZone4) / Double(validSamples.count)
            return zone4Ratio >= 0.50
        } else {
            let hrIncrease = peakHR - baselineHR
            let hrScore = min(1.0, Double(hrIncrease) / 20.0)
            let totalScore = (hrScore * 0.65 + 0.35) * 100
            return totalScore >= 60
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
        case 60..<90: return 0.02
        case 90..<120: return 0.05
        case 120..<150: return 0.08
        case 150..<180: return 0.12
        default: return time >= 180 ? 1.0 : 0.15
        }
    }
}
