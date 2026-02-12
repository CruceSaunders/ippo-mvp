import XCTest
@testable import IppoMVP

final class PetSystemTests: XCTestCase {
    
    // MARK: - Test Helpers (Pure Logic Extraction)
    
    /// Testable version of feeding logic without UserData dependency
    struct TestablePetFeeder {
        let config = PetConfig.shared
        
        func feed(
            pet: inout OwnedPet,
            equippedPet: OwnedPet?,
            currentDate: Date = Date()
        ) -> FeedResult {
            // Check daily limit
            if let lastFed = pet.lastFedDate, Calendar.current.isDateInToday(lastFed) {
                if pet.feedingsToday >= config.maxFeedingsPerDay {
                    return FeedResult(
                        success: false,
                        message: "Already fed \(config.maxFeedingsPerDay) times today"
                    )
                }
            } else {
                pet.feedingsToday = 0
            }
            
            // Calculate XP gain
            var xpGain = config.xpPerFeeding
            
            // Frost's Preserve ability: +50% feeding XP
            if let equippedDef = equippedPet?.definition, equippedDef.id == "pet_08" {
                let effectiveness = equippedPet?.abilityEffectiveness ?? 1.0
                xpGain = Int(Double(xpGain) * (1.0 + 0.50 * effectiveness))
            }
            
            // Sprout's Growth ability: +20% evolution XP
            if let equippedDef = equippedPet?.definition, equippedDef.id == "pet_03" {
                let effectiveness = equippedPet?.abilityEffectiveness ?? 1.0
                xpGain = Int(Double(xpGain) * (1.0 + 0.20 * effectiveness))
            }
            
            let previousStage = pet.evolutionStage
            pet.experience += xpGain
            pet.mood = min(config.maxMood, pet.mood + config.moodBoostPerFeeding)
            pet.lastFedDate = currentDate
            pet.feedingsToday += 1
            
            let newStage = config.currentStage(forXP: pet.experience)
            var didEvolve = false
            var ppAwarded = false
            
            if newStage > pet.evolutionStage {
                pet.evolutionStage = newStage
                didEvolve = true
                ppAwarded = AbilityConfig.shared.ppEvolutionStages.contains(newStage)
            }
            
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
    }
    
    /// Testable version of mood decay logic
    struct TestableMoodDecay {
        let config = PetConfig.shared
        
        func applyDecay(to pet: inout OwnedPet, currentDate: Date = Date()) {
            let today = Calendar.current.startOfDay(for: currentDate)
            
            if let lastFed = pet.lastFedDate {
                let lastFedDay = Calendar.current.startOfDay(for: lastFed)
                let daysSince = Calendar.current.dateComponents([.day], from: lastFedDay, to: today).day ?? 0
                
                if daysSince > 0 {
                    var decay = daysSince * config.moodDecayPerDay
                    
                    // Pebble's Fortitude: -15% mood decay
                    if pet.petDefinitionId == "pet_05" {
                        let effectiveness = pet.abilityEffectiveness
                        decay = Int(Double(decay) * (1.0 - 0.15 * effectiveness))
                    }
                    
                    pet.mood = max(config.minMood, pet.mood - decay)
                }
            }
        }
    }
    
    /// Testable evolution checker
    struct TestableEvolutionChecker {
        let config = PetConfig.shared
        
