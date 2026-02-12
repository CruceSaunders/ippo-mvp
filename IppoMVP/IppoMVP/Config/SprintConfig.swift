import Foundation

struct SprintConfig: Sendable {
    static let shared = SprintConfig()
    
    // MARK: - Sprint Duration
    let minSprintDuration: TimeInterval = 30.0
    let maxSprintDuration: TimeInterval = 45.0
    
    // MARK: - Heart Rate Validation
    let minHRIncreaseRequired: Int = 20
    let targetHRZonePercent: Double = 0.80  // Zone 4-5 = >80% max HR
    let minTimeInTargetZone: Double = 0.70  // 70% of sprint duration
    
    // MARK: - Cadence Validation
    let minCadenceIncreasePercent: Double = 0.15  // 15% increase
    let minPeakCadence: Int = 160
    
    // MARK: - HR Derivative Validation
    let minHRDerivative: Double = 3.0  // BPM per second
    let hrdMeasurementWindow: TimeInterval = 10.0
    
    // MARK: - Weights
    let hrWeight: Double = 0.50
    let cadenceWeight: Double = 0.35
    let hrdWeight: Double = 0.15
    
    // MARK: - Validation
    let validationThreshold: Double = 60.0  // Score needed to validate
    
    // MARK: - Recovery
    let recoveryDuration: TimeInterval = 45.0
    
    // MARK: - Countdown
    let countdownDuration: TimeInterval = 3.0
    
    // MARK: - Helpers
    func randomSprintDuration() -> TimeInterval {
        TimeInterval.random(in: minSprintDuration...maxSprintDuration)
    }
}
