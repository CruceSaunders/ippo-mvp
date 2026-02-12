import Foundation

struct PetConfig: Sendable {
    static let shared = PetConfig()
    
    // MARK: - Catch Rates (by pets owned)
    let catchRates: [Int: Double] = [
        0: 1.00,   // First pet: 100% guaranteed
        1: 0.15,   // Second pet: 15% per sprint (~5 runs)
        2: 0.08,   // Third pet: 8% per sprint (~10 runs)
        // 3+: defaultCatchRate
    ]
    let defaultCatchRate: Double = 0.03  // ~20 runs average for 4th+ pet
    
    // MARK: - Evolution
    let evolutionStages: Int = 10
    let xpPerEvolution: [Int] = [0, 100, 250, 500, 1000, 2000, 4000, 7000, 12000, 20000]
    
    // MARK: - Evolution Stage Names
    let stageNames: [String] = [
        "Newborn", "Infant", "Toddler", "Child", "Youth",
        "Adolescent", "Young Adult", "Adult", "Mature", "Elder"
    ]
    
    // MARK: - Feeding
    let maxFeedingsPerDay: Int = 3
    let xpPerFeeding: Int = 25
    let moodBoostPerFeeding: Int = 1
    
    // MARK: - Mood
    let maxMood: Int = 10
    let minMood: Int = 1
    let moodDecayPerDay: Int = 1  // Loses 1 mood per day without feeding
    
    // MARK: - XP Sources
    let xpPerMinuteRunning: Int = 10
    let xpPerCompletedSprint: Int = 50
    
    // MARK: - Ability Effectiveness by Stage
    func abilityEffectiveness(forStage stage: Int) -> Double {
        switch stage {
        case 1...3: return 0.50
        case 4...6: return 0.75
        case 7...9: return 1.00
        case 10: return 1.25
        default: return 1.00
        }
    }
    
    // MARK: - Helpers
    func catchRate(forPetsOwned count: Int) -> Double {
        catchRates[count] ?? defaultCatchRate
    }
    
    func shouldCatchPet(petsOwned: Int, bonusCatchRate: Double = 0) -> Bool {
        let baseRate = catchRate(forPetsOwned: petsOwned)
        let totalRate = min(1.0, baseRate + bonusCatchRate)
        return Double.random(in: 0...1) < totalRate
    }
    
    func xpNeeded(forStage stage: Int) -> Int {
        guard stage >= 1 && stage <= evolutionStages else { return Int.max }
        return xpPerEvolution[safe: stage] ?? Int.max
    }
    
    func currentStage(forXP xp: Int) -> Int {
        for (index, requiredXP) in xpPerEvolution.enumerated().reversed() {
            if xp >= requiredXP {
                return index + 1
            }
        }
        return 1
    }
}