        func checkEvolution(for pet: OwnedPet) -> EvolutionStatus {
            let currentStage = pet.evolutionStage
            let nextStage = currentStage + 1
            
            guard nextStage <= config.evolutionStages else {
                return EvolutionStatus(
                    canEvolve: false,
                    currentStage: currentStage,
                    nextStage: currentStage,
                    xpNeeded: 0,
                    xpCurrent: pet.experience,
                    isMaxed: true
                )
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
    
    // MARK: - Test Fixtures
    
    private func makePet(
        id: String = "test-pet-id",
        definitionId: String = "pet_01",
        evolutionStage: Int = 1,
        experience: Int = 0,
        mood: Int = 8,
        lastFedDate: Date? = nil,
        feedingsToday: Int = 0,
        abilityLevel: Int = 1
    ) -> OwnedPet {
        OwnedPet(
            id: id,
            petDefinitionId: definitionId,
            evolutionStage: evolutionStage,
            experience: experience,
            mood: mood,
            lastFedDate: lastFedDate,
            feedingsToday: feedingsToday,
            isEquipped: false,
            abilityLevel: abilityLevel
        )
    }
    
    let config = PetConfig.shared
    let feeder = TestablePetFeeder()
    let decayer = TestableMoodDecay()
    let evolutionChecker = TestableEvolutionChecker()
    
    // MARK: - Feeding Tests
    
    func testBasicFeeding() {
        var pet = makePet()
        let initialXP = pet.experience
        let initialMood = pet.mood
        
        let result = feeder.feed(pet: &pet, equippedPet: nil)
        
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.xpGained, config.xpPerFeeding)
        XCTAssertEqual(result.moodGained, config.moodBoostPerFeeding)
        XCTAssertEqual(pet.experience, initialXP + config.xpPerFeeding)
        XCTAssertEqual(pet.mood, initialMood + config.moodBoostPerFeeding)
        XCTAssertEqual(pet.feedingsToday, 1)
        XCTAssertNotNil(pet.lastFedDate)
    }
    
    func testFeedingUpdatesRemainingCount() {
        var pet = makePet()
        
        let result1 = feeder.feed(pet: &pet, equippedPet: nil)
        XCTAssertEqual(result1.feedingsRemaining, config.maxFeedingsPerDay - 1)
        
        let result2 = feeder.feed(pet: &pet, equippedPet: nil)
        XCTAssertEqual(result2.feedingsRemaining, config.maxFeedingsPerDay - 2)
        
        let result3 = feeder.feed(pet: &pet, equippedPet: nil)
        XCTAssertEqual(result3.feedingsRemaining, 0)
    }
    
    func testMaxFeedingsPerDay() {
        var pet = makePet(
            lastFedDate: Date(),
            feedingsToday: config.maxFeedingsPerDay
        )
        
        let result = feeder.feed(pet: &pet, equippedPet: nil)
        
        XCTAssertFalse(result.success)
        XCTAssertTrue(result.message.contains("\(config.maxFeedingsPerDay)"))
    }
    
    func testFeedingAtMaxFeedingsMinusOne() {
        var pet = makePet(
            lastFedDate: Date(),
            feedingsToday: config.maxFeedingsPerDay - 1
        )
        
        let result = feeder.feed(pet: &pet, equippedPet: nil)
        
        XCTAssertTrue(result.success, "Should allow feeding when at max-1")
        XCTAssertEqual(pet.feedingsToday, config.maxFeedingsPerDay)
        XCTAssertEqual(result.feedingsRemaining, 0)
    }
    
    func testFeedingsResetOnNewDay() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        var pet = makePet(
            lastFedDate: yesterday,
            feedingsToday: config.maxFeedingsPerDay
        )
        
        let result = feeder.feed(pet: &pet, equippedPet: nil)
        
        XCTAssertTrue(result.success, "Should allow feeding on new day")
        XCTAssertEqual(pet.feedingsToday, 1, "Feedings should reset to 1 after feeding on new day")
    }
    
    func testFeedingNeverFedBefore() {
        var pet = makePet(lastFedDate: nil, feedingsToday: 0)
        
        let result = feeder.feed(pet: &pet, equippedPet: nil)
        
        XCTAssertTrue(result.success)
        XCTAssertEqual(pet.feedingsToday, 1)
    }
    
    // MARK: - Mood Tests
    
    func testMoodIncreaseOnFeeding() {
        var pet = makePet(mood: 5)
        
        _ = feeder.feed(pet: &pet, equippedPet: nil)
        
        XCTAssertEqual(pet.mood, 5 + config.moodBoostPerFeeding)
    }
    
    func testMoodCappedAtMax() {
        var pet = makePet(mood: config.maxMood)
        
        _ = feeder.feed(pet: &pet, equippedPet: nil)
        
        XCTAssertEqual(pet.mood, config.maxMood, "Mood should not exceed max")
    }
    
