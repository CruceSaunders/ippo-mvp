import Foundation

@MainActor
final class ChallengesSystem {
    static let shared = ChallengesSystem()
    private let calendar = Calendar.current
    
    private init() {}
    
    // MARK: - Weekly Challenge Templates
    private let weeklyTemplates: [(name: String, description: String, icon: String, type: ChallengeType, target: Int, coins: Int, gems: Int, rp: Int)] = [
        ("Run 3 Times", "Complete 3 runs this week", "figure.run", .runs, 3, 200, 5, 50),
        ("Sprint Master", "Complete 10 sprints this week", "bolt.fill", .sprints, 10, 300, 10, 75),
        ("Pet Caretaker", "Feed your pets 5 times this week", "leaf.fill", .petFeedings, 5, 150, 5, 25),
        ("Distance Runner", "Run 10km this week", "map.fill", .distance, 10000, 250, 10, 100),
        ("Loot Collector", "Open 3 loot boxes this week", "gift.fill", .lootBoxes, 3, 200, 5, 50),
        ("Sprint Warrior", "Complete 5 sprints this week", "bolt.fill", .sprints, 5, 150, 5, 50),
        ("Daily Runner", "Run every day this week (5 runs)", "figure.run", .runs, 5, 400, 15, 100),
        ("Quick Burst", "Complete 3 sprints in a single run", "bolt.fill", .sprints, 3, 100, 5, 25),
    ]
    
    // MARK: - Generate Weekly Challenges
    func generateWeeklyChallenges() -> [Challenge] {
        let templates = weeklyTemplates.shuffled()
        let selected = Array(templates.prefix(3))
        
        return selected.map { template in
            Challenge(
                name: template.name,
                description: template.description,
                iconName: template.icon,
                type: template.type,
                target: template.target,
                rewardCoins: template.coins,
                rewardGems: template.gems,
                rewardRP: template.rp
            )
        }
    }
    
    // MARK: - Generate Monthly Challenge
    func generateMonthlyChallenge() -> Challenge {
        let monthName = calendar.monthSymbols[calendar.component(.month, from: Date()) - 1]
        
        return Challenge(
            name: "\(monthName) Challenge",
            description: "Run 50km this month",
            iconName: "trophy.fill",
            type: .distance,
            target: 50000, // 50km in meters
            rewardCoins: 1000,
            rewardGems: 50,
            rewardRP: 500
        )
    }
    
    // MARK: - Refresh Challenges if Needed
    func refreshIfNeeded() {
        let userData = UserData.shared
        var data = userData.challengeData
        let now = Date()
        
        // Check weekly reset
        let needsWeeklyRefresh: Bool
        if let weekStart = data.weekStartDate {
            let weeksSince = calendar.dateComponents([.weekOfYear], from: weekStart, to: now).weekOfYear ?? 0
            needsWeeklyRefresh = weeksSince >= 1
        } else {
            needsWeeklyRefresh = true
        }
        
        if needsWeeklyRefresh {
            data.weeklyChallenges = generateWeeklyChallenges()
            data.weekStartDate = calendar.startOfDay(for: now)
        }
        
        // Check monthly reset
        let needsMonthlyRefresh: Bool
        if let monthStart = data.monthStartDate {
            let monthsSince = calendar.dateComponents([.month], from: monthStart, to: now).month ?? 0
            needsMonthlyRefresh = monthsSince >= 1
        } else {
            needsMonthlyRefresh = true
        }
        
        if needsMonthlyRefresh {
            data.monthlyChallenge = generateMonthlyChallenge()
            data.monthStartDate = calendar.startOfDay(for: now)
        }
        
        userData.challengeData = data
        userData.save()
    }
    
    // MARK: - Update Challenge Progress
    func updateProgress(type: ChallengeType, increment: Int) {
        let userData = UserData.shared
        var data = userData.challengeData
        
        // Update weekly challenges
        for i in data.weeklyChallenges.indices {
            if data.weeklyChallenges[i].type == type && !data.weeklyChallenges[i].isCompleted {
                data.weeklyChallenges[i].progress += increment
                if data.weeklyChallenges[i].progress >= data.weeklyChallenges[i].target {
                    data.weeklyChallenges[i].isCompleted = true
                }
            }
        }
        
        // Update monthly challenge
        if var monthly = data.monthlyChallenge, monthly.type == type && !monthly.isCompleted {
            monthly.progress += increment
            if monthly.progress >= monthly.target {
                monthly.isCompleted = true
            }
            data.monthlyChallenge = monthly
        }
        
        userData.challengeData = data
        userData.save()
    }
    
    // MARK: - Claim Challenge Reward
    func claimReward(challengeId: String) -> Bool {
        let userData = UserData.shared
        var data = userData.challengeData
        
        // Check weekly
        if let index = data.weeklyChallenges.firstIndex(where: { $0.id == challengeId }) {
            guard data.weeklyChallenges[index].isCompleted && !data.weeklyChallenges[index].isClaimed else { return false }
            
            let challenge = data.weeklyChallenges[index]
            userData.addCoins(challenge.rewardCoins)
            userData.addGems(challenge.rewardGems)
            userData.addRP(challenge.rewardRP)
            data.weeklyChallenges[index].isClaimed = true
            userData.challengeData = data
            userData.save()
            return true
        }
        
        // Check monthly
        if let monthly = data.monthlyChallenge, monthly.id == challengeId {
            guard monthly.isCompleted && !monthly.isClaimed else { return false }
            
            userData.addCoins(monthly.rewardCoins)
            userData.addGems(monthly.rewardGems)
            userData.addRP(monthly.rewardRP)
            var updated = monthly
            updated.isClaimed = true
            data.monthlyChallenge = updated
            userData.challengeData = data
            userData.save()
            return true
        }
        
        return false
    }
}
