import Foundation

// MARK: - Pet Definition (Static Game Data)
struct GamePetDefinition: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let description: String
    let hintText: String
    let stageImageNames: [String]  // 10 image names, one per evolution stage
    var hasIdleVideos: Bool = false
    var hasHappyVideos: Bool = false
    var isStarter: Bool = false

    var stageCount: Int { stageImageNames.count }
}

// MARK: - Owned Pet (User's Instance)
struct OwnedPet: Identifiable, Codable, Equatable {
    let id: String
    let petDefinitionId: String
    var evolutionStage: Int
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

    var xpForCurrentStage: Int {
        PetConfig.shared.xpThresholds[safe: evolutionStage - 1] ?? 0
    }

    var xpForNextStage: Int {
        guard evolutionStage < PetConfig.shared.maxStages else { return xpForCurrentStage }
        return PetConfig.shared.xpThresholds[safe: evolutionStage] ?? Int.max
    }

    var xpProgress: Double {
        let current = xpForCurrentStage
        let next = xpForNextStage
        guard next > current else { return 1.0 }
        let progress = Double(experience - current) / Double(next - current)
        return min(max(progress, 0), 1.0)
    }

    var isMaxEvolution: Bool {
        evolutionStage >= PetConfig.shared.maxStages
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
    case xpBoost        // +30% XP for 2 hours
    case encounterBoost // +50% catch rate for 1 run
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
