import XCTest
@testable import IppoMVP

final class AbilityTreeSystemTests: XCTestCase {
    
    // MARK: - Test Fixtures
    
    /// Creates a UserAbilities instance for testing
    private func makeAbilities(
        abilityPoints: Int = 0,
        petPoints: Int = 0,
        unlockedAbilities: Set<String> = [],
        petAbilityLevels: [String: Int] = [:]
    ) -> UserAbilities {
        UserAbilities(
            abilityPoints: abilityPoints,
            petPoints: petPoints,
            unlockedPlayerAbilities: unlockedAbilities,
            petAbilityLevels: petAbilityLevels
        )
    }
    
    /// Creates a test node for isolated testing
    private func makeNode(
        id: String = "test_node",
        name: String = "Test Node",
        tier: Int = 1,
        cost: Int = 1,
        effect: AbilityEffect = .rpBonus(0.05),
        prerequisites: [String] = []
    ) -> AbilityNode {
        AbilityNode(
            id: id,
            name: name,
            description: "Test description",
            tier: tier,
            cost: cost,
            effect: effect,
            prerequisites: prerequisites,
            iconName: "star.fill",
            treeX: 0.5,
            treeY: 0.5
        )
    }
    
    let config = AbilityConfig.shared
    
    // MARK: - UserAbilities.canUnlock Tests
    
    func testCanUnlockWithSufficientAPAndNoPrereqs() {
        let abilities = makeAbilities(abilityPoints: 5)
        let node = makeNode(cost: 3, prerequisites: [])
        
        XCTAssertTrue(abilities.canUnlock(node))
    }
    
    func testCannotUnlockWithInsufficientAP() {
        let abilities = makeAbilities(abilityPoints: 2)
        let node = makeNode(cost: 3, prerequisites: [])
        
        XCTAssertFalse(abilities.canUnlock(node))
    }
    
    func testCannotUnlockExactlyAtCost() {
        let abilities = makeAbilities(abilityPoints: 3)
        let node = makeNode(cost: 3, prerequisites: [])
        
        XCTAssertTrue(abilities.canUnlock(node), "Should be able to unlock when AP equals cost")
    }
    
    func testCannotUnlockAlreadyUnlocked() {
        let abilities = makeAbilities(abilityPoints: 10, unlockedAbilities: ["test_node"])
        let node = makeNode(id: "test_node", cost: 1)
        
        XCTAssertFalse(abilities.canUnlock(node))
    }
    
    func testCannotUnlockWithMissingPrereqs() {
        let abilities = makeAbilities(abilityPoints: 10)
        let node = makeNode(cost: 1, prerequisites: ["prereq_1", "prereq_2"])
        
        XCTAssertFalse(abilities.canUnlock(node))
    }
    
    func testCannotUnlockWithPartialPrereqs() {
        let abilities = makeAbilities(abilityPoints: 10, unlockedAbilities: ["prereq_1"])
        let node = makeNode(cost: 1, prerequisites: ["prereq_1", "prereq_2"])
        
        XCTAssertFalse(abilities.canUnlock(node))
    }
    
    func testCanUnlockWithAllPrereqs() {
        let abilities = makeAbilities(abilityPoints: 10, unlockedAbilities: ["prereq_1", "prereq_2"])
        let node = makeNode(cost: 1, prerequisites: ["prereq_1", "prereq_2"])
        
        XCTAssertTrue(abilities.canUnlock(node))
    }
    
    func testCanUnlockWithEmptyPrereqs() {
        let abilities = makeAbilities(abilityPoints: 5)
        let node = makeNode(cost: 1, prerequisites: [])
        
        XCTAssertTrue(abilities.canUnlock(node))
    }
    
    // MARK: - UserAbilities.unlock Tests
    
    func testUnlockDeductsAP() {
        var abilities = makeAbilities(abilityPoints: 10)
        let node = makeNode(cost: 3)
        
        let success = abilities.unlock(node)
        
        XCTAssertTrue(success)
        XCTAssertEqual(abilities.abilityPoints, 7)
    }
    
    func testUnlockAddsToUnlockedSet() {
        var abilities = makeAbilities(abilityPoints: 10)
        let node = makeNode(id: "new_ability", cost: 1)
        
        _ = abilities.unlock(node)
        
        XCTAssertTrue(abilities.unlockedPlayerAbilities.contains("new_ability"))
    }
    
