import Foundation

// MARK: - Pet Definition (Static Game Data)
struct GamePetDefinition: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let description: String
    let abilityName: String
    let abilityDescription: String
    let abilityBaseValue: Double
    let evolutionImageNames: [String]
    
    var emoji: String {
        switch id {
        case "pet_01": return "🔥"
        case "pet_02": return "💧"
        case "pet_03": return "🌱"
        case "pet_04": return "🌬️"
        case "pet_05": return "🪨"
        case "pet_06": return "⚡"
        case "pet_07": return "👤"
        case "pet_08": return "❄️"
        case "pet_09": return "🔥"
        case "pet_10": return "🌙"
        default: return "🐾"
        }
    }
    
    /// Maps pet definition IDs to xcassets image names
    var imageAssetName: String? {
        switch id {
        case "pet_01": return "emberhart"    // Ember -> Infernal Legendary
        case "pet_02": return "solarok"      // Splash -> Aquatic Epic
        case "pet_03": return "azyrith"      // Sprout -> Verdant Legendary
        case "pet_04": return "aurivern"     // Zephyr -> Celestial
        case "pet_05": return "kryonith"     // Pebble -> Verdant Epic
        case "pet_06": return "lumirith"     // Spark -> Radiant
        case "pet_07": return "nebulyth"     // Shadow -> Abyssal Legendary
        case "pet_08": return "flitfoal"     // Frost -> Abyssal Epic
        case "pet_09": return "cosmoose"     // Blaze -> Celestial Epic
        case "pet_10": return "astravyrn"    // Luna -> Celestial Legendary
        default: return nil
        }
    }
}

// MARK: - Owned Pet (User's Instance)
struct OwnedPet: Identifiable, Codable, Equatable {
    let id: String
    let petDefinitionId: String
    var evolutionStage: Int
    var experience: Int
    var mood: Int
    var lastFedDate: Date?
    var feedingsToday: Int
    var isEquipped: Bool
    var abilityLevel: Int
    var caughtDate: Date
    
    init(
        id: String = UUID().uuidString,
        petDefinitionId: String,
        evolutionStage: Int = 1,
        experience: Int = 0,
        mood: Int = 8,
        lastFedDate: Date? = nil,
        feedingsToday: Int = 0,
        isEquipped: Bool = false,
        abilityLevel: Int = 1,
        caughtDate: Date = Date()
    ) {
        self.id = id
        self.petDefinitionId = petDefinitionId
        self.evolutionStage = evolutionStage
        self.experience = experience
        self.mood = mood
        self.lastFedDate = lastFedDate
        self.feedingsToday = feedingsToday
        self.isEquipped = isEquipped
        self.abilityLevel = abilityLevel
        self.caughtDate = caughtDate
    }
    
    var definition: GamePetDefinition? {
        GameData.pet(byId: petDefinitionId)
    }
    
    var currentImageName: String {
        definition?.evolutionImageNames[evolutionStage - 1] ?? "pet_placeholder"
    }
    
    var stageName: String {
        switch evolutionStage {
        case 1: return "Newborn"
        case 2: return "Infant"
        case 3: return "Toddler"
        case 4: return "Child"
        case 5: return "Youth"
        case 6: return "Adolescent"
        case 7: return "Young Adult"
        case 8: return "Adult"
        case 9: return "Mature"
        case 10: return "Elder"
        default: return "Unknown"
        }
    }
    
    var xpForNextStage: Int {
        PetConfig.shared.xpPerEvolution[safe: evolutionStage] ?? Int.max
    }
    
    var xpProgress: Double {
        let required = xpForNextStage
        guard required > 0 && required != Int.max else { return 1.0 }
        let previousRequired = evolutionStage > 1 ? PetConfig.shared.xpPerEvolution[evolutionStage - 1] : 0
        let progressInStage = experience - previousRequired
        let xpNeededForStage = required - previousRequired
        return Double(progressInStage) / Double(xpNeededForStage)
    }
    
    var abilityEffectiveness: Double {
        // Base effectiveness by evolution stage
        let stageMultiplier: Double
        switch evolutionStage {
        case 1...3: stageMultiplier = 0.50
        case 4...6: stageMultiplier = 0.75
        case 7...9: stageMultiplier = 1.00
        case 10: stageMultiplier = 1.25
        default: stageMultiplier = 1.00
        }
        
        // Ability level multiplier (1.0, 1.25, 1.5, 1.75, 2.0)
        let abilityMultiplier = 1.0 + (Double(abilityLevel - 1) * 0.25)
        
        return stageMultiplier * abilityMultiplier
    }
    
    var moodEmoji: String {
        switch mood {
        case 8...10: return "😊"
        case 5...7: return "😐"
        case 3...4: return "😔"
        default: return "😢"
        }
    }
    
    var canBeFed: Bool {
        guard let lastFed = lastFedDate else { return true }
        return !Calendar.current.isDateInToday(lastFed) || feedingsToday < PetConfig.shared.maxFeedingsPerDay
    }
}

// MARK: - Rarity
enum Rarity: String, Codable, CaseIterable {
    case common
    case uncommon
    case rare
    case epic
    case legendary
    
    var displayName: String {
        rawValue.capitalized
    }
}

// MARK: - Collection Extension
extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
