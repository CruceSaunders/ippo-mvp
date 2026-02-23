import Foundation

// MARK: - Achievement
struct Achievement: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let description: String
    let iconName: String
    let category: AchievementCategory
    let requirement: Int
    var progress: Int
    var isCompleted: Bool
    var completedDate: Date?
    
    init(
        id: String,
        name: String,
        description: String,
        iconName: String,
        category: AchievementCategory,
        requirement: Int,
        progress: Int = 0,
        isCompleted: Bool = false,
        completedDate: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.iconName = iconName
        self.category = category
        self.requirement = requirement
        self.progress = progress
        self.isCompleted = isCompleted
        self.completedDate = completedDate
    }
    
    var progressFraction: Double {
        guard requirement > 0 else { return 0 }
        return min(1.0, Double(progress) / Double(requirement))
    }
}

// MARK: - Achievement Category
enum AchievementCategory: String, Codable, CaseIterable {
    case runs
    case sprints
    case pets
    case distance
    case streaks
    case abilities
    
    var displayName: String {
        switch self {
        case .runs: return "Running"
        case .sprints: return "Sprints"
        case .pets: return "Pets"
        case .distance: return "Distance"
        case .streaks: return "Streaks"
        case .abilities: return "Abilities"
        }
    }
    
    var iconName: String {
        switch self {
        case .runs: return "figure.run"
        case .sprints: return "bolt.fill"
        case .pets: return "pawprint.fill"
        case .distance: return "map.fill"
        case .streaks: return "flame.fill"
        case .abilities: return "star.fill"
        }
    }
}

// MARK: - Achievement Definitions
struct AchievementDefinitions {
    static let all: [Achievement] = [
        // Runs
        Achievement(id: "run_1", name: "First Steps", description: "Complete your first run", iconName: "figure.run", category: .runs, requirement: 1),
        Achievement(id: "run_5", name: "Getting Started", description: "Complete 5 runs", iconName: "figure.run", category: .runs, requirement: 5),
        Achievement(id: "run_10", name: "Regular Runner", description: "Complete 10 runs", iconName: "figure.run", category: .runs, requirement: 10),
        Achievement(id: "run_25", name: "Dedicated Runner", description: "Complete 25 runs", iconName: "figure.run", category: .runs, requirement: 25),
        Achievement(id: "run_50", name: "Running Addict", description: "Complete 50 runs", iconName: "figure.run", category: .runs, requirement: 50),
        Achievement(id: "run_100", name: "Centurion Runner", description: "Complete 100 runs", iconName: "figure.run", category: .runs, requirement: 100),
        
        // Sprints
        Achievement(id: "sprint_1", name: "Sprint Novice", description: "Complete your first sprint", iconName: "bolt.fill", category: .sprints, requirement: 1),
        Achievement(id: "sprint_10", name: "Sprint Apprentice", description: "Complete 10 sprints", iconName: "bolt.fill", category: .sprints, requirement: 10),
        Achievement(id: "sprint_25", name: "Sprint Warrior", description: "Complete 25 sprints", iconName: "bolt.fill", category: .sprints, requirement: 25),
        Achievement(id: "sprint_50", name: "Sprint Pro", description: "Complete 50 sprints", iconName: "bolt.fill", category: .sprints, requirement: 50),
        Achievement(id: "sprint_100", name: "Sprint Legend", description: "Complete 100 sprints", iconName: "bolt.fill", category: .sprints, requirement: 100),
        
        // Pets
        Achievement(id: "pet_1", name: "Pet Parent", description: "Catch your first pet", iconName: "pawprint.fill", category: .pets, requirement: 1),
        Achievement(id: "pet_3", name: "Growing Family", description: "Catch 3 pets", iconName: "pawprint.fill", category: .pets, requirement: 3),
        Achievement(id: "pet_5", name: "Collector", description: "Catch 5 pets", iconName: "pawprint.fill", category: .pets, requirement: 5),
        Achievement(id: "pet_10", name: "Gotta Catch 'Em All", description: "Catch all 10 pets", iconName: "pawprint.fill", category: .pets, requirement: 10),
        
        // Distance
        Achievement(id: "dist_5", name: "5K Club", description: "Run 5km total", iconName: "map.fill", category: .distance, requirement: 5000),
        Achievement(id: "dist_10", name: "10K Club", description: "Run 10km total", iconName: "map.fill", category: .distance, requirement: 10000),
        Achievement(id: "dist_42", name: "Marathon", description: "Run 42.2km total", iconName: "map.fill", category: .distance, requirement: 42200),
        Achievement(id: "dist_100", name: "Centurion", description: "Run 100km total", iconName: "map.fill", category: .distance, requirement: 100000),
        Achievement(id: "dist_500", name: "Ultra Runner", description: "Run 500km total", iconName: "map.fill", category: .distance, requirement: 500000),
        
        // Streaks
        Achievement(id: "streak_3", name: "Warming Up", description: "Reach a 3-day streak", iconName: "flame.fill", category: .streaks, requirement: 3),
        Achievement(id: "streak_7", name: "Hot Streak", description: "Reach a 7-day streak", iconName: "flame.fill", category: .streaks, requirement: 7),
        Achievement(id: "streak_14", name: "On Fire", description: "Reach a 14-day streak", iconName: "flame.fill", category: .streaks, requirement: 14),
        Achievement(id: "streak_30", name: "Unstoppable", description: "Reach a 30-day streak", iconName: "flame.fill", category: .streaks, requirement: 30),
        
        // Abilities
        Achievement(id: "ability_1", name: "First Unlock", description: "Unlock your first ability", iconName: "star.fill", category: .abilities, requirement: 1),
        Achievement(id: "ability_5", name: "Skill Builder", description: "Unlock 5 abilities", iconName: "star.fill", category: .abilities, requirement: 5),
        Achievement(id: "ability_10", name: "Talent Tree", description: "Unlock 10 abilities", iconName: "star.fill", category: .abilities, requirement: 10),
        Achievement(id: "ability_all", name: "Fully Loaded", description: "Unlock all player abilities", iconName: "star.fill", category: .abilities, requirement: 26),
    ]
}
