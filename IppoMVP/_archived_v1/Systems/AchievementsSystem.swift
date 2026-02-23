import Foundation

@MainActor
final class AchievementsSystem {
    static let shared = AchievementsSystem()
    
    private init() {}
    
    // MARK: - Initialize Achievements
    func initializeIfNeeded() {
        let userData = UserData.shared
        guard userData.achievements.isEmpty else { return }
        userData.achievements = AchievementDefinitions.all
        userData.save()
    }
    
    // MARK: - Update All Progress
    func updateAllProgress() {
        let userData = UserData.shared
        let profile = userData.profile
        
        for i in userData.achievements.indices {
            guard !userData.achievements[i].isCompleted else { continue }
            
            let newProgress: Int
            switch userData.achievements[i].category {
            case .runs:
                newProgress = profile.totalRuns
            case .sprints:
                newProgress = profile.totalSprintsValid
            case .pets:
                newProgress = userData.ownedPets.count
            case .distance:
                newProgress = Int(profile.totalDistanceMeters)
            case .streaks:
                newProgress = profile.longestStreak
            case .abilities:
                newProgress = userData.abilities.unlockedPlayerAbilities.count
            }
            
            userData.achievements[i].progress = newProgress
            
            if newProgress >= userData.achievements[i].requirement && !userData.achievements[i].isCompleted {
                userData.achievements[i].isCompleted = true
                userData.achievements[i].completedDate = Date()
            }
        }
        
        userData.save()
    }
    
    // MARK: - Stats
    var completedCount: Int {
        UserData.shared.achievements.filter { $0.isCompleted }.count
    }
    
    var totalCount: Int {
        UserData.shared.achievements.count
    }
    
    func achievements(for category: AchievementCategory) -> [Achievement] {
        UserData.shared.achievements.filter { $0.category == category }
    }
    
    var recentlyCompleted: [Achievement] {
        UserData.shared.achievements
            .filter { $0.isCompleted }
            .sorted { ($0.completedDate ?? .distantPast) > ($1.completedDate ?? .distantPast) }
    }
}
