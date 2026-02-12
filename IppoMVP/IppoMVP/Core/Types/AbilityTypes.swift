import Foundation

// MARK: - Ability Effect
enum AbilityEffect: Codable, Equatable {
    case rpBonus(Double)
    case xpBonus(Double)
    case coinBonus(Double)
    case sprintBonus(Double)
    case petXpBonus(Double)
    case catchRateBonus(Double)
    case passiveBonus(Double)
    case evolutionDiscount(Double)
    case allBonus(Double)
    case lootLuckBonus(Double)
    case moodDecayReduction(Double)
    case feedingBonus(Double)
    case encounterBonus(Double)
    case lootQualityBonus(Double)
    
    var description: String {
        switch self {
        case .rpBonus(let value): return "+\(Int(value * 100))% RP"
        case .xpBonus(let value): return "+\(Int(value * 100))% XP"
        case .coinBonus(let value): return "+\(Int(value * 100))% Coins"
        case .sprintBonus(let value): return "+\(Int(value * 100))% Sprint Rewards"
        case .petXpBonus(let value): return "+\(Int(value * 100))% Pet XP"
        case .catchRateBonus(let value): return "+\(Int(value * 100))% Catch Rate"
        case .passiveBonus(let value): return "+\(Int(value * 100))% Passive Rewards"
        case .evolutionDiscount(let value): return "-\(Int(value * 100))% Evolution XP"
        case .allBonus(let value): return "+\(Int(value * 100))% All Rewards"
        case .lootLuckBonus(let value): return "+\(Int(value * 100))% Rare Loot"
        case .moodDecayReduction(let value): return "-\(Int(value * 100))% Mood Decay"
        case .feedingBonus(let value): return "+\(Int(value * 100))% Feeding Bonus"
        case .encounterBonus(let value): return "+\(Int(value * 100))% Encounter Rate"
        case .lootQualityBonus(let value): return "+\(Int(value * 100))% Loot Quality"
        }
    }
    
    var value: Double {
        switch self {
        case .rpBonus(let v), .xpBonus(let v), .coinBonus(let v),
             .sprintBonus(let v), .petXpBonus(let v), .catchRateBonus(let v),
             .passiveBonus(let v), .evolutionDiscount(let v), .allBonus(let v),
             .lootLuckBonus(let v), .moodDecayReduction(let v), .feedingBonus(let v),
             .encounterBonus(let v), .lootQualityBonus(let v):
            return v
        }
    }
}

// MARK: - Ability Node (Player Tree)
struct AbilityNode: Codable, Equatable {
    let id: String
    let name: String
    let description: String
    let tier: Int
    let cost: Int
    let effect: AbilityEffect
    let prerequisites: [String]
    let iconName: String
    let treeX: Double
    let treeY: Double
    
    static func == (lhs: AbilityNode, rhs: AbilityNode) -> Bool {
        lhs.id == rhs.id
    }
}

extension AbilityNode: Identifiable {}

// MARK: - Pet Ability Node
struct PetAbilityNode: Codable, Equatable {
    let id: String
    let petId: String
    let name: String
    let description: String
    let tier: Int
    let cost: Int  // Pet Points
    let effect: AbilityEffect
    let prerequisites: [String]
    let iconName: String
    let treeX: Double
    let treeY: Double
    
    static func == (lhs: PetAbilityNode, rhs: PetAbilityNode) -> Bool {
        lhs.id == rhs.id
    }
}

extension PetAbilityNode: Identifiable {}

// MARK: - User Abilities
struct UserAbilities: Codable, Equatable {
    var abilityPoints: Int
    var petPoints: Int
    var unlockedPlayerAbilities: Set<String>
    var petAbilityLevels: [String: Int]  // Legacy: kept for migration
    var unlockedPetAbilities: [String: Set<String>]  // petId -> set of unlocked node IDs
    
    init(
        abilityPoints: Int = 0,
        petPoints: Int = 0,
        unlockedPlayerAbilities: Set<String> = [],
        petAbilityLevels: [String: Int] = [:],
        unlockedPetAbilities: [String: Set<String>] = [:]
    ) {
        self.abilityPoints = abilityPoints
        self.petPoints = petPoints
        self.unlockedPlayerAbilities = unlockedPlayerAbilities
        self.petAbilityLevels = petAbilityLevels
        self.unlockedPetAbilities = unlockedPetAbilities
    }
    
    // MARK: - Player Abilities
    func canUnlock(_ node: AbilityNode) -> Bool {
        guard abilityPoints >= node.cost else { return false }
        guard !unlockedPlayerAbilities.contains(node.id) else { return false }
        return node.prerequisites.allSatisfy { unlockedPlayerAbilities.contains($0) }
    }
    
    mutating func unlock(_ node: AbilityNode) -> Bool {
        guard canUnlock(node) else { return false }
        abilityPoints -= node.cost
        unlockedPlayerAbilities.insert(node.id)
        return true
    }
    
    // MARK: - Pet Abilities (Legacy level-based)
    func getPetAbilityLevel(for petId: String) -> Int {
        petAbilityLevels[petId] ?? 1
    }
    
