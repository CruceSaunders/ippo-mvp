import Foundation

enum GameData {
    static let petDefinitions: [GamePetDefinition] = [
        // MARK: - Starters (3)
        GamePetDefinition(
            id: "pet_01",
            name: "Lumira",
            description: "A gentle spirit that glows brighter as it grows",
            hintText: "A gentle glow in the dark...",
            stageImageNames: (1...3).map { "lumira_\(String(format: "%02d", $0))" },
            isStarter: true,
            evolutionLevels: [2: 8, 3: 14]
        ),
        GamePetDefinition(
            id: "pet_02",
            name: "Mossworth",
            description: "A mossy friend who loves the shade of old trees",
            hintText: "Something stirs beneath the moss...",
            stageImageNames: (1...3).map { "mossworth_\(String(format: "%02d", $0))" },
            isStarter: true,
            evolutionLevels: [2: 7, 3: 13]
        ),
        GamePetDefinition(
            id: "pet_03",
            name: "Dewdrop",
            description: "A little sea dragon who dreams of the deep",
            hintText: "A playful ripple in the tide pools...",
            stageImageNames: (1...3).map { "dewdrop_\(String(format: "%02d", $0))" },
            isStarter: true,
            evolutionLevels: [2: 9, 3: 15]
        ),

        // New catchable pets are added here. See .cursorrules "Adding a New Pet" for the process.
    ]

    static func pet(byId id: String) -> GamePetDefinition? {
        petDefinitions.first { $0.id == id }
    }

    /// All non-starter pet IDs that can be caught during runs.
    static var catchablePetIds: [String] {
        petDefinitions.filter { !$0.isStarter }.map { $0.id }
    }
}
