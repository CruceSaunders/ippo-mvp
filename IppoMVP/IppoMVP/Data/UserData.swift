import Foundation
import Combine
import UserNotifications

@MainActor
final class UserData: ObservableObject {
    static let shared = UserData()

    // MARK: - Published Properties
    @Published var profile: PlayerProfile
    @Published var ownedPets: [OwnedPet]
    @Published var inventory: PlayerInventory
    @Published var runHistory: [CompletedRun]
    @Published var isLoggedIn: Bool = false
    @Published var pendingRunSummary: CompletedRun? {
        didSet { persistPendingRun() }
    }
    @Published var starterPetId: String?
    @Published var pendingEvolution: PendingEvolution?
    @Published var activeCareNeed: CareNeedType?
    @Published var pendingMilestoneToast: MilestoneToast?

    /// Timestamp of the most recent local mutation (run completion, purchase, etc.).
    /// Cloud sync will skip overwriting local state if it started before this timestamp.
    private var lastLocalMutationDate: Date = .distantPast
    private var cloudSyncInFlight: Bool = false

    // MARK: - Derived Properties
    var equippedPet: OwnedPet? {
        ownedPets.first { $0.isEquipped && !$0.isLost }
    }

    var activePets: [OwnedPet] {
        ownedPets.filter { !$0.isLost }
    }

    var lostPets: [OwnedPet] {
        ownedPets.filter { $0.isLost }
    }

    var ownedPetDefinitionIds: Set<String> {
        Set(ownedPets.map { $0.petDefinitionId })
    }

    // MARK: - Init
    private init() {
        if let savedData = DataPersistence.shared.loadUserData() {
            self.profile = savedData.profile
            self.ownedPets = savedData.ownedPets
            self.inventory = savedData.inventory
            self.runHistory = savedData.runHistory
            self.isLoggedIn = true
        } else {
            self.profile = PlayerProfile()
            self.ownedPets = []
            self.inventory = PlayerInventory()
            self.runHistory = []
        }
        inventory.cleanExpiredBoosts()
        migrateEvolutionStages()
        loadPendingRun()
    }

    private func migrateEvolutionStages() {
        var needsSave = false
        let config = PetConfig.shared
        for i in ownedPets.indices {
            let correctedLevel = config.levelForXP(ownedPets[i].experience)
            let correctedStage = ownedPets[i].definition?.stageForLevel(correctedLevel) ?? config.stageForLevel(correctedLevel)
            if ownedPets[i].level != correctedLevel {
                ownedPets[i].level = correctedLevel
                needsSave = true
            }
            if ownedPets[i].evolutionStage != correctedStage {
                ownedPets[i].evolutionStage = correctedStage
                needsSave = true
            }
        }
        if needsSave { save() }
    }

    // MARK: - Pet Management
    func addPet(definitionId: String, equip: Bool = false) {
        guard GameData.pet(byId: definitionId) != nil else { return }
        guard !ownedPets.contains(where: { $0.petDefinitionId == definitionId }) else { return }

        if equip {
            for i in ownedPets.indices {
                ownedPets[i].isEquipped = false
            }
        }

        let pet = OwnedPet(
            petDefinitionId: definitionId,
            mood: 3,
            isEquipped: equip
        )
        ownedPets.append(pet)
        profile.sprintsSinceLastCatch = 0
        save()
        WatchConnectivityService.shared.pushProfileToWatch()
    }

    func equipPet(_ petId: String) {
        for i in ownedPets.indices {
            ownedPets[i].isEquipped = (ownedPets[i].id == petId)
        }
        profile.equippedPetId = petId
        save()
        WatchConnectivityService.shared.pushProfileToWatch()
    }

    // MARK: - Coins
    func addCoins(_ amount: Int) {
        profile.coins += amount
        save()
    }

    func spendCoins(_ amount: Int) -> Bool {
        guard profile.coins >= amount else { return false }
        profile.coins -= amount
        save()
        return true
    }

