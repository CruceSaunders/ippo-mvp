import Foundation

// MARK: - Rank (5 Ranks x 3 Divisions = 15 Tiers)
enum Rank: String, Codable, CaseIterable {
    case bronze
    case silver
    case gold
    case platinum
    case diamond
    
    var displayName: String {
        switch self {
        case .bronze: return "Bronze"
        case .silver: return "Silver"
        case .gold: return "Gold"
        case .platinum: return "Platinum"
        case .diamond: return "Diamond"
        }
    }
    
    var iconName: String {
        switch self {
        case .bronze: return "shield.fill"
        case .silver: return "shield.lefthalf.filled"
        case .gold: return "crown.fill"
        case .platinum: return "star.fill"
        case .diamond: return "diamond.fill"
        }
    }
    
    var nextRank: Rank? {
        let allRanks = Rank.allCases
        guard let currentIndex = allRanks.firstIndex(of: self),
              currentIndex < allRanks.count - 1 else { return nil }
        return allRanks[currentIndex + 1]
    }
    
    // Base RP required for Division III (lowest division) of each rank
    var baseRPRequired: Int {
        switch self {
        case .bronze: return 0
        case .silver: return 500
        case .gold: return 2000
        case .platinum: return 5000
        case .diamond: return 12000
        }
    }
    
    // RP range per division within this rank
    var rpPerDivision: Int {
        guard let next = nextRank else { return 0 }
        return (next.baseRPRequired - baseRPRequired) / 3
    }
    
    /// RP decay per day of not running (light decay system)
    var rpDecayPerDay: ClosedRange<Int> {
        switch self {
        case .bronze: return 0...0          // Protected
        case .silver: return 2...5
        case .gold: return 5...10
        case .platinum: return 10...15
        case .diamond: return 15...25
        }
    }
    
    static func rank(forRP rp: Int) -> Rank {
        let sortedRanks = Rank.allCases.reversed()
        for rank in sortedRanks {
            if rp >= rank.baseRPRequired {
                return rank
            }
        }
        return .bronze
    }
}

// MARK: - Division
enum Division: Int, Codable, CaseIterable {
    case three = 3  // Lowest within a rank
    case two = 2
    case one = 1    // Highest within a rank (about to promote)
    
    var displayName: String {
        switch self {
        case .three: return "III"
        case .two: return "II"
        case .one: return "I"
        }
    }
}

// MARK: - Rank Tier (Rank + Division)
struct RankTier: Equatable {
    let rank: Rank
    let division: Division
    
    var displayName: String {
        "\(rank.displayName) \(division.displayName)"
    }
    
    var rpRequired: Int {
        let divisionOffset: Int
        switch division {
        case .three: divisionOffset = 0
        case .two: divisionOffset = rank.rpPerDivision
        case .one: divisionOffset = rank.rpPerDivision * 2
        }
        return rank.baseRPRequired + divisionOffset
    }
    
    static func tier(forRP rp: Int) -> RankTier {
        let rank = Rank.rank(forRP: rp)
        
        guard rank != .diamond else {
            // Diamond has special handling
            let divisionRP = max(1, (20000 - rank.baseRPRequired) / 3)
            let rpInRank = rp - rank.baseRPRequired
            if rpInRank >= divisionRP * 2 {
                return RankTier(rank: .diamond, division: .one)
            } else if rpInRank >= divisionRP {
                return RankTier(rank: .diamond, division: .two)
            }
            return RankTier(rank: .diamond, division: .three)
        }
        
        let rpInRank = rp - rank.baseRPRequired
        let divisionRP = rank.rpPerDivision
        
        guard divisionRP > 0 else {
            return RankTier(rank: rank, division: .three)
        }
        
        if rpInRank >= divisionRP * 2 {
            return RankTier(rank: rank, division: .one)
        } else if rpInRank >= divisionRP {
            return RankTier(rank: rank, division: .two)
        }
        return RankTier(rank: rank, division: .three)
    }
    
    static let allTiers: [RankTier] = {
        var tiers: [RankTier] = []
        for rank in Rank.allCases {
            for division in [Division.three, .two, .one] {
                tiers.append(RankTier(rank: rank, division: division))
            }
        }
        return tiers
    }()
}

// MARK: - Player Profile
struct PlayerProfile: Codable, Equatable {
    var id: String
    var displayName: String
    var username: String
    var rp: Int
    var xp: Int
    var level: Int
    var totalRuns: Int
    var totalSprints: Int
    var totalSprintsValid: Int
    var createdAt: Date
    var lastRunDate: Date?
    var currentStreak: Int
    var longestStreak: Int
    var totalDistanceMeters: Double
    var totalDurationSeconds: Int
    var weeklyRP: Int
    var weeklyRPResetDate: Date
    
