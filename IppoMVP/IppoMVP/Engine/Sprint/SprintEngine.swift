import Foundation
import Combine

@MainActor
final class SprintEngine: ObservableObject {
    static let shared = SprintEngine()
    
    // MARK: - Published State
    @Published private(set) var state: SprintState = .idle
    @Published private(set) var sprintData: SprintData?
    @Published private(set) var countdownRemaining: Int = 3
    @Published private(set) var timeRemaining: TimeInterval = 0
    @Published private(set) var lastResult: SprintResult?
    
    // MARK: - Dependencies
    private let config = SprintConfig.shared
    private let validator = SprintValidator()
    
    // MARK: - Internal State
    private var sprintTimer: Timer?
    private var countdownTimer: Timer?
    private var targetDuration: TimeInterval = 35
    
    // Callbacks
    var onSprintStart: (() -> Void)?
    var onSprintEnd: ((SprintResult) -> Void)?
    var onCountdownTick: ((Int) -> Void)?
    
    // MARK: - Init
    private init() {}
    
    // MARK: - Sprint Lifecycle
    func startCountdown(baselineHR: Int) {
        guard state == .idle else { return }
        
        targetDuration = config.randomSprintDuration()
        sprintData = SprintData(targetDuration: targetDuration, baselineHR: baselineHR)
        countdownRemaining = Int(config.countdownDuration)
        state = .countdown
        
        // Start countdown
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tickCountdown()
            }
        }
    }
    
    private func tickCountdown() {
        countdownRemaining -= 1
        onCountdownTick?(countdownRemaining)
        
        if countdownRemaining <= 0 {
            countdownTimer?.invalidate()
            countdownTimer = nil
            startSprint()
        }
    }
    
    private func startSprint() {
        sprintData?.startTime = Date()
        timeRemaining = targetDuration
        state = .active
        
        onSprintStart?()
        
        // Start sprint timer
        sprintTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateSprint()
            }
        }
    }
    
    private func updateSprint() {
        guard let data = sprintData else { return }
        
        timeRemaining = data.remaining
        
        if timeRemaining <= 0 {
            endSprint()
        }
    }
    
    func endSprint() {
        sprintTimer?.invalidate()
        sprintTimer = nil
        
        guard let data = sprintData else {
            state = .idle
            return
        }
        
        state = .validating
        
        // Validate the sprint
        // Note: maxHR should come from user profile, defaulting to 190 for MVP
        let maxHR = 190
        let result = validator.validate(data, maxHR: maxHR)
        
        lastResult = result
        state = .completed
        
        onSprintEnd?(result)
        
        // Reset after a delay
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            await MainActor.run {
                reset()
            }
        }
    }
    
    func cancelSprint() {
        sprintTimer?.invalidate()
        countdownTimer?.invalidate()
        sprintTimer = nil
        countdownTimer = nil
        state = .failed
        
        Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            await MainActor.run {
                reset()
            }
        }
    }
    
    func reset() {
        state = .idle
        sprintData = nil
        timeRemaining = 0
        countdownRemaining = 3
    }
    
    // MARK: - Sensor Updates
    func addSensorSample(hr: Int, cadence: Int) {
        guard state == .active else { return }
        sprintData?.addSample(hr: hr, cadence: cadence)
    }
    
    // MARK: - Computed
    var progress: Double {
        sprintData?.progress ?? 0
    }
    
    var isInFinalSeconds: Bool {
        timeRemaining <= 5 && timeRemaining > 0
    }
}
