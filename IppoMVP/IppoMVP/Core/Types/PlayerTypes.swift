import Foundation

// MARK: - Player Profile
struct PlayerProfile: Codable, Equatable {
    var id: String
    var displayName: String
    var username: String
    var age: Int
    var xp: Int
    var level: Int
    var coins: Int
    var equippedPetId: String?
    var totalRuns: Int
    var totalSprints: Int
    var totalSprintsValid: Int
    var createdAt: Date
    var lastRunDate: Date?
    var lastInteractionDate: Date?
    var currentStreak: Int
    var longestStreak: Int
    var totalDistanceMeters: Double
    var totalDurationSeconds: Int
    var sprintsSinceLastCatch: Int

    init(
        id: String = UUID().uuidString,
        displayName: String = "Runner",
        username: String = "",
        age: Int = 25,
        xp: Int = 0,
        level: Int = 1,
        coins: Int = EconomyConfig.shared.startingCoins,
        equippedPetId: String? = nil,
        totalRuns: Int = 0,
        totalSprints: Int = 0,
        totalSprintsValid: Int = 0,
        createdAt: Date = Date(),
        lastRunDate: Date? = nil,
        lastInteractionDate: Date? = nil,
        currentStreak: Int = 0,
        longestStreak: Int = 0,
        totalDistanceMeters: Double = 0,
        totalDurationSeconds: Int = 0,
        sprintsSinceLastCatch: Int = 0
    ) {
        self.id = id
        self.displayName = displayName
        self.username = username
        self.age = age
        self.xp = xp
        self.level = level
        self.coins = coins
        self.equippedPetId = equippedPetId
        self.totalRuns = totalRuns
        self.totalSprints = totalSprints
        self.totalSprintsValid = totalSprintsValid
        self.createdAt = createdAt
        self.lastRunDate = lastRunDate
        self.lastInteractionDate = lastInteractionDate
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.totalDistanceMeters = totalDistanceMeters
        self.totalDurationSeconds = totalDurationSeconds
        self.sprintsSinceLastCatch = sprintsSinceLastCatch
    }

    // MARK: - Heart Rate
    var estimatedMaxHR: Int {
        220 - age
    }

    var hrZone4Threshold: Int {
        Int(Double(estimatedMaxHR) * 0.80)
    }

    // MARK: - Level
    var xpForNextLevel: Int {
        PlayerLevelConfig.xpRequired(for: level + 1)
    }

    var xpProgress: Double {
        let currentLevelXP = PlayerLevelConfig.xpRequired(for: level)
        let nextLevelXP = xpForNextLevel
        let progressXP = xp - currentLevelXP
        let neededXP = nextLevelXP - currentLevelXP
        guard neededXP > 0 else { return 1.0 }
        return Double(progressXP) / Double(neededXP)
    }
}

// MARK: - Player Level Config
struct PlayerLevelConfig {
    static func xpRequired(for level: Int) -> Int {
        guard level > 1 else { return 0 }
        let base = 30
        let scaling = Double(level - 1)
        return Int(Double(base) * scaling * (1.0 + scaling * 0.02))
    }

    static func level(forXP xp: Int) -> Int {
        var level = 1
        while level < maxLevel && xpRequired(for: level + 1) <= xp {
            level += 1
        }
        return level
    }

    static let maxLevel = 100
}
