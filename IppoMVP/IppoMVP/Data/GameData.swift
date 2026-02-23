import Foundation

@MainActor
final class GameData {
    static let shared = GameData()

    nonisolated let allPets: [GamePetDefinition] = GameData.petDefinitions

    nonisolated var starterPets: [GamePetDefinition] {
        petDefinitions.filter { $0.isStarter }
    }

    static let petDefinitions: [GamePetDefinition] = [
        // MARK: - Starters (3)
        GamePetDefinition(
            id: "pet_01",
            name: "Lumira",
            description: "A gentle spirit that glows brighter as it grows",
            hintText: "A gentle glow in the dark...",
            stageImageNames: (1...10).map { "lumira_\(String(format: "%02d", $0))" },
            isStarter: true
        ),
        GamePetDefinition(
            id: "pet_02",
            name: "Mossworth",
            description: "A mossy friend who loves the shade of old trees",
            hintText: "Something stirs beneath the moss...",
            stageImageNames: (1...10).map { "mossworth_\(String(format: "%02d", $0))" },
            isStarter: true
        ),
        GamePetDefinition(
            id: "pet_03",
            name: "Puddlejoy",
            description: "A bubbly splash that dances in puddles",
            hintText: "A playful ripple in a rainy puddle...",
            stageImageNames: (1...10).map { "puddlejoy_\(String(format: "%02d", $0))" },
            isStarter: true
        ),

        // MARK: - Catchable (7)
        GamePetDefinition(
            id: "pet_04",
            name: "Cinders",
            description: "A tiny flame that never burns, only warms",
            hintText: "A warm glow in the forest...",
            stageImageNames: (1...10).map { "cinders_\(String(format: "%02d", $0))" }
        ),
        GamePetDefinition(
            id: "pet_05",
            name: "Breezling",
            description: "A little cloud that rides the wind",
            hintText: "A whisper carried on the breeze...",
            stageImageNames: (1...10).map { "breezling_\(String(format: "%02d", $0))" }
        ),
        GamePetDefinition(
            id: "pet_06",
            name: "Pebblet",
            description: "A sturdy little rock with a heart of gold",
            hintText: "A stone that hums with warmth...",
            stageImageNames: (1...10).map { "pebblet_\(String(format: "%02d", $0))" }
        ),
        GamePetDefinition(
            id: "pet_07",
            name: "Bloomsy",
            description: "A flower bud waiting for the right moment to bloom",
            hintText: "A flower bud waiting to open...",
            stageImageNames: (1...10).map { "bloomsy_\(String(format: "%02d", $0))" }
        ),
        GamePetDefinition(
            id: "pet_08",
            name: "Starkit",
            description: "A fragment of a falling star, still sparkling",
            hintText: "A sparkle that fell from the sky...",
            stageImageNames: (1...10).map { "starkit_\(String(format: "%02d", $0))" }
        ),
        GamePetDefinition(
            id: "pet_09",
            name: "Duskfawn",
            description: "A shy creature that appears at sunset",
            hintText: "A shadow that dances at twilight...",
            stageImageNames: (1...10).map { "duskfawn_\(String(format: "%02d", $0))" }
        ),
        GamePetDefinition(
            id: "pet_10",
            name: "Coralette",
            description: "A tiny shell humming with the sound of the sea",
            hintText: "A melody from beneath the waves...",
            stageImageNames: (1...10).map { "coralette_\(String(format: "%02d", $0))" }
        ),
    ]

    // MARK: - Lookup (instance)
    func pet(byId id: String) -> GamePetDefinition? {
        allPets.first { $0.id == id }
    }

    // MARK: - Static Lookup
    nonisolated static func pet(byId id: String) -> GamePetDefinition? {
        petDefinitions.first { $0.id == id }
    }

    // MARK: - Random Unowned Pet
    func randomUnownedPet(ownedPetIds: Set<String>) -> GamePetDefinition? {
        let unowned = allPets.filter { !$0.isStarter && !ownedPetIds.contains($0.id) }
        return unowned.randomElement()
    }

    private init() {}
}
