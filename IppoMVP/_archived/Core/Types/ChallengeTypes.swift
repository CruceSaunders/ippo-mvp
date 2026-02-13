import Foundation

// MARK: - Daily Rewards Data
struct DailyRewardsData: Codable, Equatable {
    var lastClaimDate: Date?
    var currentDay: Int          // 1-7 cycle position
    var currentStreak: Int
    var longestStreak: Int
    var claimedDays: Set<Int>    // Which days claimed this cycle (1-7)
    var cycleStartDate: Date?
    
    init(
        lastClaimDate: Date? = nil,
        currentDay: Int = 1,
        currentStreak: Int = 0,
        longestStreak: Int = 0,
        claimedDays: Set<Int> = [],
        cycleStartDate: Date? = nil
    ) {
        self.lastClaimDate = lastClaimDate
        self.currentDay = currentDay
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.claimedDays = claimedDays
        self.cycleStartDate = cycleStartDate
    }
}

// MARK: - Daily Reward Definition
struct DailyRewardDefinition {
    let day: Int
    let rewardType: DailyRewardType
    let displayName: String
    let iconName: String
    
    static let rewards: [DailyRewardDefinition] = [
        DailyRewardDefinition(day: 1, rewardType: .coins(75), displayName: "75", iconName: "dollarsign.circle.fill"),
        DailyRewardDefinition(day: 2, rewardType: .coins(75), displayName: "75", iconName: "dollarsign.circle.fill"),
        DailyRewardDefinition(day: 3, rewardType: .gems(5), displayName: "5", iconName: "diamond.fill"),
        DailyRewardDefinition(day: 4, rewardType: .coins(100), displayName: "100", iconName: "dollarsign.circle.fill"),
        DailyRewardDefinition(day: 5, rewardType: .lootBox(.common), displayName: "Common Egg", iconName: "gift.fill"),
        DailyRewardDefinition(day: 6, rewardType: .coins(150), displayName: "150", iconName: "dollarsign.circle.fill"),
        DailyRewardDefinition(day: 7, rewardType: .lootBox(.rare), displayName: "Rare", iconName: "gift.fill"),
    ]
    
    static func reward(forDay day: Int) -> DailyRewardDefinition? {
        rewards.first { $0.day == day }
    }
}

enum DailyRewardType {
    case coins(Int)
    case gems(Int)
    case lootBox(Rarity)
}

// MARK: - Challenge Data
struct ChallengeData: Codable, Equatable {
    var weeklyChallenges: [Challenge]
    var monthlyChallenge: Challenge?
    var weekStartDate: Date?
    var monthStartDate: Date?
    
    init(
        weeklyChallenges: [Challenge] = [],
        monthlyChallenge: Challenge? = nil,
        weekStartDate: Date? = nil,
        monthStartDate: Date? = nil
    ) {
        self.weeklyChallenges = weeklyChallenges
        self.monthlyChallenge = monthlyChallenge
        self.weekStartDate = weekStartDate
        self.monthStartDate = monthStartDate
    }
}

struct Challenge: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let description: String
    let iconName: String
    let type: ChallengeType
    let target: Int
    var progress: Int
    let rewardCoins: Int
    let rewardGems: Int
    let rewardRP: Int
    var isCompleted: Bool
    var isClaimed: Bool
    
    init(
        id: String = UUID().uuidString,
        name: String,
        description: String,
        iconName: String,
        type: ChallengeType,
        target: Int,
        progress: Int = 0,
        rewardCoins: Int = 0,
        rewardGems: Int = 0,
        rewardRP: Int = 0,
        isCompleted: Bool = false,
        isClaimed: Bool = false
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.iconName = iconName
        self.type = type
        self.target = target
        self.progress = progress
        self.rewardCoins = rewardCoins
        self.rewardGems = rewardGems
        self.rewardRP = rewardRP
        self.isCompleted = isCompleted
        self.isClaimed = isClaimed
    }
    
    var progressFraction: Double {
        guard target > 0 else { return 0 }
        return min(1.0, Double(progress) / Double(target))
    }
}

enum ChallengeType: String, Codable {
    case runs
    case sprints
    case distance
    case petFeedings
    case lootBoxes
}
