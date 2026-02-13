import Foundation

@MainActor
final class DailyRewardsSystem {
    static let shared = DailyRewardsSystem()
    private let calendar = Calendar.current
    
    private init() {}
    
    // MARK: - Check if Reward Available
    func canClaimToday() -> Bool {
        let userData = UserData.shared
        let data = userData.dailyRewards
        
        guard let lastClaim = data.lastClaimDate else {
            // Never claimed before
            return true
        }
        
        // Check if lastClaim is a different calendar day than today
        return !calendar.isDateInToday(lastClaim)
    }
    
    // MARK: - Get Current Day to Claim
    func currentClaimDay() -> Int {
        let userData = UserData.shared
        let data = userData.dailyRewards
        
        guard let lastClaim = data.lastClaimDate else {
            return 1 // First time
        }
        
        if calendar.isDateInToday(lastClaim) {
            // Already claimed today, show current day
            return data.currentDay
        }
        
        let today = calendar.startOfDay(for: Date())
        let lastClaimDay = calendar.startOfDay(for: lastClaim)
        let daysDiff = calendar.dateComponents([.day], from: lastClaimDay, to: today).day ?? 0
        
        if daysDiff == 1 {
            // Consecutive day: advance to next day in cycle
            let nextDay = data.currentDay >= 7 ? 1 : data.currentDay + 1
            return nextDay
        } else if daysDiff > 1 {
            // Missed days: reset cycle but keep going from next position
            let nextDay = data.currentDay >= 7 ? 1 : data.currentDay + 1
            return nextDay
        }
        
        return data.currentDay
    }
    
    // MARK: - Claim Daily Reward
    func claimReward() -> DailyRewardType? {
        guard canClaimToday() else { return nil }
        
        let userData = UserData.shared
        var data = userData.dailyRewards
        
        let dayToClaim = currentClaimDay()
        
        guard let rewardDef = DailyRewardDefinition.reward(forDay: dayToClaim) else { return nil }
        
        let today = calendar.startOfDay(for: Date())
        let lastClaimDay = data.lastClaimDate.map { calendar.startOfDay(for: $0) }
        let daysDiff = lastClaimDay.map { calendar.dateComponents([.day], from: $0, to: today).day ?? 0 }
        
        // Update streak
        if let diff = daysDiff, diff == 1 {
            // Consecutive day
            data.currentStreak += 1
        } else if daysDiff == nil || (daysDiff ?? 0) > 1 {
            // First claim or missed a day
            data.currentStreak = 1
        }
        // If daysDiff == 0, it means same day claim (shouldn't happen due to guard)
        
        data.longestStreak = max(data.longestStreak, data.currentStreak)
        
        // Handle cycle
        if dayToClaim == 1 {
            // Start new cycle
            data.claimedDays = [1]
            data.cycleStartDate = today
        } else {
            data.claimedDays.insert(dayToClaim)
        }
        
        data.currentDay = dayToClaim
        data.lastClaimDate = Date()
        
        // Apply reward
        switch rewardDef.rewardType {
        case .coins(let amount):
            userData.addCoins(amount)
        case .gems(let amount):
            userData.addGems(amount)
        case .lootBox(let rarity):
            userData.addLootBox(rarity)
        }
        
        userData.dailyRewards = data
        userData.save()
        
        return rewardDef.rewardType
    }
    
    // MARK: - Days This Week Count
    func daysClaimedThisWeek() -> Int {
        let data = UserData.shared.dailyRewards
        return data.claimedDays.count
    }
}