    func testMoodCappedNearMax() {
        var pet = makePet(mood: config.maxMood - 1)
        
        // If moodBoostPerFeeding > 1, this would exceed max
        _ = feeder.feed(pet: &pet, equippedPet: nil)
        
        XCTAssertLessThanOrEqual(pet.mood, config.maxMood)
    }
    
    // MARK: - Mood Decay Tests
    
    func testMoodDecayAfterOneDay() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        var pet = makePet(mood: 8, lastFedDate: yesterday)
        
        decayer.applyDecay(to: &pet)
        
        XCTAssertEqual(pet.mood, 8 - config.moodDecayPerDay)
    }
    
    func testMoodDecayAfterMultipleDays() {
        let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: Date())!
        var pet = makePet(mood: 8, lastFedDate: threeDaysAgo)
        
        decayer.applyDecay(to: &pet)
        
        XCTAssertEqual(pet.mood, 8 - (3 * config.moodDecayPerDay))
    }
    
    func testMoodDecayFlooredAtMinimum() {
        let tenDaysAgo = Calendar.current.date(byAdding: .day, value: -10, to: Date())!
        var pet = makePet(mood: 5, lastFedDate: tenDaysAgo)
        
        decayer.applyDecay(to: &pet)
        
        XCTAssertEqual(pet.mood, config.minMood, "Mood should not go below minimum")
    }
    
    func testNoDecayOnSameDay() {
        var pet = makePet(mood: 8, lastFedDate: Date())
        
        decayer.applyDecay(to: &pet)
        
        XCTAssertEqual(pet.mood, 8, "No decay should occur on same day")
    }
    
    func testNoDecayWhenNeverFed() {
        var pet = makePet(mood: 8, lastFedDate: nil)
        
        decayer.applyDecay(to: &pet)
        
        XCTAssertEqual(pet.mood, 8, "No decay when pet has never been fed")
    }
    
    func testPebbleFortitudeReducesDecay() {
        // pet_05 is Pebble with Fortitude ability (-15% mood decay)
        let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: Date())!
        var pebble = makePet(
            definitionId: "pet_05",
            evolutionStage: 7,  // Stage 7-9 = 100% effectiveness
            mood: 10,
            lastFedDate: threeDaysAgo,
            abilityLevel: 1
        )
        
        var normalPet = makePet(
            definitionId: "pet_01",
            evolutionStage: 7,
            mood: 10,
            lastFedDate: threeDaysAgo,
            abilityLevel: 1
        )
        
        decayer.applyDecay(to: &pebble)
        decayer.applyDecay(to: &normalPet)
        
