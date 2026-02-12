import Foundation
import Combine

@MainActor
final class UserData: ObservableObject {
    static let shared = UserData()
    
    // MARK: - Published Properties
    @Published var profile: PlayerProfile
    @Published var ownedPets: [OwnedPet]
    @Published var abilities: UserAbilities
    @Published var inventory: Inventory
    @Published var coins: Int
    @Published var gems: Int
    @Published var runHistory: [CompletedRun]
    @Published var isLoggedIn: Bool = false
    @Published var dailyRewards: DailyRewardsData
    @Published var challengeData: ChallengeData
    @Published var achievements: [Achievement]
    
    // MARK: - Derived Properties
    var equippedPet: OwnedPet? {
        ownedPets.first { $0.isEquipped }
    }
    
    var ownedPetIds: Set<String> {
        Set(ownedPets.map { $0.petDefinitionId })
    }
    
    var petsOwnedCount: Int {
        ownedPets.count
    }
    
    var totalLootBoxes: Int {
        inventory.totalLootBoxes
    }
    
    // MARK: - Init
    private init() {
        // Load from persistence or use defaults
        if let savedData = DataPersistence.shared.loadUserData() {
            self.profile = savedData.profile
            self.ownedPets = savedData.ownedPets
            self.abilities = savedData.abilities
            self.inventory = savedData.inventory
            self.coins = savedData.coins
            self.gems = savedData.gems
            self.runHistory = savedData.runHistory
            self.dailyRewards = savedData.dailyRewards ?? DailyRewardsData()
            self.challengeData = savedData.challengeData ?? ChallengeData()
            self.achievements = savedData.achievements ?? AchievementDefinitions.all
            self.isLoggedIn = true
        } else {
            // New user defaults
            self.profile = PlayerProfile()
            self.ownedPets = []
            self.abilities = UserAbilities()
            self.inventory = Inventory()
            self.coins = RewardsConfig.shared.startingCoins
            self.gems = RewardsConfig.shared.startingGems
            self.runHistory = []
            self.dailyRewards = DailyRewardsData()
            self.challengeData = ChallengeData()
            self.achievements = AchievementDefinitions.all
        }
    }
    
    // MARK: - Pet Management
    func addPet(_ petDefinitionId: String) -> OwnedPet {
        let newPet = OwnedPet(
            petDefinitionId: petDefinitionId,
            isEquipped: ownedPets.isEmpty  // First pet auto-equipped
        )
        ownedPets.append(newPet)
        
        if newPet.isEquipped {
            profile.equippedPetId = newPet.id
        }
        
        // Update achievements
        AchievementsSystem.shared.updateAllProgress()
        
        save()
        return newPet
    }
    
    func equipPet(_ petId: String) {
        for i in ownedPets.indices {
            ownedPets[i].isEquipped = (ownedPets[i].id == petId)
        }
        profile.equippedPetId = petId
        save()
    }
    
    func feedPet(_ petId: String) -> Bool {
        guard let index = ownedPets.firstIndex(where: { $0.id == petId }) else { return false }
        var pet = ownedPets[index]
        
        // Check if can be fed
        if let lastFed = pet.lastFedDate, Calendar.current.isDateInToday(lastFed) {
            if pet.feedingsToday >= PetConfig.shared.maxFeedingsPerDay {
                return false
            }
        } else {
            // New day, reset feedings
            pet.feedingsToday = 0
        }
        
        // Calculate XP gain (with Frost bonus if equipped)
        var xpGain = PetConfig.shared.xpPerFeeding
        if let equippedDef = equippedPet?.definition, equippedDef.id == "pet_08" {
            // Frost's Preserve ability: +50% feeding XP
            let effectiveness = equippedPet?.abilityEffectiveness ?? 1.0
            xpGain = Int(Double(xpGain) * (1.0 + 0.50 * effectiveness))
        }
        
        // Apply feeding
        pet.experience += xpGain
        pet.mood = min(PetConfig.shared.maxMood, pet.mood + PetConfig.shared.moodBoostPerFeeding)
        pet.lastFedDate = Date()
        pet.feedingsToday += 1
        
        // Check for evolution
        let newStage = PetConfig.shared.currentStage(forXP: pet.experience)
        if newStage > pet.evolutionStage {
            pet.evolutionStage = newStage
            // Award PP at stages 3, 6, 9, 10
            if AbilityConfig.shared.ppEvolutionStages.contains(newStage) {
                abilities.petPoints += 1
            }
        }
        
        ownedPets[index] = pet
        
        // Update challenge progress
        ChallengesSystem.shared.updateProgress(type: .petFeedings, increment: 1)
        
        save()
        return true
    }
    
