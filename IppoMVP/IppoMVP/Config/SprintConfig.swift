import Foundation

struct SprintConfig: Sendable {
    static let shared = SprintConfig()
    
    // MARK: - Sprint Duration
    let minSprintDuration: TimeInterval = 30.0
    let maxSprintDuration: TimeInterval = 45.0
    
    // MARK: - Heart Rate Validation
    /// Zone 4 starts at 80% of estimated max HR. Reaching this at any point validates the sprint.
    let zone4Percent: Double = 0.80
    
    // MARK: - Recovery
    let recoveryDuration: TimeInterval = 45.0
    
    // MARK: - Countdown
    let countdownDuration: TimeInterval = 3.0
    
    // MARK: - Helpers
    func randomSprintDuration() -> TimeInterval {
        TimeInterval.random(in: minSprintDuration...maxSprintDuration)
    }
    
    func zone4Threshold(forMaxHR maxHR: Int) -> Int {
        Int(Double(maxHR) * zone4Percent)
    }
}
