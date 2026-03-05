import Foundation

// MARK: - Pet Definition (Static Game Data)
struct GamePetDefinition: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let description: String
    let hintText: String
    let stageImageNames: [String]  // 3 image names, one per evolution stage (Baby, Teen, Adult)
    var hasIdleVideos: Bool = false
    var hasHappyVideos: Bool = false
    var isStarter: Bool = false
    /// Per-pet evolution levels. Key = stage number, Value = level required.
    /// e.g. [2: 8, 3: 14] means Teen at level 8, Adult at level 14.
    /// If empty, falls back to PetConfig.shared.evolutionLevels.
    var evolutionLevels: [Int: Int] = [:]

    var stageCount: Int { stageImageNames.count }

    /// Returns the evolution stage for a given level, using this pet's thresholds.
    func stageForLevel(_ level: Int) -> Int {
        let levels = evolutionLevels.isEmpty ? PetConfig.shared.evolutionLevels : evolutionLevels
        var stage = 1
        for (stageNum, triggerLevel) in levels.sorted(by: { $0.key < $1.key }) {
            if level >= triggerLevel {
                stage = stageNum
            }
        }
        return min(stage, PetConfig.shared.maxStages)
    }
}

// MARK: - Owned Pet (User's Instance)
struct OwnedPet: Identifiable, Codable, Equatable {
    let id: String
    let petDefinitionId: String
    var evolutionStage: Int
    var level: Int
    var experience: Int
    var mood: Int               // 1=sad, 2=content, 3=happy
    var lastFedDate: Date?
    var lastWateredDate: Date?
    var lastPettedDate: Date?
    var isEquipped: Bool
    var caughtDate: Date
    var consecutiveSadDays: Int
    var isLost: Bool

    init(
        id: String = UUID().uuidString,
        petDefinitionId: String,
        evolutionStage: Int = 1,
        level: Int = 1,
        experience: Int = 0,
        mood: Int = 3,
        lastFedDate: Date? = nil,
        lastWateredDate: Date? = nil,
        lastPettedDate: Date? = nil,
        isEquipped: Bool = false,
        caughtDate: Date = Date(),
        consecutiveSadDays: Int = 0,
        isLost: Bool = false
    ) {
        self.id = id
        self.petDefinitionId = petDefinitionId
        self.evolutionStage = evolutionStage
        self.level = level
        self.experience = experience
        self.mood = mood
        self.lastFedDate = lastFedDate
        self.lastWateredDate = lastWateredDate
        self.lastPettedDate = lastPettedDate
        self.isEquipped = isEquipped
        self.caughtDate = caughtDate
        self.consecutiveSadDays = consecutiveSadDays
        self.isLost = isLost
    }