    func testUnlockFailsWhenCannotUnlock() {
        var abilities = makeAbilities(abilityPoints: 0)
        let node = makeNode(cost: 5)
        
        let success = abilities.unlock(node)
        
        XCTAssertFalse(success)
        XCTAssertEqual(abilities.abilityPoints, 0)
        XCTAssertFalse(abilities.unlockedPlayerAbilities.contains(node.id))
    }
    
    func testUnlockFailsForAlreadyUnlocked() {
        var abilities = makeAbilities(abilityPoints: 10, unlockedAbilities: ["test_node"])
        let initialAP = abilities.abilityPoints
        let node = makeNode(id: "test_node", cost: 1)
        
        let success = abilities.unlock(node)
        
        XCTAssertFalse(success)
        XCTAssertEqual(abilities.abilityPoints, initialAP, "AP should not be deducted")
    }
    
    func testUnlockMultipleNodesSequentially() {
        var abilities = makeAbilities(abilityPoints: 10)
        let node1 = makeNode(id: "node_1", cost: 2, prerequisites: [])
        let node2 = makeNode(id: "node_2", cost: 3, prerequisites: ["node_1"])
        
        let success1 = abilities.unlock(node1)
        XCTAssertTrue(success1)
        XCTAssertEqual(abilities.abilityPoints, 8)
        
        let success2 = abilities.unlock(node2)
        XCTAssertTrue(success2)
        XCTAssertEqual(abilities.abilityPoints, 5)
    }
    
    // MARK: - Pet Ability Level Tests
    
    func testGetPetAbilityLevelDefaultsTo1() {
        let abilities = makeAbilities()
        
        let level = abilities.getPetAbilityLevel(for: "random_pet_id")
        
        XCTAssertEqual(level, 1)
    }
    
    func testGetPetAbilityLevelReturnsStoredLevel() {
        let abilities = makeAbilities(petAbilityLevels: ["pet_123": 3])
        
        let level = abilities.getPetAbilityLevel(for: "pet_123")
        
        XCTAssertEqual(level, 3)
    }
    
    func testCanUpgradePetAbilityWithSufficientPP() {
        let abilities = makeAbilities(petPoints: 10)
        
        XCTAssertTrue(abilities.canUpgradePetAbility(petId: "any_pet"))
    }
    
    func testCannotUpgradePetAbilityWithInsufficientPP() {
        // Level 1 -> 2 costs 2 PP
        let abilities = makeAbilities(petPoints: 1)
        
        XCTAssertFalse(abilities.canUpgradePetAbility(petId: "any_pet"))
    }
    
    func testCannotUpgradePetAbilityAtMaxLevel() {
        let abilities = makeAbilities(petPoints: 100, petAbilityLevels: ["pet_123": 5])
        
        XCTAssertFalse(abilities.canUpgradePetAbility(petId: "pet_123"))
    }
    
    func testUpgradePetAbilityDeductsPP() {
        var abilities = makeAbilities(petPoints: 10)
        
        // Level 1 -> 2 costs 2 PP (level + 1)
        let success = abilities.upgradePetAbility(petId: "pet_123")
        
        XCTAssertTrue(success)
        XCTAssertEqual(abilities.petPoints, 8)  // 10 - 2
    }
    
    func testUpgradePetAbilityIncrementsLevel() {
        var abilities = makeAbilities(petPoints: 10)
        
        _ = abilities.upgradePetAbility(petId: "pet_123")
        
        XCTAssertEqual(abilities.getPetAbilityLevel(for: "pet_123"), 2)
    }
    
    func testUpgradePetAbilityFailsAtMaxLevel() {
        var abilities = makeAbilities(petPoints: 100, petAbilityLevels: ["pet_123": 5])
        let initialPP = abilities.petPoints
        
        let success = abilities.upgradePetAbility(petId: "pet_123")
        
        XCTAssertFalse(success)
        XCTAssertEqual(abilities.petPoints, initialPP)
        XCTAssertEqual(abilities.getPetAbilityLevel(for: "pet_123"), 5)
    }
    
