import Foundation

enum GameData {
    static let petDefinitions: [GamePetDefinition] = [
        // MARK: - Starters (3)
        GamePetDefinition(
            id: "pet_01",
            name: "Lumira",
            description: "A gentle spirit that glows brighter as it grows",
            hintText: "A gentle glow in the dark...",
            personality: "Playful and adventurous. Loves sunrise runs and gets excited when you pick up the pace.",
            stageImageNames: (1...3).map { "lumira_\(String(format: "%02d", $0))" },
            isStarter: true,
            evolutionLevels: [2: 6, 3: 18]
        ),
        GamePetDefinition(
            id: "pet_02",
            name: "Mossworth",
            description: "A mossy friend who loves the shade of old trees",
            hintText: "Something stirs beneath the moss...",
            personality: "Calm and nurturing. Prefers evening strolls and loves being petted after a long day.",
            stageImageNames: (1...3).map { "mossworth_\(String(format: "%02d", $0))" },
            isStarter: true,
            evolutionLevels: [2: 7, 3: 19]
        ),
        GamePetDefinition(
            id: "pet_03",
            name: "Dewdrop",
            description: "A little sea dragon who dreams of the deep",
            hintText: "A playful ripple in the tide pools...",
            personality: "Curious and dreamy. Gets extra happy when it rains and loves splashing in puddles.",
            stageImageNames: (1...3).map { "dewdrop_\(String(format: "%02d", $0))" },
            isStarter: true,
            evolutionLevels: [2: 5, 3: 17]
        ),

        // MARK: - Catchable Pets (7)
        GamePetDefinition(
            id: "pet_04",
            name: "Bramble",
            description: "A cheeky squirrel whose berry-laden tail grows into a magnificent orchard",
            hintText: "Tiny paw prints surrounded by scattered berries...",
            personality: "Mischievous and energetic. Loves trail runs and hoards treats like acorns.",
            stageImageNames: (1...3).map { "bramble_\(String(format: "%02d", $0))" },
            evolutionLevels: [2: 6, 3: 17]
        ),
        GamePetDefinition(
            id: "pet_05",
            name: "Zephyr",
            description: "A sky serpent born from storm clouds, crowned with lightning",
            hintText: "A wisp of cloud that seems to have eyes...",
            personality: "Fierce and competitive. Thrives during fast sprints and windy weather.",
            stageImageNames: (1...3).map { "zephyr_\(String(format: "%02d", $0))" },
            evolutionLevels: [2: 8, 3: 20]
        ),
        GamePetDefinition(
            id: "pet_06",
            name: "Coraline",
            description: "A reef bunny who blooms with living coral as she grows",
            hintText: "Bubbles rise from a patch of pink coral...",
            personality: "Sweet and social. Happiest after being petted and loves company.",
            stageImageNames: (1...3).map { "coraline_\(String(format: "%02d", $0))" },
            evolutionLevels: [2: 7, 3: 19]
        ),
        GamePetDefinition(
            id: "pet_07",
            name: "Cinders",
            description: "A fire salamander whose inner flame blazes into dragon wings",
            hintText: "Scorch marks shaped like tiny footprints...",
            personality: "Bold and warm-hearted. Gets fired up during intense sprints.",
            stageImageNames: (1...3).map { "cinders_\(String(format: "%02d", $0))" },
            evolutionLevels: [2: 5, 3: 18]
        ),
        GamePetDefinition(
            id: "pet_08",
            name: "Glaciel",
            description: "A crystal deer whose antlers grow into frozen chandeliers of ice",
            hintText: "Frost patterns that look like tiny hoofprints...",
            personality: "Graceful and serene. Loves cold morning runs and moves with quiet elegance.",
            stageImageNames: (1...3).map { "glaciel_\(String(format: "%02d", $0))" },
            evolutionLevels: [2: 6, 3: 20]
        ),
        GamePetDefinition(
            id: "pet_09",
            name: "Shale",
            description: "A hermit crab who builds an ever-grander shell garden",
            hintText: "A small rock that seems to scuttle away...",
            personality: "Steady and loyal. Takes a while to warm up but bonds deeply over time.",
            stageImageNames: (1...3).map { "shale_\(String(format: "%02d", $0))" },
            evolutionLevels: [2: 7, 3: 18]
        ),
        GamePetDefinition(
            id: "pet_10",
            name: "Stella",
            description: "A tidepool pup whose starfish glow guides lost sailors home",
            hintText: "A warm glow beneath the shallow waves...",
            personality: "Gentle and wise. Glows brighter on evening runs and loves stargazing.",
            stageImageNames: (1...3).map { "stella_\(String(format: "%02d", $0))" },
            evolutionLevels: [2: 8, 3: 17]
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