    init(
        id: String = UUID().uuidString,
        displayName: String = "Runner",
        username: String = "",
        rp: Int = 0,
        xp: Int = 0,
        level: Int = 1,
        totalRuns: Int = 0,
        totalSprints: Int = 0,
        totalSprintsValid: Int = 0,
        createdAt: Date = Date(),
        lastRunDate: Date? = nil,
        currentStreak: Int = 0,
        longestStreak: Int = 0,
        totalDistanceMeters: Double = 0,
        totalDurationSeconds: Int = 0,
        weeklyRP: Int = 0,
        weeklyRPResetDate: Date = Self.nextMondayMidnight()
    ) {
        self.id = id
        self.displayName = displayName
        self.username = username
        self.rp = rp
        self.xp = xp
        self.level = level
        self.totalRuns = totalRuns
        self.totalSprints = totalSprints
        self.totalSprintsValid = totalSprintsValid
        self.createdAt = createdAt
        self.lastRunDate = lastRunDate
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.totalDistanceMeters = totalDistanceMeters
        self.totalDurationSeconds = totalDurationSeconds
        self.weeklyRP = weeklyRP
        self.weeklyRPResetDate = weeklyRPResetDate
    }
    
    var rank: Rank {
        Rank.rank(forRP: rp)
    }
    
    var rankTier: RankTier {
        RankTier.tier(forRP: rp)
    }
    
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
    
    var rpToNextRank: Int? {
        guard let next = rank.nextRank else { return nil }
        return next.baseRPRequired - rp
    }
    
    var rpProgressInRank: Double {
        let currentRP = rank.baseRPRequired
        guard let next = rank.nextRank else { return 1.0 }
        let nextRP = next.baseRPRequired
        let progress = Double(rp - currentRP) / Double(nextRP - currentRP)
        return max(0, min(1, progress))
    }
    
    var streakBonus: Double {
        switch currentStreak {
        case 1...3: return 0.05
        case 4...7: return 0.10
        case 8...14: return 0.15
        default: return currentStreak >= 15 ? 0.20 : 0.0
        }
    }
    
    // MARK: - Weekly RP Reset
    mutating func checkWeeklyReset() {
        if Date() >= weeklyRPResetDate {
            weeklyRP = 0
            weeklyRPResetDate = Self.nextMondayMidnight()
        }
    }
    
    static func nextMondayMidnight() -> Date {
        let calendar = Calendar.current
        let now = Date()
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
        components.weekday = 2  // Monday
        components.hour = 0
        components.minute = 0
        components.second = 0
        
        if let monday = calendar.date(from: components), monday > now {
            return monday
        }
        // Next week's Monday
        return calendar.date(byAdding: .weekOfYear, value: 1, to: calendar.date(from: components) ?? now) ?? now
    }
}

// MARK: - Player Level Config
// 1 XP per minute of running, cap at level 100
struct PlayerLevelConfig {
    static func xpRequired(for level: Int) -> Int {
        // Each level requires progressively more XP
        // Level 1: 0 XP, Level 2: 30 XP (30 min), Level 10: ~500 XP
        // Level 50: ~5000 XP, Level 100: ~15000 XP
        guard level > 1 else { return 0 }
        let base = 30  // 30 minutes for first level
        let scaling = Double(level - 1)
        return Int(Double(base) * scaling * (1.0 + scaling * 0.02))
    }
    
    static func level(forXP xp: Int) -> Int {
        var level = 1
        while level < 100 && xpRequired(for: level + 1) <= xp {
            level += 1
        }
        return level
    }
    
    static let maxLevel = 100
}

// MARK: - Completed Run
struct CompletedRun: Identifiable, Codable, Equatable {
    let id: String
    let date: Date
    let durationSeconds: Int
    let distanceMeters: Double
    let sprintsCompleted: Int
    let sprintsTotal: Int
    let rpBoxesEarned: Int
    let xpEarned: Int
    let averageHR: Int
    let totalCalories: Double
    
    init(
        id: String = UUID().uuidString,
        date: Date = Date(),
        durationSeconds: Int,
        distanceMeters: Double = 0,
        sprintsCompleted: Int,
        sprintsTotal: Int,
        rpBoxesEarned: Int = 0,
        xpEarned: Int = 0,
        averageHR: Int = 0,
        totalCalories: Double = 0
    ) {
        self.id = id
        self.date = date
        self.durationSeconds = durationSeconds
        self.distanceMeters = distanceMeters
        self.sprintsCompleted = sprintsCompleted
        self.sprintsTotal = sprintsTotal
        self.rpBoxesEarned = rpBoxesEarned
        self.xpEarned = xpEarned
        self.averageHR = averageHR
        self.totalCalories = totalCalories
    }
    
    var formattedDuration: String {
        let hours = durationSeconds / 3600
        let minutes = (durationSeconds % 3600) / 60
        let seconds = durationSeconds % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var formattedDistance: String {
        let km = distanceMeters / 1000.0
        if km < 0.01 { return "0.00 km" }
        return String(format: "%.2f km", km)
    }
    
    var formattedPace: String {
        guard distanceMeters > 50 else { return "--:--" }
        let km = distanceMeters / 1000.0
        let minutesPerKm = (Double(durationSeconds) / 60.0) / km
        guard minutesPerKm.isFinite && minutesPerKm > 0 && minutesPerKm < 60 else { return "--:--" }
        let paceMinutes = Int(minutesPerKm)
        let paceSeconds = Int((minutesPerKm - Double(paceMinutes)) * 60)
        return String(format: "%d:%02d /km", paceMinutes, paceSeconds)
    }
    
    var formattedCalories: String {
        if totalCalories < 1 { return "0 kcal" }
        return String(format: "%.0f kcal", totalCalories)
    }
    
    var sprintSuccessRate: Double {
        guard sprintsTotal > 0 else { return 0 }
        return Double(sprintsCompleted) / Double(sprintsTotal)
    }
}