    func testUpgradePetAbilityCostScales() {
        // Level 2 costs 2, Level 3 costs 3, Level 4 costs 4, Level 5 costs 5
        // Total: 2+3+4+5 = 14 PP to max from level 1
        var abilities = makeAbilities(petPoints: 20)
        
        _ = abilities.upgradePetAbility(petId: "pet")  // 1->2, cost 2, remaining 18
        XCTAssertEqual(abilities.petPoints, 18)
        
        _ = abilities.upgradePetAbility(petId: "pet")  // 2->3, cost 3, remaining 15
        XCTAssertEqual(abilities.petPoints, 15)
        
        _ = abilities.upgradePetAbility(petId: "pet")  // 3->4, cost 4, remaining 11
        XCTAssertEqual(abilities.petPoints, 11)
        
        _ = abilities.upgradePetAbility(petId: "pet")  // 4->5, cost 5, remaining 6
        XCTAssertEqual(abilities.petPoints, 6)
        
        XCTAssertEqual(abilities.getPetAbilityLevel(for: "pet"), 5)
    }
    
    // MARK: - Bonus Calculation Tests
    
    func testRPBonusWithNoAbilities() {
        let abilities = makeAbilities()
        
        XCTAssertEqual(abilities.rpBonusTotal, 0.0)
    }
    
    func testRPBonusWithSingleAbility() {
        // rp_1 gives +5% RP
        let abilities = makeAbilities(unlockedAbilities: ["rp_1"])
        
        XCTAssertEqual(abilities.rpBonusTotal, 0.05, accuracy: 0.001)
    }
    
    func testRPBonusStacksMultipleAbilities() {
        // rp_1 (+5%) + rp_2 (+10%) = 15%
        let abilities = makeAbilities(unlockedAbilities: ["rp_1", "rp_2"])
        
        XCTAssertEqual(abilities.rpBonusTotal, 0.15, accuracy: 0.001)
    }
    
    func testRPBonusIncludesAllBonus() {
        // champion gives +25% all (includes RP)
        let abilities = makeAbilities(unlockedAbilities: ["champion"])
        
        XCTAssertEqual(abilities.rpBonusTotal, 0.25, accuracy: 0.001)
    }
    
    func testRPBonusIncludesSprintBonus() {
        // sprint_master gives +15% sprint rewards (includes RP)
        let abilities = makeAbilities(unlockedAbilities: ["sprint_master"])
        
        XCTAssertEqual(abilities.rpBonusTotal, 0.15, accuracy: 0.001)
    }
    
    func testXPBonusCalculation() {
        // xp_1 (+5%) + xp_2 (+10%) = 15%
        let abilities = makeAbilities(unlockedAbilities: ["xp_1", "xp_2"])
        
        XCTAssertEqual(abilities.xpBonusTotal, 0.15, accuracy: 0.001)
    }
    
    func testCoinBonusCalculation() {
        // coin_1 (+5%) + coin_2 (+10%) + treasure_hunter (+25%) = 40%
        let abilities = makeAbilities(unlockedAbilities: ["coin_1", "coin_2", "treasure_hunter"])
        
        XCTAssertEqual(abilities.coinBonusTotal, 0.40, accuracy: 0.001)
    }
    
    func testCatchRateBonusCalculation() {
        // lucky_runner gives +2% catch rate
        let abilities = makeAbilities(unlockedAbilities: ["lucky_runner"])
        
        XCTAssertEqual(abilities.catchRateBonusTotal, 0.02, accuracy: 0.001)
    }
    
    func testPetXPBonusCalculation() {
        // pet_lover gives +25% pet XP
        let abilities = makeAbilities(unlockedAbilities: ["pet_lover"])
        
        XCTAssertEqual(abilities.petXpBonusTotal, 0.25, accuracy: 0.001)
    }
    
    func testPassiveBonusCalculation() {
        // passive_income gives +50% passive rewards
        let abilities = makeAbilities(unlockedAbilities: ["passive_income"])
        
        XCTAssertEqual(abilities.passiveBonusTotal, 0.50, accuracy: 0.001)
    }
    
    func testEvolutionDiscountCalculation() {
        // evolution_accelerator gives -20% evolution XP needed
        let abilities = makeAbilities(unlockedAbilities: ["evolution_accelerator"])
        
        XCTAssertEqual(abilities.evolutionDiscountTotal, 0.20, accuracy: 0.001)
    }
    