    func addPetXP(_ petId: String, xp: Int) {
        guard let index = ownedPets.firstIndex(where: { $0.id == petId }) else { return }
        var pet = ownedPets[index]
        
        // Apply Sprout bonus if equipped
        var modifiedXP = xp
        if let equippedDef = equippedPet?.definition, equippedDef.id == "pet_03" {
            let effectiveness = equippedPet?.abilityEffectiveness ?? 1.0
            modifiedXP = Int(Double(xp) * (1.0 + 0.20 * effectiveness))
        }
        
        pet.experience += modifiedXP
        
        // Check for evolution
        let newStage = PetConfig.shared.currentStage(forXP: pet.experience)
        if newStage > pet.evolutionStage {
            pet.evolutionStage = newStage
            if AbilityConfig.shared.ppEvolutionStages.contains(newStage) {
                abilities.petPoints += 1
            }
        }
        
        ownedPets[index] = pet
        save()
    }
    
    // MARK: - Currency
    func addCoins(_ amount: Int) {
        // Apply rank boost to coin rewards
        let rankBoost = profile.rank.coinBoost
        let boostedAmount = Int(Double(amount) * (1.0 + rankBoost))
        coins += boostedAmount
        save()
    }
    
    func spendCoins(_ amount: Int) -> Bool {
        guard coins >= amount else { return false }
        coins -= amount
        save()
        return true
    }
    
    func addGems(_ amount: Int) {
        gems += amount
        save()
    }
    
    func spendGems(_ amount: Int) -> Bool {
        guard gems >= amount else { return false }
        gems -= amount
        save()
        return true
    }
    
    // MARK: - Progression
    func addRP(_ amount: Int) {
        profile.rp += amount
        save()
    }
    
    func addXP(_ amount: Int) {
        profile.xp += amount
        let newLevel = PlayerLevelConfig.level(forXP: profile.xp)
        if newLevel > profile.level {
            // Level up! Award AP
            let levelsGained = newLevel - profile.level
            abilities.abilityPoints += levelsGained * AbilityConfig.shared.apPerLevel
            profile.level = newLevel
        }
        save()
    }
    
    // MARK: - Loot Boxes
    func addLootBox(_ rarity: Rarity) {
        inventory.addLootBox(rarity)
        save()
    }
    
    func openLootBox(_ rarity: Rarity) -> LootBoxContents? {
        guard inventory.removeLootBox(rarity) else { return nil }
        
        var contents = LootBoxContents.generate(for: rarity)
        
        // Apply Spark bonus if equipped
        if let equippedDef = equippedPet?.definition, equippedDef.id == "pet_06" {
            let effectiveness = equippedPet?.abilityEffectiveness ?? 1.0
            let bonusCoins = Int(Double(contents.coins) * 0.25 * effectiveness)
            contents = LootBoxContents(
                coins: contents.coins + bonusCoins,
                gems: contents.gems,
                rarity: contents.rarity
            )
        }
        
        // Add rewards
        addCoins(contents.coins)
        addGems(contents.gems)
        
        // Update challenge progress
        ChallengesSystem.shared.updateProgress(type: .lootBoxes, increment: 1)
        
        save()
        return contents
    }
    
    // MARK: - Run Completion
    func completeRun(_ run: CompletedRun) {
        runHistory.insert(run, at: 0)
        profile.totalRuns += 1
        profile.totalSprints += run.sprintsTotal
        profile.totalSprintsValid += run.sprintsCompleted
        profile.totalDurationSeconds += run.durationSeconds
        profile.totalDistanceMeters += run.distanceMeters
        
        // Update streak
        updateStreak()
        
        // Update challenge progress
        ChallengesSystem.shared.updateProgress(type: .runs, increment: 1)
        ChallengesSystem.shared.updateProgress(type: .sprints, increment: run.sprintsCompleted)
        ChallengesSystem.shared.updateProgress(type: .distance, increment: Int(run.distanceMeters))
        
        // Update achievements
        AchievementsSystem.shared.updateAllProgress()
        
        save()
    }
    
