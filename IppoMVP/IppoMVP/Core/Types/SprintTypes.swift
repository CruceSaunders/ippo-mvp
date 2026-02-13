import Foundation

// MARK: - Sprint State
enum SprintState: String, Codable {
    case idle
    case countdown
    case active
    case validating
    case completed
    case failed
}

// MARK: - Sprint Result
struct SprintResult: Codable, Equatable {
    let sprintId: String
    let duration: TimeInterval
    let startTime: Date
    let endTime: Date
    let isValid: Bool
    let validationScore: Double
    let hrScore: Double
    let cadenceScore: Double
    let hrdScore: Double
    let baselineHR: Int
    let peakHR: Int
    let averageCadence: Int
    let peakCadence: Int
    
    init(
        sprintId: String = UUID().uuidString,
        duration: TimeInterval,
        startTime: Date,
        endTime: Date = Date(),
        isValid: Bool,
        validationScore: Double,
        hrScore: Double = 0,
        cadenceScore: Double = 0,
        hrdScore: Double = 0,
        baselineHR: Int = 0,
        peakHR: Int = 0,
        averageCadence: Int = 0,
        peakCadence: Int = 0
    ) {
        self.sprintId = sprintId
        self.duration = duration
        self.startTime = startTime
        self.endTime = endTime
        self.isValid = isValid
        self.validationScore = validationScore
        self.hrScore = hrScore
        self.cadenceScore = cadenceScore
        self.hrdScore = hrdScore
        self.baselineHR = baselineHR
        self.peakHR = peakHR
        self.averageCadence = averageCadence
        self.peakCadence = peakCadence
    }
}

// MARK: - Sprint Data (Live tracking during sprint)
struct SprintData {
    var startTime: Date
    var targetDuration: TimeInterval
    var baselineHR: Int
    var hrSamples: [Int]
    var cadenceSamples: [Int]
    var peakHR: Int
    var peakCadence: Int
    
    init(startTime: Date = Date(), targetDuration: TimeInterval = 35, baselineHR: Int = 0) {
        self.startTime = startTime
        self.targetDuration = targetDuration
        self.baselineHR = baselineHR
        self.hrSamples = []
        self.cadenceSamples = []
        self.peakHR = 0
        self.peakCadence = 0
    }
    
    var elapsed: TimeInterval {
        Date().timeIntervalSince(startTime)
    }
    
    var remaining: TimeInterval {
        max(0, targetDuration - elapsed)
    }
    
    var progress: Double {
        min(1.0, elapsed / targetDuration)
    }
    
    var averageHR: Int {
        guard !hrSamples.isEmpty else { return 0 }
        return hrSamples.reduce(0, +) / hrSamples.count
    }
    
    var averageCadence: Int {
        guard !cadenceSamples.isEmpty else { return 0 }
        return cadenceSamples.reduce(0, +) / cadenceSamples.count
    }
    
    mutating func addSample(hr: Int, cadence: Int) {
        hrSamples.append(hr)
        cadenceSamples.append(cadence)
        peakHR = max(peakHR, hr)
        peakCadence = max(peakCadence, cadence)
    }
}

// MARK: - Encounter
struct Encounter: Identifiable, Codable {
    let id: String
    let triggeredAt: Date
    var sprintResult: SprintResult?
    var rpBoxEarned: Bool
    
    init(
        id: String = UUID().uuidString,
        triggeredAt: Date = Date(),
        sprintResult: SprintResult? = nil,
        rpBoxEarned: Bool = false
    ) {
        self.id = id
        self.triggeredAt = triggeredAt
        self.sprintResult = sprintResult
        self.rpBoxEarned = rpBoxEarned
    }
}

// MARK: - Sprint Rewards (simplified: only RP Box + XP)
struct SprintRewards: Codable, Equatable {
    var rpBoxEarned: Bool
    var xp: Int
    
    init(rpBoxEarned: Bool = false, xp: Int = 0) {
        self.rpBoxEarned = rpBoxEarned
        self.xp = xp
    }
    
    static let empty = SprintRewards()
}
