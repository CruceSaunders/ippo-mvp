import Foundation

@MainActor
final class PetSystem: ObservableObject {
    static let shared = PetSystem()
    
    private let config = PetConfig.shared
    
    private init() {}
    
    // MARK: - Feeding
    func feedPet(_ petId: String) -> FeedResult {
        let userData = UserData.shared
        
        guard let index = userData.ownedPets.firstIndex(where: { $0.id == petId }) else {
            return FeedResult(success: false, message: "Pet not found")
        }
        
        var pet = userData.ownedPets[index]
        
        // Check daily limit
        if let lastFed = pet.lastFedDate, Calendar.current.isDateInToday(lastFed) {
            if pet.feedingsToday >= config.maxFeedingsPerDay {
                return FeedResult(
                    success: false,
                    message: "Already fed \(config.maxFeedingsPerDay) times today"
                )
            }
        } else {
            // New day
            pet.feedingsToday = 0
        }
        
        // Calculate XP gain
        var xpGain = config.xpPerFeeding
        
        // Frost's Preserve ability: +50% feeding XP
        if let equippedDef = userData.equippedPet?.definition, equippedDef.id == "pet_08" {
            let effectiveness = userData.equippedPet?.abilityEffectiveness ?? 1.0
            xpGain = Int(Double(xpGain) * (1.0 + 0.50 * effectiveness))
        }
        
        // Sprout's Growth ability: +20% evolution XP
        if let equippedDef = userData.equippedPet?.definition, equippedDef.id == "pet_03" {
            let effectiveness = userData.equippedPet?.abilityEffectiveness ?? 1.0
            xpGain = Int(Double(xpGain) * (1.0 + 0.20 * effectiveness))
        }
        
        // Apply feeding
        let previousStage = pet.evolutionStage
        pet.experience += xpGain
        pet.mood = min(config.maxMood, pet.mood + config.moodBoostPerFeeding)
        pet.lastFedDate = Date()
        pet.feedingsToday += 1
        
        // Check evolution
        let newStage = config.currentStage(forXP: pet.experience)
        var didEvolve = false
        
        if newStage > pet.evolutionStage {
            pet.evolutionStage = newStage
            didEvolve = true
            
            // Award PP at stages 3, 6, 9, 10
            if AbilityConfig.shared.ppEvolutionStages.contains(newStage) {
                userData.abilities.petPoints += 1
            }
        }
        
        userData.ownedPets[index] = pet
        userData.save()
        
        return FeedResult(
            success: true,
            message: didEvolve ? "Fed and evolved!" : "Fed successfully",
            xpGained: xpGain,
            moodGained: config.moodBoostPerFeeding,
            feedingsRemaining: config.maxFeedingsPerDay - pet.feedingsToday,
            didEvolve: didEvolve,
            newStage: didEvolve ? newStage : nil,
            previousStage: previousStage
        )
    }
    
    // MARK: - Mood Decay
    func applyMoodDecay() {
        let userData = UserData.shared
        let today = Calendar.current.startOfDay(for: Date())
        
        for i in userData.ownedPets.indices {
            var pet = userData.ownedPets[i]
            
            if let lastFed = pet.lastFedDate {
                let lastFedDay = Calendar.current.startOfDay(for: lastFed)
                let daysSince = Calendar.current.dateComponents([.day], from: lastFedDay, to: today).day ?? 0
                
                if daysSince > 0 {
                    // Apply decay based on days since feeding
                    var decay = daysSince * config.moodDecayPerDay
                    
                    // Pebble's Fortitude: -15% mood decay
                    if pet.petDefinitionId == "pet_05" {
                        let effectiveness = pet.abilityEffectiveness
                        decay = Int(Double(decay) * (1.0 - 0.15 * effectiveness))
                    }
                    
                    pet.mood = max(config.minMood, pet.mood - decay)
                    userData.ownedPets[i] = pet
                }
            }
        }
        
        userData.save()
    }
    
    // MARK: - Evolution Check
    func checkEvolution(for petId: String) -> EvolutionStatus {
        let userData = UserData.shared
        
        guard let pet = userData.ownedPets.first(where: { $0.id == petId }) else {
            return EvolutionStatus(canEvolve: false, currentStage: 0, nextStage: 0, xpNeeded: 0, xpCurrent: 0)
        }
        
        let currentStage = pet.evolutionStage
        let nextStage = currentStage + 1
        
        guard nextStage <= config.evolutionStages else {
            return EvolutionStatus(canEvolve: false, currentStage: currentStage, nextStage: currentStage, xpNeeded: 0, xpCurrent: pet.experience, isMaxed: true)
        }
        
        let xpNeeded = config.xpNeeded(forStage: nextStage)
        let canEvolve = pet.experience >= xpNeeded
        
        return EvolutionStatus(
            canEvolve: canEvolve,
            currentStage: currentStage,
            nextStage: nextStage,
            xpNeeded: xpNeeded,
            xpCurrent: pet.experience
        )
    }
}

// MARK: - Result Types
struct FeedResult {
    let success: Bool
    let message: String
    var xpGained: Int = 0
    var moodGained: Int = 0
    var feedingsRemaining: Int = 0
    var didEvolve: Bool = false
    var newStage: Int? = nil
    var previousStage: Int = 1
}

struct EvolutionStatus {
    let canEvolve: Bool
    let currentStage: Int
    let nextStage: Int
    let xpNeeded: Int
    let xpCurrent: Int
    var isMaxed: Bool = false
    
    var progress: Double {
        guard xpNeeded > 0 else { return 1.0 }
        return min(1.0, Double(xpCurrent) / Double(xpNeeded))
    }
}
