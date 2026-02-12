import Foundation

struct SprintValidator {
    private let config = SprintConfig.shared
    
    // MARK: - Validate Sprint
    func validate(_ data: SprintData, maxHR: Int) -> SprintResult {
        let hrScore = calculateHRScore(data, maxHR: maxHR)
        let cadenceScore = calculateCadenceScore(data)
        let hrdScore = calculateHRDScore(data)
        
        let totalScore = (hrScore * config.hrWeight +
                         cadenceScore * config.cadenceWeight +
                         hrdScore * config.hrdWeight) * 100
        
        let isValid = totalScore >= config.validationThreshold
        
        return SprintResult(
            duration: data.elapsed,
            startTime: data.startTime,
            isValid: isValid,
            validationScore: totalScore,
            hrScore: hrScore * 100,
            cadenceScore: cadenceScore * 100,
            hrdScore: hrdScore * 100,
            baselineHR: data.baselineHR,
            peakHR: data.peakHR,
            averageCadence: data.averageCadence,
            peakCadence: data.peakCadence
        )
    }
    
    // MARK: - Heart Rate Score (50% weight)
    private func calculateHRScore(_ data: SprintData, maxHR: Int) -> Double {
        guard !data.hrSamples.isEmpty else { return 0 }
        
        var score = 0.0
        
        // 1. HR increase from baseline (40% of HR score)
        let hrIncrease = data.peakHR - data.baselineHR
        let increaseScore = min(1.0, Double(hrIncrease) / Double(config.minHRIncreaseRequired))
        score += increaseScore * 0.4
        
        // 2. Reached target zone (40% of HR score)
        let targetHR = Int(Double(maxHR) * config.targetHRZonePercent)
        let reachedZone = data.peakHR >= targetHR
        if reachedZone {
            score += 0.4
        } else {
            // Partial credit for getting close
            let zoneProgress = Double(data.peakHR) / Double(targetHR)
            score += 0.4 * min(1.0, zoneProgress)
        }
        
        // 3. Time in elevated HR (20% of HR score)
        let elevatedThreshold = data.baselineHR + 10
        let elevatedSamples = data.hrSamples.filter { $0 >= elevatedThreshold }.count
        let elevatedPercent = Double(elevatedSamples) / Double(data.hrSamples.count)
        score += min(1.0, elevatedPercent / config.minTimeInTargetZone) * 0.2
        
        return score
    }
    
    // MARK: - Cadence Score (35% weight)
    private func calculateCadenceScore(_ data: SprintData) -> Double {
        guard !data.cadenceSamples.isEmpty else { return 0 }
        
        var score = 0.0
        
        // 1. Cadence increase (50% of cadence score)
        let preSamples = Array(data.cadenceSamples.prefix(3))
        let preCadence = preSamples.isEmpty ? 0 : preSamples.reduce(0, +) / preSamples.count
        
        if preCadence > 0 {
            let increasePercent = Double(data.peakCadence - preCadence) / Double(preCadence)
            let increaseScore = min(1.0, increasePercent / config.minCadenceIncreasePercent)
            score += increaseScore * 0.5
        }
        
        // 2. Peak cadence reached target (50% of cadence score)
        let peakScore = min(1.0, Double(data.peakCadence) / Double(config.minPeakCadence))
        score += peakScore * 0.5
        
        return score
    }
    
    // MARK: - HR Derivative Score (15% weight)
    private func calculateHRDScore(_ data: SprintData) -> Double {
        guard data.hrSamples.count >= 3 else { return 0 }
        
        // Look at first 10 seconds worth of samples (assuming ~1 sample/sec)
        let windowSize = min(10, data.hrSamples.count)
        let windowSamples = Array(data.hrSamples.prefix(windowSize))
        
        // Calculate maximum rate of change
        var maxDerivative = 0.0
        for i in 1..<windowSamples.count {
            let derivative = Double(windowSamples[i] - windowSamples[i-1])
            maxDerivative = max(maxDerivative, derivative)
        }
        
        // Score based on target derivative
        return min(1.0, maxDerivative / config.minHRDerivative)
    }
}