    // MARK: - XP
    func addXP(_ amount: Int) {
        var adjustedAmount = Double(amount)

        if inventory.activeXPBoost != nil {
            adjustedAmount *= (1.0 + EconomyConfig.shared.xpBoostMultiplier)
        }

        let econConfig = EconomyConfig.shared
        let streakDays = min(profile.currentStreak, econConfig.streakBonusCap)
        if streakDays > 0 {
            let streakBonus = 1.0 + (Double(streakDays) / Double(econConfig.streakBonusCap)) * econConfig.maxStreakBonusPercent
            adjustedAmount *= streakBonus
        }

        if let pet = equippedPet {
            adjustedAmount *= pet.xpMultiplier
        }

        profile.xp += Int(adjustedAmount)
        let newPlayerLevel = PlayerLevelConfig.level(forXP: profile.xp)
        if newPlayerLevel > profile.level {
            profile.level = newPlayerLevel
        }

        if let pet = equippedPet, let idx = ownedPets.firstIndex(where: { $0.id == pet.id }) {
            let petConfig = PetConfig.shared
            let oldStage = ownedPets[idx].evolutionStage
            let oldImageName = ownedPets[idx].currentImageName
            ownedPets[idx].experience += Int(adjustedAmount)

            let newLevel = petConfig.levelForXP(ownedPets[idx].experience)
            ownedPets[idx].level = newLevel

            let newStage = ownedPets[idx].definition?.stageForLevel(newLevel) ?? petConfig.stageForLevel(newLevel)
            if newStage > oldStage {
                ownedPets[idx].evolutionStage = newStage
                if let def = ownedPets[idx].definition {
                    pendingEvolution = PendingEvolution(
                        petName: def.name,
                        petDefinitionId: def.id,
                        newStage: newStage,
                        stageName: petConfig.stageName(for: newStage),
                        oldImageName: oldImageName,
                        newImageName: def.stageImageNames[safe: newStage - 1] ?? oldImageName
                    )
                }
            }
        }

        save()
    }

    // MARK: - Pet Care
    func feedPet() -> Bool {
        guard let pet = equippedPet,
              let idx = ownedPets.firstIndex(where: { $0.id == pet.id }),
              inventory.food > 0 else { return false }

        inventory.food -= 1
        if pet.canEarnFeedXP {
            ownedPets[idx].lastFedDate = Date()
            addPetXP(idx: idx, amount: PetConfig.shared.xpPerFeeding)
        }
        if activeCareNeed == .hungry { clearCareNeed() }
        cancelCareNotificationIfSatisfied()
        recalculateMood(at: idx)

        if !UserDefaults.standard.bool(forKey: "ippo.hasEverFed") {
            UserDefaults.standard.set(true, forKey: "ippo.hasEverFed")
            pendingMilestoneToast = .firstFeed
        }

        save()
        return true
    }

    func waterPet() -> Bool {
        guard let pet = equippedPet,
              let idx = ownedPets.firstIndex(where: { $0.id == pet.id }),
              inventory.water > 0 else { return false }

        inventory.water -= 1
        if pet.canEarnWaterXP {
            ownedPets[idx].lastWateredDate = Date()
            addPetXP(idx: idx, amount: PetConfig.shared.xpPerWatering)
        }
        if activeCareNeed == .thirsty { clearCareNeed() }
        cancelCareNotificationIfSatisfied()
        recalculateMood(at: idx)
        save()
        return true
    }

