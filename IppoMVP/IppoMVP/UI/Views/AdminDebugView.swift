import SwiftUI

struct AdminDebugView: View {
    @EnvironmentObject var userData: UserData
    @EnvironmentObject var authService: AuthService
    @State private var feedbackMessage: String?
    @State private var showingResetConfirm = false

    // Coin/inventory fields
    @State private var coinAmount: String = "100"
    @State private var foodAmount: String = "5"
    @State private var waterAmount: String = "5"

    // Pet XP field
    @State private var petXPAmount: String = "500"
    @State private var selectedStage: Int = 1

    // Run simulator fields
    @State private var runDuration: String = "900"
    @State private var runDistance: String = "2400"
    @State private var runSprints: String = "3"
    @State private var runCoins: String = "50"
    @State private var runXP: String = "80"
    @State private var runIncludesCatch = false
    @State private var runCatchPetId: String = "pet_01"

    var body: some View {
        List {
            accountInfoSection
            stateInspectorSection
            coinsSection
            inventorySection
            petXPSection
            petManagementSection
            petCareSection
            boostsSection
            runSimulatorSection
            notificationTestSection
            onboardingSection
            dangerZoneSection
        }
        .navigationTitle("Debug Panel")
        .navigationBarTitleDisplayMode(.inline)
        .scrollContentBackground(.hidden)
        .background(AppColors.background.ignoresSafeArea())
        .overlay {
            if let msg = feedbackMessage {
                VStack {
                    Spacer()
                    Text(msg)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(AppColors.success)
                        .cornerRadius(10)
                        .padding(.bottom, 40)
                }
            }
        }
    }

    // MARK: - Account Info

    private var accountInfoSection: some View {
        Section("Account Info") {
            labelRow("Firebase UID", value: authService.userId ?? "nil")
            labelRow("Email", value: authService.email ?? "nil")
            labelRow("Display Name", value: authService.displayName ?? "nil")
            labelRow("Auth State", value: authService.isAuthenticated ? "Authenticated" : "Not Authenticated")
            labelRow("Admin", value: authService.isAdmin ? "Yes" : "No")
        }
        .listRowBackground(AppColors.surface)
    }

    // MARK: - State Inspector

    private var stateInspectorSection: some View {
        Section("Current State") {
            labelRow("Coins", value: "\(userData.profile.coins)")
            labelRow("Level", value: "\(userData.profile.level)")
            labelRow("XP", value: "\(userData.profile.xp)")
            labelRow("Streak", value: "\(userData.profile.currentStreak)")
            labelRow("Last Run Date", value: userData.profile.lastRunDate?.formatted() ?? "nil")
            labelRow("Longest Streak", value: "\(userData.profile.longestStreak)")
            labelRow("Total Runs", value: "\(userData.profile.totalRuns)")
            labelRow("Pets Owned", value: "\(userData.activePets.count)")
            labelRow("Lost Pets", value: "\(userData.lostPets.count)")
            labelRow("Food", value: "\(userData.inventory.food)")
            labelRow("Water", value: "\(userData.inventory.water)")
            if let pet = userData.equippedPet {
                labelRow("Equipped", value: pet.definition?.name ?? "?")
                labelRow("Pet Level", value: "\(pet.level)")
                labelRow("Pet Stage", value: "\(pet.evolutionStage) (\(pet.stageName))")
                labelRow("Pet XP", value: "\(pet.experience)")
                labelRow("Pet Mood", value: pet.moodName)
                labelRow("Sad Days", value: "\(pet.consecutiveSadDays)")
                labelRow("Can Feed XP", value: pet.canEarnFeedXP ? "Yes" : "No")
                labelRow("Can Water XP", value: pet.canEarnWaterXP ? "Yes" : "No")
                labelRow("Can Pet XP", value: pet.canEarnPetXP ? "Yes" : "No")
            }
            let streakDays = min(userData.profile.currentStreak, EconomyConfig.shared.streakBonusCap)
            let streakBonus = streakDays > 0
                ? (Double(streakDays) / Double(EconomyConfig.shared.streakBonusCap)) * EconomyConfig.shared.maxStreakBonusPercent * 100
                : 0
            labelRow("Streak XP Bonus", value: "+\(String(format: "%.1f", streakBonus))%")

            if userData.inventory.isHibernating {
                labelRow("Hibernating Until", value: userData.inventory.hibernationEndsAt?.formatted() ?? "?")
            }
            if userData.inventory.isStreakFrozen {
                labelRow("Streak Freeze Until", value: userData.inventory.streakFreezeEndsAt?.formatted() ?? "?")
            }
            if let boost = userData.inventory.activeXPBoost {
                labelRow("XP Boost", value: "\(Int(boost.remainingSeconds / 60))m left")
            }
            if userData.inventory.activeEncounterCharm != nil {
                labelRow("Encounter Charm", value: "Active (next run)")
            }
            if userData.inventory.activeCoinBoost != nil {
                labelRow("Golden Stride", value: "Active (next run)")
            }
        }
        .listRowBackground(AppColors.surface)
    }