        // Normal: 10 - 3 = 7
        // Pebble: 10 - (3 * 0.85) = 10 - 2 = 8 (rounded)
        XCTAssertGreaterThan(pebble.mood, normalPet.mood, "Pebble should have higher mood due to Fortitude")
    }
    
    // MARK: - Evolution Tests
    
    func testEvolutionOnFeeding() {
        // Need 100 XP for stage 2
        // With 25 XP per feeding, need 4 feedings
        var pet = makePet(experience: 75)  // Just 25 XP away from evolution
        
        let result = feeder.feed(pet: &pet, equippedPet: nil)
        
        XCTAssertTrue(result.didEvolve)
        XCTAssertEqual(result.newStage, 2)
        XCTAssertEqual(result.previousStage, 1)
        XCTAssertEqual(pet.evolutionStage, 2)
    }
    
    func testNoEvolutionWhenXPInsufficient() {
        var pet = makePet(experience: 50)  // Still 50 XP away from evolution
        
        let result = feeder.feed(pet: &pet, equippedPet: nil)
        
        XCTAssertFalse(result.didEvolve)
        XCTAssertNil(result.newStage)
        XCTAssertEqual(pet.evolutionStage, 1)
    }
    
    func testEvolutionStageThresholds() {
        // xpPerEvolution: [0, 100, 250, 500, 1000, 2000, 4000, 7000, 12000, 20000]
        let thresholds: [(xp: Int, expectedStage: Int)] = [
            (0, 1),
            (99, 1),
            (100, 2),
            (249, 2),
            (250, 3),
            (499, 3),
            (500, 4),
            (999, 4),
            (1000, 5),
            (1999, 5),
            (2000, 6),
            (3999, 6),
            (4000, 7),
            (6999, 7),
            (7000, 8),
            (11999, 8),
            (12000, 9),
            (19999, 9),
            (20000, 10),
            (50000, 10)  // Above max still capped at 10
        ]
        
        for (xp, expectedStage) in thresholds {
            let stage = config.currentStage(forXP: xp)
            XCTAssertEqual(stage, expectedStage, "XP \(xp) should be stage \(expectedStage), got \(stage)")
        }
    }
    
    func testMultipleEvolutionStagesSkipped() {
        // If XP gain somehow jumps multiple stages (shouldn't happen normally)
        var pet = makePet(experience: 0)
        pet.experience = 500  // Jump straight to stage 4
        
        let newStage = config.currentStage(forXP: pet.experience)
        
        XCTAssertEqual(newStage, 4)
    }
    
    // MARK: - Evolution Status Tests
    
    func testEvolutionStatusCanEvolve() {
        // xpPerEvolution uses index = stage, so stage 2 needs xpPerEvolution[2] = 250
        let pet = makePet(experience: 250)  // At stage 2 threshold (for stage 1 -> 2)
        
        let status = evolutionChecker.checkEvolution(for: pet)
        
        XCTAssertTrue(status.canEvolve)
        XCTAssertEqual(status.currentStage, 1)
        XCTAssertEqual(status.nextStage, 2)
    }
    
    func testEvolutionStatusCannotEvolve() {
        let pet = makePet(experience: 50)
        
        let status = evolutionChecker.checkEvolution(for: pet)
        
        XCTAssertFalse(status.canEvolve)
        // xpNeeded(forStage: 2) returns xpPerEvolution[2] = 250
        XCTAssertEqual(status.xpNeeded, 250)
        XCTAssertEqual(status.xpCurrent, 50)
    }
    
    func testEvolutionStatusMaxed() {
        let pet = makePet(evolutionStage: 10, experience: 25000)
        
        let status = evolutionChecker.checkEvolution(for: pet)
        
        XCTAssertFalse(status.canEvolve)
        XCTAssertTrue(status.isMaxed)
        XCTAssertEqual(status.currentStage, 10)
        XCTAssertEqual(status.nextStage, 10)
    }
    
    func testEvolutionStatusProgress() {
        // Stage 2 needs 250 XP (xpPerEvolution[2]), pet has 50
        let pet = makePet(experience: 50)
        
        let status = evolutionChecker.checkEvolution(for: pet)
        
        // Progress = 50 / 250 = 0.2
        XCTAssertEqual(status.progress, 0.2, accuracy: 0.01)
    }
    
    // MARK: - PP Award Tests
    
    func testPPAwardedAtStage3() {
        var pet = makePet(evolutionStage: 2, experience: 225)  // 25 XP from stage 3 (250)
        
        let result = feeder.feed(pet: &pet, equippedPet: nil)
        
        XCTAssertTrue(result.didEvolve)
        XCTAssertEqual(result.newStage, 3)
        // PP award happens in the actual system via UserData
        XCTAssertTrue(AbilityConfig.shared.ppEvolutionStages.contains(3))
    }
    
    func testPPAwardedAtStage6() {
        var pet = makePet(evolutionStage: 5, experience: 1975)  // 25 XP from stage 6 (2000)
        
        let result = feeder.feed(pet: &pet, equippedPet: nil)
        
        XCTAssertTrue(result.didEvolve)
        XCTAssertEqual(result.newStage, 6)
        XCTAssertTrue(AbilityConfig.shared.ppEvolutionStages.contains(6))
    }
    
    func testPPAwardedAtStage9() {
        XCTAssertTrue(AbilityConfig.shared.ppEvolutionStages.contains(9))
    }
    
    func testPPAwardedAtStage10() {
        XCTAssertTrue(AbilityConfig.shared.ppEvolutionStages.contains(10))
    }
    
    func testNoPPAtOtherStages() {
        let nonPPStages = [1, 2, 4, 5, 7, 8]
        for stage in nonPPStages {
            XCTAssertFalse(AbilityConfig.shared.ppEvolutionStages.contains(stage),
                          "Stage \(stage) should not award PP")
        }
    }
    
    // MARK: - Ability Effectiveness Tests
    
    func testAbilityEffectivenessStage1to3() {
        let pet = makePet(evolutionStage: 1, abilityLevel: 1)
        XCTAssertEqual(pet.abilityEffectiveness, 0.50, accuracy: 0.01)
        
        let pet2 = makePet(evolutionStage: 2, abilityLevel: 1)
        XCTAssertEqual(pet2.abilityEffectiveness, 0.50, accuracy: 0.01)
        
        let pet3 = makePet(evolutionStage: 3, abilityLevel: 1)
        XCTAssertEqual(pet3.abilityEffectiveness, 0.50, accuracy: 0.01)
    }
    
    func testAbilityEffectivenessStage4to6() {
        let pet = makePet(evolutionStage: 4, abilityLevel: 1)
        XCTAssertEqual(pet.abilityEffectiveness, 0.75, accuracy: 0.01)
        
        let pet5 = makePet(evolutionStage: 5, abilityLevel: 1)
        XCTAssertEqual(pet5.abilityEffectiveness, 0.75, accuracy: 0.01)
        
        let pet6 = makePet(evolutionStage: 6, abilityLevel: 1)
        XCTAssertEqual(pet6.abilityEffectiveness, 0.75, accuracy: 0.01)
    }
    
    func testAbilityEffectivenessStage7to9() {
        let pet = makePet(evolutionStage: 7, abilityLevel: 1)
        XCTAssertEqual(pet.abilityEffectiveness, 1.00, accuracy: 0.01)
        
        let pet8 = makePet(evolutionStage: 8, abilityLevel: 1)
        XCTAssertEqual(pet8.abilityEffectiveness, 1.00, accuracy: 0.01)
        
        let pet9 = makePet(evolutionStage: 9, abilityLevel: 1)
        XCTAssertEqual(pet9.abilityEffectiveness, 1.00, accuracy: 0.01)
    }
    
    func testAbilityEffectivenessStage10() {
        let pet = makePet(evolutionStage: 10, abilityLevel: 1)
        XCTAssertEqual(pet.abilityEffectiveness, 1.25, accuracy: 0.01)
    }
    
    func testAbilityEffectivenessWithAbilityLevels() {
        // Stage 7-9 base = 1.00
        // Ability level 1: 1.00 * 1.00 = 1.00
        // Ability level 2: 1.00 * 1.25 = 1.25
        // Ability level 3: 1.00 * 1.50 = 1.50
        // Ability level 4: 1.00 * 1.75 = 1.75
        // Ability level 5: 1.00 * 2.00 = 2.00
        
        let pet1 = makePet(evolutionStage: 7, abilityLevel: 1)
        XCTAssertEqual(pet1.abilityEffectiveness, 1.00, accuracy: 0.01)
        
        let pet2 = makePet(evolutionStage: 7, abilityLevel: 2)
        XCTAssertEqual(pet2.abilityEffectiveness, 1.25, accuracy: 0.01)
        
        let pet3 = makePet(evolutionStage: 7, abilityLevel: 3)
        XCTAssertEqual(pet3.abilityEffectiveness, 1.50, accuracy: 0.01)
        
        let pet4 = makePet(evolutionStage: 7, abilityLevel: 4)
        XCTAssertEqual(pet4.abilityEffectiveness, 1.75, accuracy: 0.01)
        
        let pet5 = makePet(evolutionStage: 7, abilityLevel: 5)
        XCTAssertEqual(pet5.abilityEffectiveness, 2.00, accuracy: 0.01)
    }
    
    func testAbilityEffectivenessMaxPossible() {
        // Stage 10 (1.25) * Ability Level 5 (2.0) = 2.5
        let pet = makePet(evolutionStage: 10, abilityLevel: 5)
        XCTAssertEqual(pet.abilityEffectiveness, 2.50, accuracy: 0.01)
    }
    
    func testAbilityEffectivenessMinPossible() {
        // Stage 1 (0.5) * Ability Level 1 (1.0) = 0.5
        let pet = makePet(evolutionStage: 1, abilityLevel: 1)
        XCTAssertEqual(pet.abilityEffectiveness, 0.50, accuracy: 0.01)
    }
    
    // MARK: - Ability Bonus Tests
    
    func testFrostPreserveBonusXP() {
        // Frost (pet_08) gives +50% feeding XP
        var pet = makePet()
        
        // Create Frost as equipped pet (stage 7 = 100% effectiveness)
        let frost = makePet(definitionId: "pet_08", evolutionStage: 7, abilityLevel: 1)
        
        let result = feeder.feed(pet: &pet, equippedPet: frost)
        
        // Base XP = 25, with +50% = 37 (rounded)
        let expectedXP = Int(Double(config.xpPerFeeding) * 1.50)
        XCTAssertEqual(result.xpGained, expectedXP)
    }
    
    func testFrostPreserveBonusScalesWithEffectiveness() {
        var pet = makePet()
        
        // Frost at stage 1 (50% effectiveness)
        let frostLow = makePet(definitionId: "pet_08", evolutionStage: 1, abilityLevel: 1)
        let resultLow = feeder.feed(pet: &pet, equippedPet: frostLow)
        
        pet = makePet()  // Reset
        
        // Frost at stage 10 (125% effectiveness)
        let frostHigh = makePet(definitionId: "pet_08", evolutionStage: 10, abilityLevel: 1)
        let resultHigh = feeder.feed(pet: &pet, equippedPet: frostHigh)
        
        // Low: 25 * (1 + 0.5 * 0.5) = 25 * 1.25 = 31
        // High: 25 * (1 + 0.5 * 1.25) = 25 * 1.625 = 40
        XCTAssertLessThan(resultLow.xpGained, resultHigh.xpGained)
    }
    
    func testSproutGrowthBonusXP() {
        // Sprout (pet_03) gives +20% evolution XP
        var pet = makePet()
        
        let sprout = makePet(definitionId: "pet_03", evolutionStage: 7, abilityLevel: 1)
        
        let result = feeder.feed(pet: &pet, equippedPet: sprout)
        
        // Base XP = 25, with +20% = 30
        let expectedXP = Int(Double(config.xpPerFeeding) * 1.20)
        XCTAssertEqual(result.xpGained, expectedXP)
    }
    
    func testNonSpecialPetNoBonus() {
        var pet = makePet()
        
        // Ember (pet_01) has no feeding bonus
        let ember = makePet(definitionId: "pet_01", evolutionStage: 7, abilityLevel: 1)
        
        let result = feeder.feed(pet: &pet, equippedPet: ember)
        
        XCTAssertEqual(result.xpGained, config.xpPerFeeding)
    }
    
    // MARK: - Edge Cases
    
    func testFeedingExactlyAtMidnight() {
        // Feed yesterday, then try today - should work
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!
        
        var pet = makePet(lastFedDate: yesterday, feedingsToday: config.maxFeedingsPerDay)
        
        // Feeding today should work since it's a new day
        let result = feeder.feed(pet: &pet, equippedPet: nil)
        
        XCTAssertTrue(result.success, "Should be able to feed on new day")
        XCTAssertEqual(pet.feedingsToday, 1, "Should reset to 1 feeding on new day")
    }
    
    func testZeroMoodDecayPet() {
        // A pet that was fed today should have zero decay
        var pet = makePet(mood: 8, lastFedDate: Date())
        
        decayer.applyDecay(to: &pet)
        
        XCTAssertEqual(pet.mood, 8)
    }
    
    func testMoodAlreadyAtMinimum() {
        let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: Date())!
        var pet = makePet(mood: config.minMood, lastFedDate: threeDaysAgo)
        
        decayer.applyDecay(to: &pet)
        
        XCTAssertEqual(pet.mood, config.minMood, "Mood should stay at minimum")
    }
    
    func testEvolutionFromStage9To10() {
        // Final evolution
        var pet = makePet(evolutionStage: 9, experience: 19975)  // 25 from stage 10 (20000)
        
        let result = feeder.feed(pet: &pet, equippedPet: nil)
        
        XCTAssertTrue(result.didEvolve)
        XCTAssertEqual(result.newStage, 10)
        XCTAssertEqual(pet.evolutionStage, 10)
    }
    
    func testNoEvolutionBeyondMax() {
        var pet = makePet(evolutionStage: 10, experience: 50000)
        
        let result = feeder.feed(pet: &pet, equippedPet: nil)
        
        XCTAssertFalse(result.didEvolve)
        XCTAssertNil(result.newStage)
        XCTAssertEqual(pet.evolutionStage, 10)
    }
    
    // MARK: - Config Validation Tests
    
    func testConfigMaxFeedingsPositive() {
        XCTAssertGreaterThan(config.maxFeedingsPerDay, 0)
    }
    
    func testConfigMoodRangeValid() {
        XCTAssertGreaterThan(config.maxMood, config.minMood)
        XCTAssertGreaterThanOrEqual(config.minMood, 0)
    }
    
    func testConfigEvolutionThresholdsAscending() {
        var previous = -1
        for threshold in config.xpPerEvolution {
            XCTAssertGreaterThan(threshold, previous, "Evolution thresholds must be ascending")
            previous = threshold
        }
    }
    
    func testConfigEvolutionStagesMatchThresholds() {
        XCTAssertEqual(config.xpPerEvolution.count, config.evolutionStages,
                      "Number of XP thresholds should match evolution stages")
    }
    
    // MARK: - OwnedPet Computed Properties
    
    func testCanBeFedWhenNeverFed() {
        let pet = makePet(lastFedDate: nil, feedingsToday: 0)
        XCTAssertTrue(pet.canBeFed)
    }
    
    func testCanBeFedWhenFedYesterday() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let pet = makePet(lastFedDate: yesterday, feedingsToday: config.maxFeedingsPerDay)
        XCTAssertTrue(pet.canBeFed)
    }
    
    func testCannotBeFedWhenMaxedToday() {
        let pet = makePet(lastFedDate: Date(), feedingsToday: config.maxFeedingsPerDay)
        XCTAssertFalse(pet.canBeFed)
    }
    
    func testCanBeFedWhenNotMaxedToday() {
        let pet = makePet(lastFedDate: Date(), feedingsToday: config.maxFeedingsPerDay - 1)
        XCTAssertTrue(pet.canBeFed)
    }
    
    func testMoodEmojiHappy() {
        let pet = makePet(mood: 9)
        XCTAssertEqual(pet.moodEmoji, "😊")
    }
    
    func testMoodEmojiNeutral() {
        let pet = makePet(mood: 6)
        XCTAssertEqual(pet.moodEmoji, "😐")
    }
    
    func testMoodEmojiSad() {
        let pet = makePet(mood: 3)
        XCTAssertEqual(pet.moodEmoji, "😔")
    }
    
    func testMoodEmojiVerySad() {
        let pet = makePet(mood: 1)
        XCTAssertEqual(pet.moodEmoji, "😢")
    }
    
    func testStageNames() {
        let stageNames = [
            (1, "Newborn"), (2, "Infant"), (3, "Toddler"), (4, "Child"), (5, "Youth"),
            (6, "Adolescent"), (7, "Young Adult"), (8, "Adult"), (9, "Mature"), (10, "Elder")
        ]
        
        for (stage, name) in stageNames {
            let pet = makePet(evolutionStage: stage)
            XCTAssertEqual(pet.stageName, name)
        }
    }
}
