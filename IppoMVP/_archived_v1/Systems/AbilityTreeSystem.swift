import Foundation

@MainActor
final class AbilityTreeSystem: ObservableObject {
    static let shared = AbilityTreeSystem()
    
    private init() {}
    
    // MARK: - Player Abilities
    func canUnlockAbility(_ nodeId: String) -> AbilityUnlockStatus {
        let userData = UserData.shared
        
        guard let node = AbilityTreeData.node(byId: nodeId) else {
            return AbilityUnlockStatus(canUnlock: false, reason: "Ability not found")
        }
        
        // Already unlocked?
        if userData.abilities.unlockedPlayerAbilities.contains(nodeId) {
            return AbilityUnlockStatus(canUnlock: false, reason: "Already unlocked")
        }
        
        // Check prerequisites
        for prereq in node.prerequisites {
            if !userData.abilities.unlockedPlayerAbilities.contains(prereq) {
                let prereqNode = AbilityTreeData.node(byId: prereq)
                return AbilityUnlockStatus(
                    canUnlock: false,
                    reason: "Requires \(prereqNode?.name ?? prereq)"
                )
            }
        }
        
        // Check AP
        if userData.abilities.abilityPoints < node.cost {
            return AbilityUnlockStatus(
                canUnlock: false,
                reason: "Need \(node.cost) AP (have \(userData.abilities.abilityPoints))"
            )
        }
        
        return AbilityUnlockStatus(canUnlock: true, reason: nil)
    }
    
    func unlockAbility(_ nodeId: String) -> Bool {
        let status = canUnlockAbility(nodeId)
        guard status.canUnlock else { return false }
        
        guard let node = AbilityTreeData.node(byId: nodeId) else { return false }
        
        let userData = UserData.shared
        userData.abilities.abilityPoints -= node.cost
        userData.abilities.unlockedPlayerAbilities.insert(nodeId)
        userData.save()
        
        return true
    }
    
    // MARK: - Pet Abilities
    func canUpgradePetAbility(_ petId: String) -> PetAbilityUpgradeStatus {
        let userData = UserData.shared
        
        guard let pet = userData.ownedPets.first(where: { $0.id == petId }) else {
            return PetAbilityUpgradeStatus(canUpgrade: false, reason: "Pet not found")
        }
        
        let currentLevel = userData.abilities.getPetAbilityLevel(for: petId)
        
        if currentLevel >= AbilityConfig.shared.maxPetAbilityLevel {
            return PetAbilityUpgradeStatus(canUpgrade: false, reason: "Already at max level", currentLevel: currentLevel)
        }
        
        let nextLevel = currentLevel + 1
        let cost = AbilityConfig.shared.upgradeCost(toLevel: nextLevel)
        
        if userData.abilities.petPoints < cost {
            return PetAbilityUpgradeStatus(
                canUpgrade: false,
                reason: "Need \(cost) PP (have \(userData.abilities.petPoints))",
                currentLevel: currentLevel,
                nextLevel: nextLevel,
                cost: cost
            )
        }
        
        return PetAbilityUpgradeStatus(
            canUpgrade: true,
            reason: nil,
            currentLevel: currentLevel,
            nextLevel: nextLevel,
            cost: cost
        )
    }
    
    func upgradePetAbility(_ petId: String) -> Bool {
        let status = canUpgradePetAbility(petId)
        guard status.canUpgrade else { return false }
        
        return UserData.shared.upgradePetAbility(petId)
    }
    
    // MARK: - Calculated Bonuses
    var totalRPBonus: Double {
        UserData.shared.abilities.rpBonusTotal
    }
    
    var totalXPBonus: Double {
        UserData.shared.abilities.xpBonusTotal
    }
    
    var totalCoinBonus: Double {
        UserData.shared.abilities.coinBonusTotal
    }
    
    var totalCatchRateBonus: Double {
        UserData.shared.abilities.catchRateBonusTotal
    }
    
    // MARK: - Tree Visualization Data
    var unlockedNodes: Set<String> {
        UserData.shared.abilities.unlockedPlayerAbilities
    }
    
    var availableNodes: [AbilityNode] {
        AbilityTreeData.playerNodes.filter { node in
            !unlockedNodes.contains(node.id) &&
            node.prerequisites.allSatisfy { unlockedNodes.contains($0) }
        }
    }
    
    var lockedNodes: [AbilityNode] {
        AbilityTreeData.playerNodes.filter { node in
            !unlockedNodes.contains(node.id) &&
            !node.prerequisites.allSatisfy { unlockedNodes.contains($0) }
        }
    }
}

// MARK: - Status Types
struct AbilityUnlockStatus {
    let canUnlock: Bool
    let reason: String?
}

struct PetAbilityUpgradeStatus {
    let canUpgrade: Bool
    let reason: String?
    var currentLevel: Int = 1
    var nextLevel: Int = 2
    var cost: Int = 0
}
