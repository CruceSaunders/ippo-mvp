import Foundation

struct SprintValidator {
    private let config = SprintConfig.shared
    
    /// Validates a sprint: pass if peak HR reached Zone 4 at any point during the sprint.
    func validate(_ data: SprintData, maxHR: Int) -> SprintResult {
        let zone4Threshold = config.zone4Threshold(forMaxHR: maxHR)
        let isValid = !data.hrSamples.isEmpty && data.peakHR >= zone4Threshold
        
        return SprintResult(
            duration: data.elapsed,
            startTime: data.startTime,
            isValid: isValid,
            baselineHR: data.baselineHR,
            peakHR: data.peakHR,
            zone4Threshold: zone4Threshold
        )
    }
}
