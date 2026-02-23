import Foundation

struct AbilityConfig: Sendable {
    static let shared = AbilityConfig()
    
    // MARK: - Player Ability Points
    let apPerLevel: Int = 1
    let apForFirstPet: Int = 1
    
    // MARK: - Pet Points
    // Earned at evolution stages 3, 6, 9, 10
    let ppEvolutionStages: [Int] = [3, 6, 9, 10]
    let ppPerMilestone: Int = 1  // 1 PP per 50km total
    let milestoneDistanceKm: Double = 50
    
    // MARK: - Pet Ability Upgrade Costs
    // Level 1 is free (base), 2-5 cost increasing PP
    let petAbilityUpgradeCosts: [Int: Int] = [
        2: 2,  // Level 2 costs 2 PP
        3: 3,  // Level 3 costs 3 PP
        4: 4,  // Level 4 costs 4 PP
        5: 5   // Level 5 costs 5 PP
    ]
    
    // MARK: - Pet Ability Multipliers
    // Level 1: 100%, Level 2: 125%, etc.
    func abilityMultiplier(forLevel level: Int) -> Double {
        switch level {
        case 1: return 1.00
        case 2: return 1.25
        case 3: return 1.50
        case 4: return 1.75
        case 5: return 2.00
        default: return 1.00
        }
    }
    
    // MARK: - Max Levels
    let maxPetAbilityLevel: Int = 5
    
    // MARK: - Helpers
    func upgradeCost(toLevel level: Int) -> Int {
        petAbilityUpgradeCosts[level] ?? 0
    }
}