    func testLootLuckBonusCalculation() {
        // loot_luck gives +15% rare loot chance
        let abilities = makeAbilities(unlockedAbilities: ["loot_luck"])
        
        XCTAssertEqual(abilities.lootLuckBonusTotal, 0.15, accuracy: 0.001)
    }
    
    func testMaxBonusesWithAllAbilities() {
        // Unlock all abilities
        let allAbilityIds: Set<String> = [
            "rp_1", "rp_2", "xp_1", "xp_2", "coin_1", "coin_2",
            "lucky_runner", "pet_lover", "sprint_master", "loot_luck",
            "passive_income", "evolution_accelerator", "treasure_hunter", "champion"
        ]
        let abilities = makeAbilities(unlockedAbilities: allAbilityIds)
        
        // RP: 5 + 10 + 15 (sprint) + 25 (all) = 55%
        XCTAssertEqual(abilities.rpBonusTotal, 0.55, accuracy: 0.001)
        
        // XP: 5 + 10 + 15 (sprint) + 25 (all) = 55%
        XCTAssertEqual(abilities.xpBonusTotal, 0.55, accuracy: 0.001)
        
        // Coins: 5 + 10 + 15 (sprint) + 25 (all) + 25 (treasure) = 80%
        XCTAssertEqual(abilities.coinBonusTotal, 0.80, accuracy: 0.001)
    }
    
    func testBonusIgnoresUnknownAbilities() {
        let abilities = makeAbilities(unlockedAbilities: ["unknown_ability", "fake_node"])
        
        XCTAssertEqual(abilities.rpBonusTotal, 0.0)
        XCTAssertEqual(abilities.xpBonusTotal, 0.0)
        XCTAssertEqual(abilities.coinBonusTotal, 0.0)
    }
    
    // MARK: - Ability Tree Data Tests
    
    func testNodeLookupFindsExistingNode() {
        let node = AbilityTreeData.node(byId: "rp_1")
        
        XCTAssertNotNil(node)
        XCTAssertEqual(node?.name, "RP Boost I")
    }
    
    func testNodeLookupReturnsNilForUnknown() {
        let node = AbilityTreeData.node(byId: "nonexistent_node")
        
        XCTAssertNil(node)
    }
    
    func testNodesByTierReturnsCorrectNodes() {
        let tier1Nodes = AbilityTreeData.nodesByTier(1)
        
        XCTAssertEqual(tier1Nodes.count, 3)
        XCTAssertTrue(tier1Nodes.allSatisfy { $0.tier == 1 })
    }
    
    func testNodesByTierReturnsEmptyForInvalidTier() {
        let tier99Nodes = AbilityTreeData.nodesByTier(99)
        
        XCTAssertTrue(tier99Nodes.isEmpty)
    }
    
    func testAllNodesHaveUniqueIds() {
        let allIds = AbilityTreeData.playerNodes.map { $0.id }
        let uniqueIds = Set(allIds)
        
        XCTAssertEqual(allIds.count, uniqueIds.count, "All node IDs should be unique")
    }
    
    func testTier1NodesHaveNoPrerequisites() {
        let tier1Nodes = AbilityTreeData.nodesByTier(1)
        
        for node in tier1Nodes {
            XCTAssertTrue(node.prerequisites.isEmpty,
                         "Tier 1 node \(node.id) should have no prerequisites")
        }
    }
    
    func testAllPrerequisitesExist() {
        for node in AbilityTreeData.playerNodes {
            for prereq in node.prerequisites {
                let prereqNode = AbilityTreeData.node(byId: prereq)
                XCTAssertNotNil(prereqNode,
                               "Prerequisite \(prereq) for \(node.id) should exist")
            }
        }
    }
    
    func testPrerequisitesHaveLowerTier() {
        for node in AbilityTreeData.playerNodes {
            for prereq in node.prerequisites {
                if let prereqNode = AbilityTreeData.node(byId: prereq) {
                    XCTAssertLessThan(prereqNode.tier, node.tier,
                                     "Prereq \(prereq) should have lower tier than \(node.id)")
                }
            }
        }
    }
    
    func testNodeCostsMatchTier() {
        for node in AbilityTreeData.playerNodes {
            XCTAssertEqual(node.cost, node.tier,
                          "Node \(node.id) cost should match its tier")
        }
    }
    
