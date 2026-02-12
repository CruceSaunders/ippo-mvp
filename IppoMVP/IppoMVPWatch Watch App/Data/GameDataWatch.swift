import Foundation

// Simplified pet definition for Watch
struct GamePetDefinitionWatch {
    let id: String
    let name: String
    let emoji: String
}

@MainActor
final class GameDataWatch {
    static let shared = GameDataWatch()
    
    let allPets: [GamePetDefinitionWatch] = [
        GamePetDefinitionWatch(id: "pet_01", name: "Ember", emoji: "🔥"),
        GamePetDefinitionWatch(id: "pet_02", name: "Splash", emoji: "💧"),
        GamePetDefinitionWatch(id: "pet_03", name: "Sprout", emoji: "🌱"),
        GamePetDefinitionWatch(id: "pet_04", name: "Zephyr", emoji: "🌬️"),
        GamePetDefinitionWatch(id: "pet_05", name: "Pebble", emoji: "🪨"),
        GamePetDefinitionWatch(id: "pet_06", name: "Spark", emoji: "⚡"),
        GamePetDefinitionWatch(id: "pet_07", name: "Shadow", emoji: "👤"),
        GamePetDefinitionWatch(id: "pet_08", name: "Frost", emoji: "❄️"),
        GamePetDefinitionWatch(id: "pet_09", name: "Blaze", emoji: "🔥"),
        GamePetDefinitionWatch(id: "pet_10", name: "Luna", emoji: "🌙")
    ]
    
    func pet(byId id: String) -> GamePetDefinitionWatch? {
        allPets.first { $0.id == id }
    }
    
    private init() {}
}
