import Foundation

@MainActor
final class GameData {
    static let shared = GameData()
    
    // MARK: - The 10 Pets (nonisolated for cross-actor access)
    nonisolated let allPets: [GamePetDefinition] = GameData.petDefinitions
    
    // Static pet data - accessible from any context
    static let petDefinitions: [GamePetDefinition] = [
        GamePetDefinition(
            id: "pet_01",
            name: "Ember",
            description: "A fiery spirit that burns brightest in short bursts",
            abilityName: "Ignite",
            abilityDescription: "+15% RP on sprints under 35 seconds",
            abilityBaseValue: 0.15,
            evolutionImageNames: (1...10).map { "ember_stage_\(String(format: "%02d", $0))" }
        ),
        GamePetDefinition(
            id: "pet_02",
            name: "Splash",
            description: "A water creature that rewards steady effort",
            abilityName: "Flow",
            abilityDescription: "+10% passive XP during runs",
            abilityBaseValue: 0.10,
            evolutionImageNames: (1...10).map { "splash_stage_\(String(format: "%02d", $0))" }
        ),
        GamePetDefinition(
            id: "pet_03",
            name: "Sprout",
            description: "A plant being that helps all pets grow faster",
            abilityName: "Growth",
            abilityDescription: "+20% evolution XP gains",
            abilityBaseValue: 0.20,
            evolutionImageNames: (1...10).map { "sprout_stage_\(String(format: "%02d", $0))" }
        ),
        GamePetDefinition(
            id: "pet_04",
            name: "Zephyr",
            description: "An air spirit that attracts more sprint opportunities",
            abilityName: "Tailwind",
            abilityDescription: "+10% encounter chance",
            abilityBaseValue: 0.10,
            evolutionImageNames: (1...10).map { "zephyr_stage_\(String(format: "%02d", $0))" }
        ),
        GamePetDefinition(
            id: "pet_05",
            name: "Pebble",
            description: "A stone creature that stays content longer",
            abilityName: "Fortitude",
            abilityDescription: "-15% mood decay when inactive",
            abilityBaseValue: 0.15,
            evolutionImageNames: (1...10).map { "pebble_stage_\(String(format: "%02d", $0))" }
        ),
        GamePetDefinition(
            id: "pet_06",
            name: "Spark",
            description: "An electric being that amplifies rewards",
            abilityName: "Energize",
            abilityDescription: "+25% coins from loot boxes",
            abilityBaseValue: 0.25,
            evolutionImageNames: (1...10).map { "spark_stage_\(String(format: "%02d", $0))" }
        ),
        GamePetDefinition(
            id: "pet_07",
            name: "Shadow",
            description: "A dark creature that helps find others",
            abilityName: "Stealth",
            abilityDescription: "+5% catch rate for new pets",
            abilityBaseValue: 0.05,
            evolutionImageNames: (1...10).map { "shadow_stage_\(String(format: "%02d", $0))" }
        ),
        GamePetDefinition(
            id: "pet_08",
            name: "Frost",
            description: "An ice spirit that maximizes care rewards",
            abilityName: "Preserve",
            abilityDescription: "Feeding gives +50% XP",
            abilityBaseValue: 0.50,
            evolutionImageNames: (1...10).map { "frost_stage_\(String(format: "%02d", $0))" }
        ),
        GamePetDefinition(
            id: "pet_09",
            name: "Blaze",
            description: "A fire creature that rewards sustained effort",
            abilityName: "Intensity",
            abilityDescription: "+30% RP on sprints over 40 seconds",
            abilityBaseValue: 0.30,
            evolutionImageNames: (1...10).map { "blaze_stage_\(String(format: "%02d", $0))" }
        ),
        GamePetDefinition(
            id: "pet_10",
            name: "Luna",
            description: "A celestial being that enhances everything",
            abilityName: "Blessing",
            abilityDescription: "+5% to ALL other pet bonuses",
            abilityBaseValue: 0.05,
            evolutionImageNames: (1...10).map { "luna_stage_\(String(format: "%02d", $0))" }
        )
    ]
    
    // MARK: - Lookup (instance methods for MainActor context)
    func pet(byId id: String) -> GamePetDefinition? {
        allPets.first { $0.id == id }
    }
    
    func pet(byName name: String) -> GamePetDefinition? {
        allPets.first { $0.name.lowercased() == name.lowercased() }
    }
    
    // MARK: - Static Lookup (accessible from any context)
    nonisolated static func pet(byId id: String) -> GamePetDefinition? {
        petDefinitions.first { $0.id == id }
    }
    
    nonisolated static func pet(byName name: String) -> GamePetDefinition? {
        petDefinitions.first { $0.name.lowercased() == name.lowercased() }
    }
    
    // MARK: - Random Pet Selection
    func randomUnownedPet(ownedPetIds: Set<String>) -> GamePetDefinition? {
        let unowned = allPets.filter { !ownedPetIds.contains($0.id) }
        return unowned.randomElement()
    }
    
    // MARK: - Private Init
    private init() {}
}

// MARK: - Player Ability Tree Data (26 nodes: 1 origin + 5 branches of 5)
struct AbilityTreeData {
    