    func testEdgesMatchPrerequisites() {
        let edges = AbilityTreeData.edges
        
        for node in AbilityTreeData.playerNodes {
            for prereq in node.prerequisites {
                let hasEdge = edges.contains { $0.from == prereq && $0.to == node.id }
                XCTAssertTrue(hasEdge, "Edge should exist from \(prereq) to \(node.id)")
            }
        }
    }
    
    // MARK: - Ability Effect Tests
    
    func testAbilityEffectValueExtraction() {
        XCTAssertEqual(AbilityEffect.rpBonus(0.10).value, 0.10, accuracy: 0.001)
        XCTAssertEqual(AbilityEffect.xpBonus(0.15).value, 0.15, accuracy: 0.001)
        XCTAssertEqual(AbilityEffect.coinBonus(0.20).value, 0.20, accuracy: 0.001)
        XCTAssertEqual(AbilityEffect.catchRateBonus(0.05).value, 0.05, accuracy: 0.001)
        XCTAssertEqual(AbilityEffect.allBonus(0.25).value, 0.25, accuracy: 0.001)
    }
    
    func testAbilityEffectDescriptionFormatting() {
        XCTAssertEqual(AbilityEffect.rpBonus(0.05).description, "+5% RP")
        XCTAssertEqual(AbilityEffect.xpBonus(0.10).description, "+10% XP")
        XCTAssertEqual(AbilityEffect.coinBonus(0.25).description, "+25% Coins")
        XCTAssertEqual(AbilityEffect.evolutionDiscount(0.20).description, "-20% Evolution XP")
    }
    
    // MARK: - AbilityConfig Tests
    
    func testMaxPetAbilityLevel() {
        XCTAssertEqual(config.maxPetAbilityLevel, 5)
    }
    
    func testUpgradeCostsAreProgressive() {
        var previousCost = 0
        for level in 2...5 {
            let cost = config.upgradeCost(toLevel: level)
            XCTAssertGreaterThan(cost, previousCost,
                                "Cost for level \(level) should be > cost for level \(level - 1)")
            previousCost = cost
        }
    }
    
    func testUpgradeCostForInvalidLevel() {
        XCTAssertEqual(config.upgradeCost(toLevel: 1), 0)  // Level 1 is free
        XCTAssertEqual(config.upgradeCost(toLevel: 6), 0)  // Above max
        XCTAssertEqual(config.upgradeCost(toLevel: 0), 0)  // Invalid
    }
    
    func testAbilityMultiplierProgression() {
        XCTAssertEqual(config.abilityMultiplier(forLevel: 1), 1.00, accuracy: 0.01)
        XCTAssertEqual(config.abilityMultiplier(forLevel: 2), 1.25, accuracy: 0.01)
        XCTAssertEqual(config.abilityMultiplier(forLevel: 3), 1.50, accuracy: 0.01)
        XCTAssertEqual(config.abilityMultiplier(forLevel: 4), 1.75, accuracy: 0.01)
        XCTAssertEqual(config.abilityMultiplier(forLevel: 5), 2.00, accuracy: 0.01)
    }
    
    func testAbilityMultiplierForInvalidLevel() {
        XCTAssertEqual(config.abilityMultiplier(forLevel: 0), 1.00)
        XCTAssertEqual(config.abilityMultiplier(forLevel: 6), 1.00)
        XCTAssertEqual(config.abilityMultiplier(forLevel: -1), 1.00)
    }
    
    func testPPEvolutionStages() {
        XCTAssertEqual(config.ppEvolutionStages, [3, 6, 9, 10])
        XCTAssertEqual(config.ppEvolutionStages.count, 4)
    }
    
    // MARK: - Integration Tests (Prerequisite Chains)
    
    func testUnlockChainRPPath() {
        var abilities = makeAbilities(abilityPoints: 20)
        
        // Tier 1: rp_1 (cost 1)
        let rp1 = AbilityTreeData.node(byId: "rp_1")!
        XCTAssertTrue(abilities.unlock(rp1))
        XCTAssertEqual(abilities.abilityPoints, 19)
        
        // Tier 2: rp_2 (cost 2, requires rp_1)
        let rp2 = AbilityTreeData.node(byId: "rp_2")!
        XCTAssertTrue(abilities.unlock(rp2))
        XCTAssertEqual(abilities.abilityPoints, 17)
        
        // Tier 3: lucky_runner (cost 3, requires rp_2)
        let luckyRunner = AbilityTreeData.node(byId: "lucky_runner")!
        XCTAssertTrue(abilities.unlock(luckyRunner))
        XCTAssertEqual(abilities.abilityPoints, 14)
    }
    