    // Custom decoder for backward compatibility — `level` may be absent in old saved data
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        petDefinitionId = try container.decode(String.self, forKey: .petDefinitionId)
        evolutionStage = try container.decode(Int.self, forKey: .evolutionStage)
        level = try container.decodeIfPresent(Int.self, forKey: .level) ?? 1
        experience = try container.decode(Int.self, forKey: .experience)
        mood = try container.decode(Int.self, forKey: .mood)
        lastFedDate = try container.decodeIfPresent(Date.self, forKey: .lastFedDate)
        lastWateredDate = try container.decodeIfPresent(Date.self, forKey: .lastWateredDate)
        lastPettedDate = try container.decodeIfPresent(Date.self, forKey: .lastPettedDate)
        isEquipped = try container.decode(Bool.self, forKey: .isEquipped)
        caughtDate = try container.decode(Date.self, forKey: .caughtDate)
        consecutiveSadDays = try container.decode(Int.self, forKey: .consecutiveSadDays)
        isLost = try container.decode(Bool.self, forKey: .isLost)
    }

    var definition: GamePetDefinition? {
        GameData.pet(byId: petDefinitionId)
    }

    var currentImageName: String {
        guard let def = definition,
              evolutionStage >= 1,
              evolutionStage <= def.stageImageNames.count else {
            return "pet_placeholder"
        }
        return def.stageImageNames[evolutionStage - 1]
    }

    var stageName: String {
        PetConfig.shared.stageName(for: evolutionStage)
    }

    // MARK: - Level-Based XP Progress

    var xpForCurrentLevel: Int {
        PetConfig.shared.xpRequiredForLevel(level)
    }

    var xpForNextLevel: Int {
        guard level < PetConfig.shared.petMaxLevel else { return xpForCurrentLevel }
        return PetConfig.shared.xpRequiredForLevel(level + 1)
    }

    var xpProgress: Double {
        let current = xpForCurrentLevel
        let next = xpForNextLevel
        guard next > current else { return 1.0 }
        let progress = Double(experience - current) / Double(next - current)
        return min(max(progress, 0), 1.0)
    }

    var isMaxLevel: Bool {
        level >= PetConfig.shared.petMaxLevel
    }

    var xpMultiplier: Double {
        PetConfig.shared.xpMultiplier(forMood: mood)
    }

    var moodName: String {
        switch mood {
        case 3: return "Happy"
        case 2: return "Content"
        default: return "Sad"
        }
    }

    var canEarnFeedXP: Bool {
        guard let lastFed = lastFedDate else { return true }
        return !Calendar.current.isDateInToday(lastFed)
    }

    var canEarnWaterXP: Bool {
        guard let lastWatered = lastWateredDate else { return true }
        return !Calendar.current.isDateInToday(lastWatered)
    }

    var canEarnPetXP: Bool {
        guard let lastPetted = lastPettedDate else { return true }
        return !Calendar.current.isDateInToday(lastPetted)
    }
}

// MARK: - Care Need Type
enum CareNeedType: String, Codable, CaseIterable {
    case hungry
    case thirsty
    case lonely

    var displayText: String {
        switch self {
        case .hungry: return "hungry"
        case .thirsty: return "thirsty"
        case .lonely: return "lonely"
        }
    }

    var actionVerb: String {
        switch self {
        case .hungry: return "Feed"
        case .thirsty: return "Water"
        case .lonely: return "Pet"
        }
    }
}

// MARK: - Boost Type
enum BoostType: String, Codable {
    case xpBoost         // +30% XP for 2 hours
    case encounterCharm  // +3% catch rate for 1 run (8% -> 11%)
    case coinBoost       // +40% coins for 1 run
    case streakFreeze    // Protect streak for 3 days

    // Legacy mapping for backward compatibility
    case encounterBoost
}

struct ActiveBoost: Codable, Equatable {
    let type: BoostType
    let expiresAt: Date

    var isActive: Bool { Date() < expiresAt }

    var remainingSeconds: TimeInterval {
        max(0, expiresAt.timeIntervalSinceNow)
    }
}

// MARK: - Run Summary
struct CompletedRun: Identifiable, Codable, Equatable {
    let id: String
    let date: Date
    let durationSeconds: Int
    let distanceMeters: Double
    let sprintsCompleted: Int
    let coinsEarned: Int
    let xpEarned: Int
    let petCaughtId: String?

    init(
        id: String = UUID().uuidString,
        date: Date = Date(),
        durationSeconds: Int = 0,
        distanceMeters: Double = 0,
        sprintsCompleted: Int = 0,
        coinsEarned: Int = 0,
        xpEarned: Int = 0,
        petCaughtId: String? = nil
    ) {
        self.id = id
        self.date = date
        self.durationSeconds = durationSeconds
        self.distanceMeters = distanceMeters
        self.sprintsCompleted = sprintsCompleted
        self.coinsEarned = coinsEarned
        self.xpEarned = xpEarned
        self.petCaughtId = petCaughtId
    }
}

// MARK: - Collection Extension
extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