    private func cancelCareNotificationIfSatisfied() {
        guard let pet = equippedPet else { return }
        let calendar = Calendar.current
        let fedToday = pet.lastFedDate.map { calendar.isDateInToday($0) } ?? false
        let wateredToday = pet.lastWateredDate.map { calendar.isDateInToday($0) } ?? false
        if fedToday && wateredToday {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["daily_care"])
        }
    }

    func petPet() -> Bool {
        guard let pet = equippedPet,
              let idx = ownedPets.firstIndex(where: { $0.id == pet.id }) else { return false }

        if pet.canEarnPetXP {
            ownedPets[idx].lastPettedDate = Date()
            addPetXP(idx: idx, amount: PetConfig.shared.xpPerPetting)
        }
        recalculateMood(at: idx)
        save()
        return true
    }

    private func addPetXP(idx: Int, amount: Int) {
        var adjustedAmount = Double(amount)
        adjustedAmount *= ownedPets[idx].xpMultiplier

        if inventory.activeXPBoost != nil {
            adjustedAmount *= (1.0 + EconomyConfig.shared.xpBoostMultiplier)
        }

        let econConfig = EconomyConfig.shared
        let streakDays = min(profile.currentStreak, econConfig.streakBonusCap)
        if streakDays > 0 {
            let streakBonus = 1.0 + (Double(streakDays) / Double(econConfig.streakBonusCap)) * econConfig.maxStreakBonusPercent
            adjustedAmount *= streakBonus
        }

        let petConfig = PetConfig.shared
        let oldStage = ownedPets[idx].evolutionStage
        let oldImageName = ownedPets[idx].currentImageName
        ownedPets[idx].experience += Int(adjustedAmount)

        let newLevel = petConfig.levelForXP(ownedPets[idx].experience)
        ownedPets[idx].level = newLevel

        let newStage = ownedPets[idx].definition?.stageForLevel(newLevel) ?? petConfig.stageForLevel(newLevel)
        if newStage > oldStage {
            ownedPets[idx].evolutionStage = newStage
            if let def = ownedPets[idx].definition {
                pendingEvolution = PendingEvolution(
                    petName: def.name,
                    petDefinitionId: def.id,
                    newStage: newStage,
                    stageName: petConfig.stageName(for: newStage),
                    oldImageName: oldImageName,
                    newImageName: def.stageImageNames[safe: newStage - 1] ?? oldImageName
                )
            }
        }
    }

    func recalculateMood(at idx: Int) {
        guard !inventory.isHibernating else { return }
        let pet = ownedPets[idx]
        guard pet.isEquipped else { return }

        var score = 0
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let lastRun = profile.lastRunDate,
           calendar.isDate(lastRun, inSameDayAs: Date()) || calendar.isDate(lastRun, inSameDayAs: today.addingTimeInterval(-86400)) {
            score += 1
        }

        if let lastFed = pet.lastFedDate, calendar.isDateInToday(lastFed) {
            score += 1
        }

        if let lastWatered = pet.lastWateredDate, calendar.isDateInToday(lastWatered) {
            score += 1
        }

        if let lastPetted = pet.lastPettedDate, calendar.isDateInToday(lastPetted) {
            score += 1
        }

        let mood: Int
        if score >= 3 {
            mood = 3
        } else if score >= 2 {
            mood = 2
        } else {
            mood = 1
        }
        ownedPets[idx].mood = mood
    }

    // MARK: - Pet Runaway
    func checkRunaway() {
        guard !inventory.isHibernating else { return }
        let config = PetConfig.shared

        for i in ownedPets.indices where ownedPets[i].isEquipped && !ownedPets[i].isLost {
            if ownedPets[i].mood == 1 {
                ownedPets[i].consecutiveSadDays += 1
            } else {
                ownedPets[i].consecutiveSadDays = 0
            }

            let sadDays = ownedPets[i].consecutiveSadDays
            let noInteraction = daysSinceLastInteraction()

            if sadDays >= config.runawayDaysSad && noInteraction >= config.runawayDaysNoInteraction {
                let petName = ownedPets[i].definition?.name ?? "Your pet"
                ownedPets[i].isLost = true
                ownedPets[i].isEquipped = false
                profile.equippedPetId = nil
                WatchConnectivityService.shared.pushProfileToWatch()
                NotificationSystem.shared.notifyPetRanAway(petName: petName)
            }
        }
        save()
    }

    func rescuePet(_ petId: String) -> Bool {
        guard let idx = ownedPets.firstIndex(where: { $0.id == petId && $0.isLost }) else { return false }
        let cost = PetConfig.shared.rescueCost(forStage: ownedPets[idx].evolutionStage)
        guard spendCoins(cost) else { return false }

        ownedPets[idx].isLost = false
        ownedPets[idx].mood = 1
        ownedPets[idx].consecutiveSadDays = 0
        save()
        return true
    }

    private func daysSinceLastInteraction() -> Int {
        guard let lastInteraction = profile.lastInteractionDate else { return 999 }
        let calendar = Calendar.current
        return calendar.dateComponents([.day], from: lastInteraction, to: Date()).day ?? 999
    }

    // MARK: - Shop
    func buyItem(_ itemType: ShopItemType) -> Bool {
        let config = EconomyConfig.shared
        let cost: Int
        switch itemType {
        case .food: cost = config.foodCost
        case .water: cost = config.waterCost
        case .foodPack: cost = config.foodPackCost
        case .waterPack: cost = config.waterPackCost
        case .xpBoost: cost = config.xpBoostCost
        case .encounterCharm: cost = config.encounterCharmCost
        case .coinBoost: cost = config.coinBoostCost
        case .hibernation: cost = config.hibernationCost
        case .streakFreeze: cost = config.streakFreezeCost
        }

        guard spendCoins(cost) else { return false }

        switch itemType {
        case .food: inventory.food += 1
        case .water: inventory.water += 1
        case .foodPack: inventory.food += config.foodPackCount
        case .waterPack: inventory.water += config.waterPackCount
        case .xpBoost:
            let boost = ActiveBoost(
                type: .xpBoost,
                expiresAt: Date().addingTimeInterval(TimeInterval(config.xpBoostDurationHours * 3600))
            )
            inventory.activeBoosts.append(boost)
        case .encounterCharm:
            let boost = ActiveBoost(type: .encounterCharm, expiresAt: Date().addingTimeInterval(86400))
            inventory.activeBoosts.append(boost)
            WatchConnectivityService.shared.pushProfileToWatch()
        case .coinBoost:
            let boost = ActiveBoost(type: .coinBoost, expiresAt: Date().addingTimeInterval(86400))
            inventory.activeBoosts.append(boost)
        case .hibernation:
            inventory.hibernationEndsAt = Date().addingTimeInterval(TimeInterval(config.hibernationDays * 86400))
        case .streakFreeze:
            if let existing = inventory.streakFreezeEndsAt, Date() < existing {
                inventory.streakFreezeEndsAt = existing.addingTimeInterval(TimeInterval(config.streakFreezeDays * 86400))
            } else {
                inventory.streakFreezeEndsAt = Date().addingTimeInterval(TimeInterval(config.streakFreezeDays * 86400))
            }
        }

        save()
        return true
    }

    // MARK: - Run Completion
    func completeRun(_ run: CompletedRun) {
        lastLocalMutationDate = Date()

        runHistory.insert(run, at: 0)
        if runHistory.count > 50 { runHistory = Array(runHistory.prefix(50)) }

        profile.totalRuns += 1
        profile.totalDurationSeconds += run.durationSeconds
        profile.totalDistanceMeters += run.distanceMeters

        let isValidatedRun = run.sprintsCompleted >= 1

        if isValidatedRun {
            profile.totalSprints += run.sprintsCompleted
            profile.totalSprintsValid += run.sprintsCompleted

            updateStreak()
            profile.lastRunDate = Date()

            addCoins(run.coinsEarned)
            addXP(run.xpEarned)
        }

        inventory.consumePerRunBoosts()

        if let idx = ownedPets.firstIndex(where: { $0.isEquipped && !$0.isLost }) {
            recalculateMood(at: idx)
        }

        for milestone in [1, 5, 10, 25, 50, 100] where profile.totalRuns == milestone {
            pendingMilestoneToast = .runMilestone(milestone)
            break
        }

        if run.petCaughtId != nil && ownedPets.count == 2 {
            pendingMilestoneToast = .firstCatch
        }

        save()
    }

    // MARK: - Streak
    func updateStreak() {
        profile.lastInteractionDate = Date()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let oldStreak = profile.currentStreak

        if let lastRun = profile.lastRunDate {
            let lastRunDay = calendar.startOfDay(for: lastRun)
            let daysDiff = calendar.dateComponents([.day], from: lastRunDay, to: today).day ?? 0

            if daysDiff <= 1 {
                if daysDiff == 1 || profile.currentStreak == 0 {
                    profile.currentStreak += 1
                }
                profile.longestStreak = max(profile.longestStreak, profile.currentStreak)
            } else if daysDiff > 1 && !inventory.isHibernating && !inventory.isStreakFrozen {
                profile.currentStreak = 1
            }
        } else {
            profile.currentStreak = 1
        }

        let newStreak = profile.currentStreak
        if newStreak != oldStreak {
            for milestone in [3, 7, 14, 30, 50, 100] where newStreak == milestone {
                SoundManager.shared.play(.streakMilestone)
                pendingMilestoneToast = .streakMilestone(milestone)
                break
            }
        }
    }

    func recordInteraction() {
        profile.lastInteractionDate = Date()
        save()
    }

    // MARK: - Persistence
    func save() {
        DataPersistence.shared.saveUserData(self)
        CloudService.shared.syncToCloud(self)
    }

    func syncFromCloud() async {
        guard !cloudSyncInFlight else { return }
        cloudSyncInFlight = true
        let syncStartDate = Date()

        defer { cloudSyncInFlight = false }

        guard let cloudData = await CloudService.shared.loadUserData() else {
            await CloudService.shared.saveUserData(self)
            return
        }

        // If a local mutation happened while we were fetching from the cloud,
        // the cloud data is stale. Push local state to cloud instead.
        if lastLocalMutationDate > syncStartDate {
            await CloudService.shared.saveUserData(self)
            return
        }

        let localSnapshot = SaveableUserData(
            profile: profile,
            ownedPets: ownedPets,
            inventory: inventory,
            runHistory: runHistory
        )

        let merged = CloudService.shared.mergeData(
            local: localSnapshot,
            cloud: cloudData
        )

        profile = merged.profile
        ownedPets = merged.ownedPets
        inventory = merged.inventory
        runHistory = merged.runHistory
        isLoggedIn = true

        DataPersistence.shared.saveUserData(self)
        await CloudService.shared.saveUserData(self)
    }

    func logout() {
        profile = PlayerProfile()
        ownedPets = []
        inventory = PlayerInventory()
        runHistory = []
        isLoggedIn = false
        pendingRunSummary = nil
        activeCareNeed = nil
        DataPersistence.shared.clearUserData()
        UserDefaults.standard.removeObject(forKey: "pendingRunSummary")
        UserDefaults.standard.removeObject(forKey: "scheduledCareNeedType")
        UserDefaults.standard.removeObject(forKey: "scheduledCareNeedTime")
        UserDefaults.standard.removeObject(forKey: "lastDailyRewardDate")
        UserDefaults.standard.removeObject(forKey: "ippo.hasEverFed")
    }

    // MARK: - Pending Run Persistence

    private func persistPendingRun() {
        if let run = pendingRunSummary,
           let data = try? JSONEncoder().encode(run) {
            UserDefaults.standard.set(data, forKey: "pendingRunSummary")
        } else {
            UserDefaults.standard.removeObject(forKey: "pendingRunSummary")
        }
    }

    func loadPendingRun() {
        guard let data = UserDefaults.standard.data(forKey: "pendingRunSummary"),
              let run = try? JSONDecoder().decode(CompletedRun.self, from: data) else { return }
        pendingRunSummary = run
    }

    // MARK: - Daily Login Rewards

    func claimDailyRewards() {
        let key = "lastDailyRewardDate"
        let calendar = Calendar.current

        if let lastClaim = UserDefaults.standard.object(forKey: key) as? Date,
           calendar.isDateInToday(lastClaim) {
            return
        }

        inventory.food += 1
        inventory.water += 1

        let daysSinceInstall = max(0, calendar.dateComponents([.day], from: profile.createdAt, to: Date()).day ?? 0)
        if daysSinceInstall < 7 {
            profile.coins += 10
        } else {
            profile.coins += 5
        }

        UserDefaults.standard.set(Date(), forKey: key)
        save()
    }

    // MARK: - Welcome Back Bonus

    func checkWelcomeBackBonus() {
        guard let lastInteraction = profile.lastInteractionDate else { return }
        let daysSinceInteraction = Calendar.current.dateComponents([.day], from: lastInteraction, to: Date()).day ?? 0
        if daysSinceInteraction >= 3 {
            inventory.food += 3
            inventory.water += 3
            profile.coins += 20
            profile.lastInteractionDate = Date()
            save()
        }
    }

    // MARK: - Care Need Tracking

    func scheduleCareNeed(type: CareNeedType, fireDate: Date) {
        UserDefaults.standard.set(type.rawValue, forKey: "scheduledCareNeedType")
        UserDefaults.standard.set(fireDate.timeIntervalSince1970, forKey: "scheduledCareNeedTime")
    }

    func checkAndActivateCareNeed() {
        guard activeCareNeed == nil,
              let typeRaw = UserDefaults.standard.string(forKey: "scheduledCareNeedType"),
              let type = CareNeedType(rawValue: typeRaw) else { return }

        let fireTime = UserDefaults.standard.double(forKey: "scheduledCareNeedTime")
        guard fireTime > 0, Date().timeIntervalSince1970 >= fireTime else { return }

        activeCareNeed = type
    }

    func clearCareNeed() {
        activeCareNeed = nil
        UserDefaults.standard.removeObject(forKey: "scheduledCareNeedType")
        UserDefaults.standard.removeObject(forKey: "scheduledCareNeedTime")
    }

    // MARK: - Debug
    #if DEBUG
    func loadTestData() {
        profile.xp = 850
        profile.level = 8
        profile.coins = 120
        profile.currentStreak = 5
        profile.longestStreak = 7
        profile.totalRuns = 23
        profile.totalSprints = 67
        profile.totalSprintsValid = 58
        profile.username = "testrunner"
        profile.displayName = "Test Runner"
        profile.lastRunDate = Date()

        let pet1 = OwnedPet(
            petDefinitionId: "pet_01",
            evolutionStage: 3,
            level: 14,
            experience: 5600,
            mood: 3,
            isEquipped: true,
            caughtDate: Date().addingTimeInterval(-604800)
        )
        let pet2 = OwnedPet(
            petDefinitionId: "pet_02",
            evolutionStage: 1,
            level: 1,
            experience: 80,
            mood: 2,
            caughtDate: Date().addingTimeInterval(-172800)
        )
        ownedPets = [pet1, pet2]
        profile.equippedPetId = pet1.id

        inventory = PlayerInventory(food: 5, water: 3)

        runHistory = [
            CompletedRun(durationSeconds: 1080, distanceMeters: 2200, sprintsCompleted: 3, coinsEarned: 48, xpEarned: 85),
            CompletedRun(date: Date().addingTimeInterval(-86400), durationSeconds: 900, distanceMeters: 1800, sprintsCompleted: 2, coinsEarned: 35, xpEarned: 60),
        ]

        isLoggedIn = true
        save()
    }
    #endif
}