    func testCannotSkipPrerequisites() {
        var abilities = makeAbilities(abilityPoints: 20)
        
        // Try to unlock rp_2 without rp_1
        let rp2 = AbilityTreeData.node(byId: "rp_2")!
        XCTAssertFalse(abilities.canUnlock(rp2))
        XCTAssertFalse(abilities.unlock(rp2))
    }
    
    func testSprintMasterRequiresThreePrereqs() {
        let sprintMaster = AbilityTreeData.node(byId: "sprint_master")!
        
        XCTAssertEqual(sprintMaster.prerequisites.count, 3)
        XCTAssertTrue(sprintMaster.prerequisites.contains("rp_2"))
        XCTAssertTrue(sprintMaster.prerequisites.contains("xp_2"))
        XCTAssertTrue(sprintMaster.prerequisites.contains("coin_2"))
    }
    
    func testChampionRequiresTwoTier4Prereqs() {
        let champion = AbilityTreeData.node(byId: "champion")!
        
        XCTAssertEqual(champion.prerequisites.count, 2)
        XCTAssertTrue(champion.prerequisites.contains("passive_income"))
        XCTAssertTrue(champion.prerequisites.contains("evolution_accelerator"))
    }
    
    func testFullTreeUnlockCostCalculation() {
        // Calculate total AP needed to unlock all abilities
        let totalCost = AbilityTreeData.playerNodes.reduce(0) { $0 + $1.cost }
        
        // Tier 1: 3 nodes * 1 = 3
        // Tier 2: 3 nodes * 2 = 6
        // Tier 3: 4 nodes * 3 = 12
        // Tier 4: 3 nodes * 4 = 12
        // Tier 5: 1 node * 5 = 5
        // Total = 38
        XCTAssertEqual(totalCost, 38)
    }
    
    // MARK: - Edge Cases
    
    func testUnlockWithZeroAP() {
        var abilities = makeAbilities(abilityPoints: 0)
        let node = makeNode(cost: 1)
        
        XCTAssertFalse(abilities.canUnlock(node))
        XCTAssertFalse(abilities.unlock(node))
    }
    
    func testUpgradePetAbilityWithZeroPP() {
        var abilities = makeAbilities(petPoints: 0)
        
        XCTAssertFalse(abilities.canUpgradePetAbility(petId: "any"))
        XCTAssertFalse(abilities.upgradePetAbility(petId: "any"))
    }
    
    func testUpgradePetAbilityFromMaxMinusOne() {
        // Level 4 -> 5 costs 5 PP
        var abilities = makeAbilities(petPoints: 5, petAbilityLevels: ["pet": 4])
        
        XCTAssertTrue(abilities.canUpgradePetAbility(petId: "pet"))
        XCTAssertTrue(abilities.upgradePetAbility(petId: "pet"))
        XCTAssertEqual(abilities.getPetAbilityLevel(for: "pet"), 5)
        XCTAssertEqual(abilities.petPoints, 0)
    }
    
    func testUpgradePetAbilityInsufficientForMaxLevel() {
        // Level 4 -> 5 costs 5 PP, but we only have 4
        var abilities = makeAbilities(petPoints: 4, petAbilityLevels: ["pet": 4])
        
        XCTAssertFalse(abilities.canUpgradePetAbility(petId: "pet"))
        XCTAssertFalse(abilities.upgradePetAbility(petId: "pet"))
    }
    
    func testMultiplePetsIndependentLevels() {
        var abilities = makeAbilities(petPoints: 20)
        
        _ = abilities.upgradePetAbility(petId: "pet_A")
        _ = abilities.upgradePetAbility(petId: "pet_A")
        _ = abilities.upgradePetAbility(petId: "pet_B")
        
        XCTAssertEqual(abilities.getPetAbilityLevel(for: "pet_A"), 3)
        XCTAssertEqual(abilities.getPetAbilityLevel(for: "pet_B"), 2)
        XCTAssertEqual(abilities.getPetAbilityLevel(for: "pet_C"), 1)  // Never upgraded
    }
    