    // MARK: - Coins

    private var coinsSection: some View {
        Section("Coins") {
            HStack(spacing: 8) {
                quickButton("+100") { userData.addCoins(100); showFeedback("+100 coins") }
                quickButton("+500") { userData.addCoins(500); showFeedback("+500 coins") }
                quickButton("+1K") { userData.addCoins(1000); showFeedback("+1000 coins") }
            }
            HStack {
                TextField("Amount", text: $coinAmount)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                Button("Set Coins") {
                    if let val = Int(coinAmount) {
                        userData.profile.coins = val
                        userData.save()
                        showFeedback("Coins set to \(val)")
                    }
                }
                .buttonStyle(.bordered)
            }
        }
        .listRowBackground(AppColors.surface)
    }

    // MARK: - Inventory

    private var inventorySection: some View {
        Section("Food & Water") {
            Button("Add 5 Food + 5 Water") {
                userData.inventory.food += 5
                userData.inventory.water += 5
                userData.save()
                showFeedback("+5 Food, +5 Water")
            }
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Food").font(.system(size: 13, design: .rounded)).foregroundColor(AppColors.textSecondary)
                    TextField("Food", text: $foodAmount)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Water").font(.system(size: 13, design: .rounded)).foregroundColor(AppColors.textSecondary)
                    TextField("Water", text: $waterAmount)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                }
                Button("Set") {
                    userData.inventory.food = Int(foodAmount) ?? 0
                    userData.inventory.water = Int(waterAmount) ?? 0
                    userData.save()
                    showFeedback("Food: \(userData.inventory.food), Water: \(userData.inventory.water)")
                }
                .buttonStyle(.bordered)
            }
        }
        .listRowBackground(AppColors.surface)
    }

    // MARK: - Pet XP & Evolution

    private var petXPSection: some View {
        Section("Pet XP & Evolution") {
            if let pet = userData.equippedPet, let idx = userData.ownedPets.firstIndex(where: { $0.id == pet.id }) {
                Text("\(pet.definition?.name ?? "Pet") - Lv. \(pet.level), \(pet.stageName), XP: \(pet.experience)")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)

                HStack(spacing: 8) {
                    quickButton("+100 XP") { addPetXP(idx: idx, amount: 100) }
                    quickButton("+500 XP") { addPetXP(idx: idx, amount: 500) }
                    quickButton("+1K XP") { addPetXP(idx: idx, amount: 1000) }
                }

                HStack {
                    TextField("XP Amount", text: $petXPAmount)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                    Button("Add XP") {
                        if let val = Int(petXPAmount) {
                            addPetXP(idx: idx, amount: val)
                        }
                    }
                    .buttonStyle(.bordered)
                }

                Button("+1 Level") {
                    let nextLevel = pet.level + 1
                    guard nextLevel <= PetConfig.shared.petMaxLevel else {
                        showFeedback("Already at max level")
                        return
                    }
                    let xpNeeded = PetConfig.shared.xpRequiredForLevel(nextLevel) - pet.experience
                    if xpNeeded > 0 {
                        addPetXP(idx: idx, amount: xpNeeded)
                    }
                }
                .font(.system(size: 14, weight: .medium, design: .rounded))

                Button("Force Evolution") {
                    forceEvolution(idx: idx)
                }
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.accent)

                HStack {
                    Text("Set Stage:").font(.system(size: 14, design: .rounded))
                    Picker("Stage", selection: $selectedStage) {
                        ForEach(1...PetConfig.shared.maxStages, id: \.self) { s in
                            Text("\(s) - \(PetConfig.shared.stageName(for: s))").tag(s)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: selectedStage) { _, _ in }
                    Button("Set") {
                        setPetStage(idx: idx, stage: selectedStage)
                    }
                    .buttonStyle(.bordered)
                }

                Button("Max Out Pet (Adult, Lv. \(PetConfig.shared.petMaxLevel))") {
                    let maxLevel = PetConfig.shared.petMaxLevel
                    let maxXP = PetConfig.shared.xpRequiredForLevel(maxLevel)
                    userData.ownedPets[idx].level = maxLevel
                    userData.ownedPets[idx].evolutionStage = PetConfig.shared.maxStages
                    userData.ownedPets[idx].experience = maxXP
                    userData.save()
                    showFeedback("\(pet.definition?.name ?? "Pet") maxed out!")
                }
            } else {
                Text("No equipped pet")
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .listRowBackground(AppColors.surface)
    }

    // MARK: - Pet Management

    private var petManagementSection: some View {
        Section("Pet Management") {
            ForEach(GameData.petDefinitions) { pet in
                HStack {
                    Text(pet.name)
                        .font(.system(size: 15, design: .rounded))
                        .foregroundColor(AppColors.textPrimary)
                    Spacer()
                    if userData.ownedPetDefinitionIds.contains(pet.id) {
                        if let owned = userData.ownedPets.first(where: { $0.petDefinitionId == pet.id }) {
                            if owned.isEquipped {
                                Text("Equipped")
                                    .font(.system(size: 12, design: .rounded))
                                    .foregroundColor(AppColors.accent)
                            } else {
                                Button("Equip") {
                                    userData.equipPet(owned.id)
                                    showFeedback("Equipped \(pet.name)")
                                }
                                .font(.system(size: 13, design: .rounded))
                                .buttonStyle(.bordered)
                            }
                        }
                        Text("Owned")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundColor(AppColors.success)
                    } else {
                        Button("Add") {
                            userData.addPet(definitionId: pet.id)
                            showFeedback("Added \(pet.name)")
                        }
                        .font(.system(size: 13, design: .rounded))
                        .buttonStyle(.bordered)
                    }
                }
            }
            Button("Grant ALL Pets") {
                for pet in GameData.petDefinitions {
                    if !userData.ownedPetDefinitionIds.contains(pet.id) {
                        userData.addPet(definitionId: pet.id)
                    }
                }
                showFeedback("All \(GameData.petDefinitions.count) pets granted")
            }
            Button("Remove All Pets", role: .destructive) {
                userData.ownedPets = []
                userData.profile.equippedPetId = nil
                userData.save()
                showFeedback("All pets removed")
            }
        }
        .listRowBackground(AppColors.surface)
    }

    // MARK: - Pet Care Reset

    private var petCareSection: some View {
        Section("Pet Care") {
            if let pet = userData.equippedPet, let idx = userData.ownedPets.firstIndex(where: { $0.id == pet.id }) {
                Button("Reset Care Timestamps (Feed/Water/Pet Again Today)") {
                    userData.ownedPets[idx].lastFedDate = nil
                    userData.ownedPets[idx].lastWateredDate = nil
                    userData.ownedPets[idx].lastPettedDate = nil
                    userData.save()
                    showFeedback("Care timestamps reset")
                }
                HStack(spacing: 8) {
                    quickButton("Happy") { setMood(idx: idx, mood: 3) }
                    quickButton("Content") { setMood(idx: idx, mood: 2) }
                    quickButton("Sad") { setMood(idx: idx, mood: 1) }
                }
                Button("Reset Sad Days Counter") {
                    userData.ownedPets[idx].consecutiveSadDays = 0
                    userData.save()
                    showFeedback("Sad days reset to 0")
                }
                Button("Trigger Pet Runaway") {
                    userData.ownedPets[idx].isLost = true
                    userData.ownedPets[idx].isEquipped = false
                    userData.profile.equippedPetId = nil
                    userData.save()
                    showFeedback("\(pet.definition?.name ?? "Pet") ran away!")
                }
                .foregroundColor(AppColors.danger)
            } else {
                Text("No equipped pet")
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .listRowBackground(AppColors.surface)
    }

    // MARK: - Boosts

    private var boostsSection: some View {
        Section("Boosts & Protection") {
            Button("Activate XP Boost (2hr)") {
                let boost = ActiveBoost(
                    type: .xpBoost,
                    expiresAt: Date().addingTimeInterval(TimeInterval(EconomyConfig.shared.xpBoostDurationHours * 3600))
                )
                userData.inventory.activeBoosts.append(boost)
                userData.save()
                showFeedback("XP Boost active for 2 hours")
            }
            Button("Activate Encounter Charm") {
                let boost = ActiveBoost(type: .encounterCharm, expiresAt: Date().addingTimeInterval(86400))
                userData.inventory.activeBoosts.append(boost)
                userData.save()
                showFeedback("Encounter Charm active (next run)")
            }
            Button("Activate Golden Stride") {
                let boost = ActiveBoost(type: .coinBoost, expiresAt: Date().addingTimeInterval(86400))
                userData.inventory.activeBoosts.append(boost)
                userData.save()
                showFeedback("Golden Stride active (next run)")
            }
            Button("Activate Hibernation (7 days)") {
                userData.inventory.hibernationEndsAt = Date().addingTimeInterval(TimeInterval(EconomyConfig.shared.hibernationDays * 86400))
                userData.save()
                showFeedback("Hibernation active for 7 days")
            }
            Button("Activate Streak Shield (3 days)") {
                if let existing = userData.inventory.streakFreezeEndsAt, Date() < existing {
                    userData.inventory.streakFreezeEndsAt = existing.addingTimeInterval(TimeInterval(EconomyConfig.shared.streakFreezeDays * 86400))
                } else {
                    userData.inventory.streakFreezeEndsAt = Date().addingTimeInterval(TimeInterval(EconomyConfig.shared.streakFreezeDays * 86400))
                }
                userData.save()
                showFeedback("Streak Shield active for 3 days")
            }
            Button("Set Streak to 30") {
                userData.profile.currentStreak = 30
                userData.profile.longestStreak = max(userData.profile.longestStreak, 30)
                userData.save()
                showFeedback("Streak set to 30 (+10% XP)")
            }
            Button("Clear All Boosts & Protection") {
                userData.inventory.activeBoosts.removeAll()
                userData.inventory.hibernationEndsAt = nil
                userData.inventory.streakFreezeEndsAt = nil
                userData.save()
                showFeedback("All boosts & protection cleared")
            }
        }
        .listRowBackground(AppColors.surface)
    }

    // MARK: - Run Simulator

    private var runSimulatorSection: some View {
        Section("Simulate Run") {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Duration (s)").font(.system(size: 11, design: .rounded)).foregroundColor(AppColors.textSecondary)
                    TextField("900", text: $runDuration).keyboardType(.numberPad).textFieldStyle(.roundedBorder)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Distance (m)").font(.system(size: 11, design: .rounded)).foregroundColor(AppColors.textSecondary)
                    TextField("2400", text: $runDistance).keyboardType(.numberPad).textFieldStyle(.roundedBorder)
                }
            }
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Sprints").font(.system(size: 11, design: .rounded)).foregroundColor(AppColors.textSecondary)
                    TextField("3", text: $runSprints).keyboardType(.numberPad).textFieldStyle(.roundedBorder)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Coins").font(.system(size: 11, design: .rounded)).foregroundColor(AppColors.textSecondary)
                    TextField("50", text: $runCoins).keyboardType(.numberPad).textFieldStyle(.roundedBorder)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("XP").font(.system(size: 11, design: .rounded)).foregroundColor(AppColors.textSecondary)
                    TextField("80", text: $runXP).keyboardType(.numberPad).textFieldStyle(.roundedBorder)
                }
            }

            Toggle("Include Pet Catch", isOn: $runIncludesCatch)
            if runIncludesCatch {
                Picker("Catch Pet", selection: $runCatchPetId) {
                    ForEach(GameData.petDefinitions) { pet in
                        Text(pet.name).tag(pet.id)
                    }
                }
            }

            Button("Submit Simulated Run") {
                let catchId: String? = runIncludesCatch ? runCatchPetId : nil

                if let catchId, !userData.ownedPetDefinitionIds.contains(catchId) {
                    userData.addPet(definitionId: catchId)
                }

                let run = CompletedRun(
                    durationSeconds: Int(runDuration) ?? 900,
                    distanceMeters: Double(runDistance) ?? 2400,
                    sprintsCompleted: Int(runSprints) ?? 3,
                    coinsEarned: Int(runCoins) ?? 50,
                    xpEarned: Int(runXP) ?? 80,
                    petCaughtId: catchId
                )
                userData.completeRun(run)
                userData.pendingRunSummary = run
                showFeedback("Run submitted! Go to Home tab to see summary.")
            }
            .font(.system(size: 15, weight: .semibold, design: .rounded))
            .foregroundColor(AppColors.accent)
        }
        .listRowBackground(AppColors.surface)
    }

    // MARK: - Notification Testing

    private var notificationTestSection: some View {
        Section("Test Notifications") {
            let petName = userData.equippedPet?.definition?.name ?? "Your pet"

            Button("Care Notification (Hungry/Thirsty)") {
                NotificationSystem.shared.triggerCareNotificationNow(petName: petName)
                showFeedback("Care notification sent in 2s — mood updated to \(userData.activeCareNeed?.displayText ?? "hungry/thirsty")")
            }

            Button("Run Reminder") {
                NotificationSystem.shared.triggerRunReminderNow(petName: petName)
                showFeedback("Run reminder sent in 2s")
            }

            Button("Runaway Warning (7 days)") {
                NotificationSystem.shared.triggerRunawayWarningNow(petName: petName, daysUntilRunaway: 7)
                showFeedback("7-day runaway warning sent in 2s")
            }

            Button("Runaway Warning (4 days)") {
                NotificationSystem.shared.triggerRunawayWarningNow(petName: petName, daysUntilRunaway: 4)
                showFeedback("4-day runaway warning sent in 2s")
            }

            Button("Runaway Warning (2 days)") {
                NotificationSystem.shared.triggerRunawayWarningNow(petName: petName, daysUntilRunaway: 2)
                showFeedback("2-day runaway warning sent in 2s")
            }

            Button("Pet Ran Away") {
                NotificationSystem.shared.triggerPetRanAwayNow(petName: petName)
                showFeedback("Pet ran away notification sent in 2s")
            }

            Button("Clear Active Care Need") {
                userData.clearCareNeed()
                showFeedback("Care need cleared")
            }
            .foregroundColor(AppColors.textSecondary)
        }
        .listRowBackground(AppColors.surface)
    }

    // MARK: - Onboarding

    private var onboardingSection: some View {
        Section("Onboarding") {
            Button("Replay Onboarding (stay signed in)") {
                UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
                showFeedback("Onboarding will show on next app launch or state refresh")
            }
        }
        .listRowBackground(AppColors.surface)
    }

    // MARK: - Danger Zone

    private var dangerZoneSection: some View {
        Section("Danger Zone") {
            Button("Reset All Data", role: .destructive) {
                showingResetConfirm = true
            }
            Button("Sign Out", role: .destructive) {
                authService.signOut()
            }
        }
        .listRowBackground(AppColors.surface)
        .alert("Reset Everything?", isPresented: $showingResetConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                userData.logout()
                showFeedback("All data cleared")
            }
        }
    }

    // MARK: - Helpers

    private func addPetXP(idx: Int, amount: Int) {
        let config = PetConfig.shared
        let oldStage = userData.ownedPets[idx].evolutionStage
        let oldImageName = userData.ownedPets[idx].currentImageName
        userData.ownedPets[idx].experience += amount

        let newLevel = config.levelForXP(userData.ownedPets[idx].experience)
        userData.ownedPets[idx].level = newLevel
        let newStage = config.stageForLevel(newLevel)
        userData.ownedPets[idx].evolutionStage = newStage
        userData.save()

        if newStage > oldStage, let def = userData.ownedPets[idx].definition {
            userData.pendingEvolution = PendingEvolution(
                petName: def.name,
                petDefinitionId: def.id,
                newStage: newStage,
                stageName: config.stageName(for: newStage),
                oldImageName: oldImageName,
                newImageName: def.stageImageNames[safe: newStage - 1] ?? oldImageName
            )
            showFeedback("+\(amount) XP -> Evolved to \(config.stageName(for: newStage))! (Lv. \(newLevel))")
        } else {
            showFeedback("+\(amount) XP (Lv. \(newLevel))")
        }
    }

    private func forceEvolution(idx: Int) {
        let config = PetConfig.shared
        let currentStage = userData.ownedPets[idx].evolutionStage
        guard currentStage < config.maxStages else {
            showFeedback("Already at max stage")
            return
        }
        let nextStage = currentStage + 1
        guard let triggerLevel = config.evolutionLevels[nextStage] else {
            showFeedback("No evolution level for stage \(nextStage)")
            return
        }
        let xpNeeded = config.xpRequiredForLevel(triggerLevel) - userData.ownedPets[idx].experience
        if xpNeeded > 0 {
            addPetXP(idx: idx, amount: xpNeeded)
        } else {
            addPetXP(idx: idx, amount: 1)
        }
    }

    private func setPetStage(idx: Int, stage: Int) {
        let config = PetConfig.shared
        guard let triggerLevel = config.evolutionLevels[stage] ?? (stage == 1 ? 1 : nil) else { return }
        let xp = config.xpRequiredForLevel(triggerLevel)
        userData.ownedPets[idx].level = triggerLevel
        userData.ownedPets[idx].evolutionStage = stage
        userData.ownedPets[idx].experience = xp
        userData.save()
        showFeedback("Set to \(config.stageName(for: stage)) (Lv. \(triggerLevel))")
    }

    private func setMood(idx: Int, mood: Int) {
        userData.ownedPets[idx].mood = mood
        userData.save()
        let name = mood == 3 ? "Happy" : mood == 2 ? "Content" : "Sad"
        showFeedback("Mood set to \(name)")
    }

    private func quickButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .font(.system(size: 13, weight: .medium, design: .rounded))
            .buttonStyle(.bordered)
    }

    private func labelRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(AppColors.textPrimary)
            Spacer()
            Text(value)
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }

    private func showFeedback(_ msg: String) {
        feedbackMessage = msg
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            feedbackMessage = nil
        }
    }
}
