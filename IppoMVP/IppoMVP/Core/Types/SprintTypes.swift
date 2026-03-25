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
    let baselineHR: Int
    let peakHR: Int
    let zone4Threshold: Int
    
    init(
        sprintId: String = UUID().uuidString,
        duration: TimeInterval,
        startTime: Date,
        endTime: Date = Date(),
        isValid: Bool,
        baselineHR: Int = 0,
        peakHR: Int = 0,
        zone4Threshold: Int = 0
    ) {
        self.sprintId = sprintId
        self.duration = duration
        self.startTime = startTime
        self.endTime = endTime
        self.isValid = isValid
        self.baselineHR = baselineHR
        self.peakHR = peakHR
        self.zone4Threshold = zone4Threshold
    }

    // Backward-compatible decoder for old data with legacy scoring fields
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        sprintId = try container.decodeIfPresent(String.self, forKey: .sprintId) ?? UUID().uuidString
        duration = try container.decode(TimeInterval.self, forKey: .duration)
        startTime = try container.decode(Date.self, forKey: .startTime)
        endTime = try container.decodeIfPresent(Date.self, forKey: .endTime) ?? Date()
        isValid = try container.decode(Bool.self, forKey: .isValid)
        baselineHR = try container.decodeIfPresent(Int.self, forKey: .baselineHR) ?? 0
        peakHR = try container.decodeIfPresent(Int.self, forKey: .peakHR) ?? 0
        zone4Threshold = try container.decodeIfPresent(Int.self, forKey: .zone4Threshold) ?? 0
    }
}

// MARK: - Sprint Data (Live tracking during sprint)
struct SprintData {
    var startTime: Date
    var targetDuration: TimeInterval
    var baselineHR: Int
    var hrSamples: [Int]
    var peakHR: Int
    
    init(startTime: Date = Date(), targetDuration: TimeInterval = 35, baselineHR: Int = 0) {
        self.startTime = startTime
        self.targetDuration = targetDuration
        self.baselineHR = baselineHR
        self.hrSamples = []
        self.peakHR = 0
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
    
    mutating func addSample(hr: Int) {
        hrSamples.append(hr)
        peakHR = max(peakHR, hr)
    }
}

// MARK: - Encounter
struct Encounter: Identifiable, Codable {
    let id: String
    let triggeredAt: Date
    var sprintResult: SprintResult?
    var coinsEarned: Int
    var xpEarned: Int
    var petCaughtId: String?

    init(
        id: String = UUID().uuidString,
        triggeredAt: Date = Date(),
        sprintResult: SprintResult? = nil,
        coinsEarned: Int = 0,
        xpEarned: Int = 0,
        petCaughtId: String? = nil
    ) {
        self.id = id
        self.triggeredAt = triggeredAt
        self.sprintResult = sprintResult
        self.coinsEarned = coinsEarned
        self.xpEarned = xpEarned
        self.petCaughtId = petCaughtId
    }
}

// MARK: - Sprint Rewards
struct SprintRewards: Codable, Equatable {
    var coins: Int
    var xp: Int
    var petCaughtId: String?

    init(coins: Int = 0, xp: Int = 0, petCaughtId: String? = nil) {
        self.coins = coins
        self.xp = xp
        self.petCaughtId = petCaughtId
    }

    static let empty = SprintRewards()
}