// MARK: - Milestone Toast
struct MilestoneToast: Equatable {
    let icon: String
    let title: String
    let subtitle: String
    let color: String

    static func streakMilestone(_ days: Int) -> MilestoneToast {
        switch days {
        case 3: return MilestoneToast(icon: "flame.fill", title: "3-Day Streak!", subtitle: "You're building a habit!", color: "accent")
        case 7: return MilestoneToast(icon: "flame.fill", title: "1-Week Streak!", subtitle: "Your pet is getting attached to you!", color: "accent")
        case 14: return MilestoneToast(icon: "flame.fill", title: "2-Week Streak!", subtitle: "Incredible dedication!", color: "accent")
        case 30: return MilestoneToast(icon: "flame.fill", title: "30-Day Streak!", subtitle: "You're unstoppable!", color: "accent")
        default: return MilestoneToast(icon: "flame.fill", title: "\(days)-Day Streak!", subtitle: "Keep it going!", color: "accent")
        }
    }

    static func runMilestone(_ runs: Int) -> MilestoneToast {
        MilestoneToast(icon: "figure.run", title: "\(runs) Runs!", subtitle: "Every step counts!", color: "xp")
    }

    static let firstFeed = MilestoneToast(icon: "fork.knife", title: "First Feeding!", subtitle: "Your pet loved that!", color: "success")
    static let firstCatch = MilestoneToast(icon: "sparkles", title: "First Catch!", subtitle: "Your collection is growing!", color: "accent")
}

// MARK: - Pending Evolution
struct PendingEvolution {
    let petName: String
    let petDefinitionId: String
    let newStage: Int
    let stageName: String
    let oldImageName: String
    let newImageName: String
}

// MARK: - Saveable Data Structure
struct SaveableUserData: Codable {
    let profile: PlayerProfile
    let ownedPets: [OwnedPet]
    let inventory: PlayerInventory
    let runHistory: [CompletedRun]
}