    private func updateStreak() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        if let lastRun = profile.lastRunDate {
            let lastRunDay = calendar.startOfDay(for: lastRun)
            let daysDiff = calendar.dateComponents([.day], from: lastRunDay, to: today).day ?? 0
            
            if daysDiff == 1 {
                // Consecutive day
                profile.currentStreak += 1
                profile.longestStreak = max(profile.longestStreak, profile.currentStreak)
            } else if daysDiff > 1 {
                // Streak broken
                profile.currentStreak = 1
            }
            // daysDiff == 0 means same day, streak unchanged
        } else {
            // First run
            profile.currentStreak = 1
        }
        
        profile.lastRunDate = Date()
    }
    
    // MARK: - Abilities
    func unlockAbility(_ nodeId: String) -> Bool {
        guard let node = AbilityTreeData.node(byId: nodeId) else { return false }
        let success = abilities.unlock(node)
        if success {
            AchievementsSystem.shared.updateAllProgress()
            save()
        }
        return success
    }
    
    func upgradePetAbility(_ petId: String) -> Bool {
        let success = abilities.upgradePetAbility(petId: petId)
        if success { save() }
        return success
    }
    
    func unlockPetAbilityNode(_ petId: String, nodeId: String) -> Bool {
        let success = abilities.unlockPetAbilityNode(petId: petId, nodeId: nodeId)
        if success { save() }
        return success
    }
    
    // MARK: - Persistence
    func save() {
        DataPersistence.shared.saveUserData(self)
    }
    
    func logout() {
        profile = PlayerProfile()
        ownedPets = []
        abilities = UserAbilities()
        inventory = Inventory()
        coins = RewardsConfig.shared.startingCoins
        gems = RewardsConfig.shared.startingGems
        runHistory = []
        dailyRewards = DailyRewardsData()
        challengeData = ChallengeData()
        achievements = AchievementDefinitions.all
        isLoggedIn = false
        DataPersistence.shared.clearUserData()
    }
    
    // MARK: - Debug
    #if DEBUG
    func loadTestData() {
        // Add test pets
        let pet1 = addPet("pet_01")  // Ember
        addPetXP(pet1.id, xp: 600)  // Stage 4
        
        let pet2 = addPet("pet_02")  // Splash
        addPetXP(pet2.id, xp: 200)  // Stage 3
        
        let _ = addPet("pet_03")  // Sprout
        
        // Add some resources
        coins = 2500
        gems = 50
        profile.rp = 2450
        profile.xp = 850
        profile.level = 8
        profile.currentStreak = 5
        profile.longestStreak = 7
        profile.totalRuns = 23
        profile.totalSprints = 67
        profile.totalSprintsValid = 58
        abilities.abilityPoints = 5
        abilities.petPoints = 3
        
        // Add some loot boxes
        inventory.addLootBox(.common)
        inventory.addLootBox(.common)
        inventory.addLootBox(.uncommon)
        inventory.addLootBox(.rare)
        
        // Add some run history
        runHistory = [
            CompletedRun(
                durationSeconds: 1920,
                sprintsCompleted: 4,
                sprintsTotal: 4,
                rpEarned: 180,
                xpEarned: 220,
                coinsEarned: 340
            ),
            CompletedRun(
                date: Date().addingTimeInterval(-86400),
                durationSeconds: 1500,
                sprintsCompleted: 3,
                sprintsTotal: 4,
                rpEarned: 145,
                xpEarned: 175,
                coinsEarned: 280
            )
        ]
        
        // Initialize systems
        ChallengesSystem.shared.refreshIfNeeded()
        AchievementsSystem.shared.initializeIfNeeded()
        AchievementsSystem.shared.updateAllProgress()
        
        isLoggedIn = true
        save()
    }
    #endif
}

// MARK: - Saveable Data Structure
struct SaveableUserData: Codable {
    let profile: PlayerProfile
    let ownedPets: [OwnedPet]
    let abilities: UserAbilities
    let inventory: Inventory
    let coins: Int
    let gems: Int
    let runHistory: [CompletedRun]
    let dailyRewards: DailyRewardsData?
    let challengeData: ChallengeData?
    let achievements: [Achievement]?
}