    func testBonusWithMixedValidAndInvalidAbilities() {
        let abilities = makeAbilities(unlockedAbilities: ["rp_1", "fake_ability", "xp_1"])
        
        XCTAssertEqual(abilities.rpBonusTotal, 0.05, accuracy: 0.001)
        XCTAssertEqual(abilities.xpBonusTotal, 0.05, accuracy: 0.001)
    }
    
    func testEmptyUnlockedAbilitiesSet() {
        let abilities = makeAbilities(unlockedAbilities: [])
        
        XCTAssertEqual(abilities.rpBonusTotal, 0.0)
        XCTAssertEqual(abilities.xpBonusTotal, 0.0)
        XCTAssertEqual(abilities.coinBonusTotal, 0.0)
        XCTAssertEqual(abilities.catchRateBonusTotal, 0.0)
        XCTAssertEqual(abilities.petXpBonusTotal, 0.0)
        XCTAssertEqual(abilities.passiveBonusTotal, 0.0)
        XCTAssertEqual(abilities.evolutionDiscountTotal, 0.0)
        XCTAssertEqual(abilities.lootLuckBonusTotal, 0.0)
    }
    
    // MARK: - Status Types Tests
    
    func testAbilityUnlockStatusCanUnlock() {
        let status = AbilityUnlockStatus(canUnlock: true, reason: nil)
        
        XCTAssertTrue(status.canUnlock)
        XCTAssertNil(status.reason)
    }
    
    func testAbilityUnlockStatusCannotUnlock() {
        let status = AbilityUnlockStatus(canUnlock: false, reason: "Not enough AP")
        
        XCTAssertFalse(status.canUnlock)
        XCTAssertEqual(status.reason, "Not enough AP")
    }
    
    func testPetAbilityUpgradeStatusDefaults() {
        let status = PetAbilityUpgradeStatus(canUpgrade: false, reason: "Test")
        
        XCTAssertEqual(status.currentLevel, 1)
        XCTAssertEqual(status.nextLevel, 2)
        XCTAssertEqual(status.cost, 0)
    }
    
    func testPetAbilityUpgradeStatusCustomValues() {
        let status = PetAbilityUpgradeStatus(
            canUpgrade: true,
            reason: nil,
            currentLevel: 3,
            nextLevel: 4,
            cost: 4
        )
        
        XCTAssertTrue(status.canUpgrade)
        XCTAssertEqual(status.currentLevel, 3)
        XCTAssertEqual(status.nextLevel, 4)
        XCTAssertEqual(status.cost, 4)
    }
    
    // MARK: - Data Integrity Tests
    
    func testAllNodesHaveValidIconNames() {
        for node in AbilityTreeData.playerNodes {
            XCTAssertFalse(node.iconName.isEmpty,
                          "Node \(node.id) should have an icon name")
        }
    }
    
    func testAllNodesHaveDescriptions() {
        for node in AbilityTreeData.playerNodes {
            XCTAssertFalse(node.description.isEmpty,
                          "Node \(node.id) should have a description")
        }
    }
    
    func testAllNodesHaveValidTreeCoordinates() {
        for node in AbilityTreeData.playerNodes {
            XCTAssertGreaterThanOrEqual(node.treeX, 0.0)
            XCTAssertLessThanOrEqual(node.treeX, 1.0)
            XCTAssertGreaterThanOrEqual(node.treeY, 0.0)
            XCTAssertLessThanOrEqual(node.treeY, 1.0)
        }
    }
    
    func testTierCountsMatchExpected() {
        XCTAssertEqual(AbilityTreeData.nodesByTier(1).count, 3)
        XCTAssertEqual(AbilityTreeData.nodesByTier(2).count, 3)
        XCTAssertEqual(AbilityTreeData.nodesByTier(3).count, 4)
        XCTAssertEqual(AbilityTreeData.nodesByTier(4).count, 3)
        XCTAssertEqual(AbilityTreeData.nodesByTier(5).count, 1)
    }
    
    func testTotalNodeCount() {
        XCTAssertEqual(AbilityTreeData.playerNodes.count, 14)
    }
}