    func canUpgradePetAbility(petId: String) -> Bool {
        let currentLevel = getPetAbilityLevel(for: petId)
        guard currentLevel < 5 else { return false }
        let cost = currentLevel + 1
        return petPoints >= cost
    }
    
    mutating func upgradePetAbility(petId: String) -> Bool {
        let currentLevel = getPetAbilityLevel(for: petId)
        guard currentLevel < 5 else { return false }
        let cost = currentLevel + 1
        guard petPoints >= cost else { return false }
        petPoints -= cost
        petAbilityLevels[petId] = currentLevel + 1
        return true
    }
    
    // MARK: - Pet Ability Tree (New tree-based)
    func unlockedPetNodeIds(for petId: String) -> Set<String> {
        unlockedPetAbilities[petId] ?? []
    }
    
    func isPetNodeUnlocked(petId: String, nodeId: String) -> Bool {
        unlockedPetAbilities[petId]?.contains(nodeId) ?? false
    }
    
    func canUnlockPetNode(petId: String, node: PetAbilityNode) -> Bool {
        guard petPoints >= node.cost else { return false }
        guard !isPetNodeUnlocked(petId: petId, nodeId: node.id) else { return false }
        let unlocked = unlockedPetNodeIds(for: petId)
        // Core nodes (tier 0) have no prerequisites
        if node.prerequisites.isEmpty { return true }
        return node.prerequisites.allSatisfy { unlocked.contains($0) }
    }
    
    mutating func unlockPetAbilityNode(petId: String, nodeId: String) -> Bool {
        guard let node = PetAbilityTreeData.node(forPet: petId, nodeId: nodeId) else { return false }
        guard canUnlockPetNode(petId: petId, node: node) else { return false }
        petPoints -= node.cost
        if unlockedPetAbilities[petId] == nil {
            unlockedPetAbilities[petId] = []
        }
        unlockedPetAbilities[petId]?.insert(nodeId)
        return true
    }
    
    func petAbilityCount(for petId: String) -> Int {
        unlockedPetAbilities[petId]?.count ?? 0
    }
}

// MARK: - Computed Bonuses
extension UserAbilities {
    var rpBonusTotal: Double {
        var bonus = 0.0
        for abilityId in unlockedPlayerAbilities {
            if let node = AbilityTreeData.playerNodes.first(where: { $0.id == abilityId }) {
                switch node.effect {
                case .rpBonus(let value): bonus += value
                case .allBonus(let value): bonus += value
                case .sprintBonus(let value): bonus += value
                default: break
                }
            }
        }
        return bonus
    }
    
    var xpBonusTotal: Double {
        var bonus = 0.0
        for abilityId in unlockedPlayerAbilities {
            if let node = AbilityTreeData.playerNodes.first(where: { $0.id == abilityId }) {
                switch node.effect {
                case .xpBonus(let value): bonus += value
                case .allBonus(let value): bonus += value
                case .sprintBonus(let value): bonus += value
                default: break
                }
            }
        }
        return bonus
    }
    
    var coinBonusTotal: Double {
        var bonus = 0.0
        for abilityId in unlockedPlayerAbilities {
            if let node = AbilityTreeData.playerNodes.first(where: { $0.id == abilityId }) {
                switch node.effect {
                case .coinBonus(let value): bonus += value
                case .allBonus(let value): bonus += value
                case .sprintBonus(let value): bonus += value
                default: break
                }
            }
        }
        return bonus
    }
    
    var petXpBonusTotal: Double {
        var bonus = 0.0
        for abilityId in unlockedPlayerAbilities {
            if let node = AbilityTreeData.playerNodes.first(where: { $0.id == abilityId }) {
                if case .petXpBonus(let value) = node.effect {
                    bonus += value
                }
            }
        }
        return bonus
    }
    
    var catchRateBonusTotal: Double {
        var bonus = 0.0
        for abilityId in unlockedPlayerAbilities {
            if let node = AbilityTreeData.playerNodes.first(where: { $0.id == abilityId }) {
                if case .catchRateBonus(let value) = node.effect {
                    bonus += value
                }
            }
        }
        return bonus
    }
    
    var passiveBonusTotal: Double {
        var bonus = 0.0
        for abilityId in unlockedPlayerAbilities {
            if let node = AbilityTreeData.playerNodes.first(where: { $0.id == abilityId }) {
                if case .passiveBonus(let value) = node.effect {
                    bonus += value
                }
            }
        }
        return bonus
    }
    
    var evolutionDiscountTotal: Double {
        var discount = 0.0
        for abilityId in unlockedPlayerAbilities {
            if let node = AbilityTreeData.playerNodes.first(where: { $0.id == abilityId }) {
                if case .evolutionDiscount(let value) = node.effect {
                    discount += value
                }
            }
        }
        return discount
    }
    
    var lootLuckBonusTotal: Double {
        var bonus = 0.0
        for abilityId in unlockedPlayerAbilities {
            if let node = AbilityTreeData.playerNodes.first(where: { $0.id == abilityId }) {
                if case .lootLuckBonus(let value) = node.effect {
                    bonus += value
                }
            }
        }
        return bonus
    }
}
