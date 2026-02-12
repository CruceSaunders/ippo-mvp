import Foundation

@MainActor
final class RewardsSystem: ObservableObject {
    static let shared = RewardsSystem()
    
    private let config = RewardsConfig.shared
    
    private init() {}
    
    // MARK: - Calculate Sprint Rewards
    func calculateSprintRewards(result: SprintResult) -> SprintRewards {
        guard result.isValid else { return .empty }
        
        let userData = UserData.shared
        let base = config.baseSprintRewards()
        let rank = userData.profile.rank
        
        // Calculate bonuses from ability tree
        var rpBonus = userData.abilities.rpBonusTotal
        var xpBonus = userData.abilities.xpBonusTotal
        var coinBonus = userData.abilities.coinBonusTotal
        
        // Add rank boosts
        rpBonus += rank.rpBoost
        xpBonus += rank.xpBoost
        coinBonus += rank.coinBoost
        
        // Pet ability bonuses
        if let pet = userData.equippedPet, let def = pet.definition {
            let effectiveness = pet.abilityEffectiveness
            
            switch def.id {
            case "pet_01":  // Ember: short sprints
                if result.duration < 35 { rpBonus += 0.15 * effectiveness }
            case "pet_09":  // Blaze: long sprints
                if result.duration > 40 { rpBonus += 0.30 * effectiveness }
            default:
                break
            }
        }
        
        // Apply bonuses
        let finalRewards = config.applyBonuses(
            base: base,
            rpBonus: rpBonus,
            xpBonus: xpBonus,
            coinBonus: coinBonus,
            streakDays: userData.profile.currentStreak
        )
        
        // Roll for loot box (with loot luck bonus)
        let lootLuck = userData.abilities.lootLuckBonusTotal
        let lootBox = EncounterConfig.shared.rollLootBoxRarity(luckBonus: lootLuck)
        
        return SprintRewards(
            rp: finalRewards.rp,
            xp: finalRewards.xp,
            coins: finalRewards.coins,
            lootBox: lootBox
        )
    }
    
    // MARK: - Passive Rewards
    func calculatePassiveRewards(minutes: Int) -> (rp: Int, xp: Int) {
        let userData = UserData.shared
        let passiveBonus = userData.abilities.passiveBonusTotal
        let rank = userData.profile.rank
        
        // Splash's Flow: +10% passive XP
        var xpBonus = rank.xpBoost
        if let pet = userData.equippedPet, pet.petDefinitionId == "pet_02" {
            xpBonus += 0.10 * pet.abilityEffectiveness
        }
        
        let rpBonus = rank.rpBoost
        
        var totalRP = 0
        var totalXP = 0
        
        for _ in 0..<minutes {
            let baseRP = Int.random(in: config.rpPerMinute)
            let baseXP = Int.random(in: config.xpPerMinute)
            
            totalRP += Int(Double(baseRP) * (1.0 + passiveBonus + rpBonus))
            totalXP += Int(Double(baseXP) * (1.0 + passiveBonus + xpBonus))
        }
        
        return (totalRP, totalXP)
    }
    
    // MARK: - Pet Catch Rewards
    func getPetCatchRewards() -> (coins: Int, rp: Int, xp: Int) {
        let rank = UserData.shared.profile.rank
        return (
            Int(Double(config.bonusCoinsForPetCatch) * (1.0 + rank.coinBoost)),
            Int(Double(config.bonusRPForPetCatch) * (1.0 + rank.rpBoost)),
            Int(Double(config.bonusXPForPetCatch) * (1.0 + rank.xpBoost))
        )
    }
    
    // MARK: - Apply All Rewards
    func applyRewards(_ rewards: SprintRewards) {
        let userData = UserData.shared
        
        userData.addRP(rewards.rp)
        userData.addXP(rewards.xp)
        userData.addCoins(rewards.coins)
        
        if let rarity = rewards.lootBox {
            userData.addLootBox(rarity)
        }
        
        // Pet XP
        if let petId = userData.equippedPet?.id {
            userData.addPetXP(petId, xp: PetConfig.shared.xpPerCompletedSprint)
        }
    }
}