    // Layout constants for radial positioning
    // Origin at center-top (0.5, 0.08), branches fan out downward
    static let playerNodes: [AbilityNode] = [
        // ORIGIN - Runner's Core (free, no prerequisites)
        AbilityNode(
            id: "core",
            name: "Runner's Core",
            description: "Awaken your inner runner. Unlocks all ability paths.",
            tier: 0, cost: 0,
            effect: .allBonus(0.02),
            prerequisites: [],
            iconName: "figure.run.circle.fill",
            treeX: 0.50, treeY: 0.06
        ),
        
        // ═══════════════════════════════════════════
        // BRANCH 1: REPUTATION PATH (left)
        // ═══════════════════════════════════════════
        AbilityNode(
            id: "rp_1", name: "RP Boost I",
            description: "+5% RP from all sources",
            tier: 1, cost: 1,
            effect: .rpBonus(0.05),
            prerequisites: ["core"],
            iconName: "star.fill",
            treeX: 0.10, treeY: 0.22
        ),
        AbilityNode(
            id: "rp_2", name: "RP Boost II",
            description: "+10% RP from all sources",
            tier: 2, cost: 2,
            effect: .rpBonus(0.10),
            prerequisites: ["rp_1"],
            iconName: "star.fill",
            treeX: 0.08, treeY: 0.38
        ),
        AbilityNode(
            id: "rp_surge", name: "RP Surge",
            description: "+15% RP on validated sprints",
            tier: 3, cost: 3,
            effect: .rpBonus(0.15),
            prerequisites: ["rp_2"],
            iconName: "star.circle.fill",
            treeX: 0.06, treeY: 0.54
        ),
        AbilityNode(
            id: "rp_master", name: "Reputation Master",
            description: "+20% RP from all sources",
            tier: 4, cost: 4,
            effect: .rpBonus(0.20),
            prerequisites: ["rp_surge"],
            iconName: "star.square.fill",
            treeX: 0.08, treeY: 0.70
        ),
        AbilityNode(
            id: "rp_mastery", name: "RP Mastery",
            description: "+25% RP + faster rank progression",
            tier: 5, cost: 5,
            effect: .rpBonus(0.25),
            prerequisites: ["rp_master"],
            iconName: "trophy.fill",
            treeX: 0.10, treeY: 0.86
        ),
        
        // ═══════════════════════════════════════════
        // BRANCH 2: EXPERIENCE PATH (center-left)
        // ═══════════════════════════════════════════
        AbilityNode(
            id: "xp_1", name: "XP Boost I",
            description: "+5% XP from all sources",
            tier: 1, cost: 1,
            effect: .xpBonus(0.05),
            prerequisites: ["core"],
            iconName: "arrow.up.circle.fill",
            treeX: 0.30, treeY: 0.22
        ),
        AbilityNode(
            id: "xp_2", name: "XP Boost II",
            description: "+10% XP from all sources",
            tier: 2, cost: 2,
            effect: .xpBonus(0.10),
            prerequisites: ["xp_1"],
            iconName: "arrow.up.circle.fill",
            treeX: 0.28, treeY: 0.38
        ),
        AbilityNode(
            id: "quick_learner", name: "Quick Learner",
            description: "+15% XP + faster level ups",
            tier: 3, cost: 3,
            effect: .xpBonus(0.15),
            prerequisites: ["xp_2"],
            iconName: "brain.head.profile",
            treeX: 0.26, treeY: 0.54
        ),
        AbilityNode(
            id: "knowledge_seeker", name: "Knowledge Seeker",
            description: "+20% XP + bonus AP on level up",
            tier: 4, cost: 4,
            effect: .xpBonus(0.20),
            prerequisites: ["quick_learner"],
            iconName: "book.fill",
            treeX: 0.28, treeY: 0.70
        ),
        AbilityNode(
            id: "xp_mastery", name: "XP Mastery",
            description: "+25% XP from everything",
            tier: 5, cost: 5,
            effect: .xpBonus(0.25),
            prerequisites: ["knowledge_seeker"],
            iconName: "graduationcap.fill",
            treeX: 0.30, treeY: 0.86
        ),
        
        // ═══════════════════════════════════════════
        // BRANCH 3: SPRINT PATH (center)
        // ═══════════════════════════════════════════
        AbilityNode(
            id: "sprint_1", name: "Sprint Power I",
            description: "+5% to all sprint rewards",
            tier: 1, cost: 1,
            effect: .sprintBonus(0.05),
            prerequisites: ["core"],
            iconName: "bolt.fill",
            treeX: 0.50, treeY: 0.22
        ),
        AbilityNode(
            id: "sprint_2", name: "Sprint Power II",
            description: "+10% to all sprint rewards",
            tier: 2, cost: 2,
            effect: .sprintBonus(0.10),
            prerequisites: ["sprint_1"],
            iconName: "bolt.fill",
            treeX: 0.50, treeY: 0.38
        ),
        AbilityNode(
            id: "sprint_recovery", name: "Sprint Recovery",
            description: "+15% sprint rewards + shorter cooldown",
            tier: 3, cost: 3,
            effect: .sprintBonus(0.15),
            prerequisites: ["sprint_2"],
            iconName: "bolt.heart.fill",
            treeX: 0.50, treeY: 0.54
        ),
        AbilityNode(
            id: "sprint_streak", name: "Sprint Streak",
            description: "+50% passive rewards while running",
            tier: 4, cost: 4,
            effect: .passiveBonus(0.50),
            prerequisites: ["sprint_recovery"],
            iconName: "flame.fill",
            treeX: 0.50, treeY: 0.70
        ),
        AbilityNode(
            id: "sprint_mastery", name: "Sprint Mastery",
            description: "+20% all sprint bonuses",
            tier: 5, cost: 5,
            effect: .sprintBonus(0.20),
            prerequisites: ["sprint_streak"],
            iconName: "bolt.circle.fill",
            treeX: 0.50, treeY: 0.86
        ),
        
        // ═══════════════════════════════════════════
        // BRANCH 4: PET BOND PATH (center-right)
        // ═══════════════════════════════════════════
        AbilityNode(
            id: "pet_lover", name: "Pet Lover",
            description: "+15% pet evolution XP",
            tier: 1, cost: 1,
            effect: .petXpBonus(0.15),
            prerequisites: ["core"],
            iconName: "heart.fill",
            treeX: 0.70, treeY: 0.22
        ),
        AbilityNode(
            id: "pet_whisperer", name: "Pet Whisperer",
            description: "+25% pet evolution XP",
            tier: 2, cost: 2,
            effect: .petXpBonus(0.25),
            prerequisites: ["pet_lover"],
            iconName: "pawprint.fill",
            treeX: 0.72, treeY: 0.38
        ),
        AbilityNode(
            id: "evolution_boost", name: "Evolution Boost",
            description: "-20% XP needed for pet evolution",
            tier: 3, cost: 3,
            effect: .evolutionDiscount(0.20),
            prerequisites: ["pet_whisperer"],
            iconName: "sparkles",
            treeX: 0.74, treeY: 0.54
        ),
        AbilityNode(
            id: "catch_rate_up", name: "Catch Rate Up",
            description: "+3% pet catch rate",
            tier: 4, cost: 4,
            effect: .catchRateBonus(0.03),
            prerequisites: ["evolution_boost"],
            iconName: "scope",
            treeX: 0.72, treeY: 0.70
        ),
        AbilityNode(
            id: "pet_mastery", name: "Pet Mastery",
            description: "+5% catch rate + 30% pet XP",
            tier: 5, cost: 5,
            effect: .petXpBonus(0.30),
            prerequisites: ["catch_rate_up"],
            iconName: "pawprint.circle.fill",
            treeX: 0.70, treeY: 0.86
        ),
        
        // ═══════════════════════════════════════════
        // BRANCH 5: WEALTH PATH (right)
        // ═══════════════════════════════════════════
        AbilityNode(
            id: "coin_1", name: "Coin Boost I",
            description: "+5% coins from all sources",
            tier: 1, cost: 1,
            effect: .coinBonus(0.05),
            prerequisites: ["core"],
            iconName: "dollarsign.circle.fill",
            treeX: 0.90, treeY: 0.22
        ),
        AbilityNode(
            id: "coin_2", name: "Coin Boost II",
            description: "+10% coins from all sources",
            tier: 2, cost: 2,
            effect: .coinBonus(0.10),
            prerequisites: ["coin_1"],
            iconName: "dollarsign.circle.fill",
            treeX: 0.92, treeY: 0.38
        ),
        AbilityNode(
            id: "treasure_sense", name: "Treasure Sense",
            description: "+15% coins + loot box quality",
            tier: 3, cost: 3,
            effect: .coinBonus(0.15),
            prerequisites: ["coin_2"],
            iconName: "sparkle.magnifyingglass",
            treeX: 0.94, treeY: 0.54
        ),
        AbilityNode(
            id: "loot_luck", name: "Loot Luck",
            description: "+15% chance of rare loot boxes",
            tier: 4, cost: 4,
            effect: .lootLuckBonus(0.15),
            prerequisites: ["treasure_sense"],
            iconName: "gift.fill",
            treeX: 0.92, treeY: 0.70
        ),
        AbilityNode(
            id: "wealth_mastery", name: "Wealth Mastery",
            description: "+25% all coin rewards",
            tier: 5, cost: 5,
            effect: .coinBonus(0.25),
            prerequisites: ["loot_luck"],
            iconName: "banknote.fill",
            treeX: 0.90, treeY: 0.86
        ),
    ]
    
    // MARK: - Node Lookup
    static func node(byId id: String) -> AbilityNode? {
        playerNodes.first { $0.id == id }
    }
    
    static func nodesByTier(_ tier: Int) -> [AbilityNode] {
        playerNodes.filter { $0.tier == tier }
    }
    
    // MARK: - Tree Edges (for visualization)
    static var edges: [(from: String, to: String)] {
        var result: [(String, String)] = []
        for node in playerNodes {
            for prereq in node.prerequisites {
                result.append((prereq, node.id))
            }
        }
        return result
    }
}
