import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var userData: UserData
    @State private var showingSettings = false
    @State private var showingRunHistory = false
    @State private var showingAllAchievements = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Profile Header
                    profileHeader
                    
                    // Stats Grid
                    statsGrid
                    
                    // Reputation Points
                    rpSection
                    
                    // Level & XP Progress
                    levelSection
                    
                    // Achievements
                    achievementsSection
                    
                    // Items Snapshot
                    itemsSection
                    
                    // Recent Runs
                    recentRunsSection
                    
                    // Quick Settings
                    quickSettings
                }
                .padding(.horizontal, AppSpacing.screenPadding)
                .padding(.bottom, AppSpacing.xxl)
            }
            .background(AppColors.background)
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsSheet()
            }
            .sheet(isPresented: $showingRunHistory) {
                RunHistorySheet()
            }
            .sheet(isPresented: $showingAllAchievements) {
                AllAchievementsSheet()
            }
            .onAppear {
                AchievementsSystem.shared.initializeIfNeeded()
                AchievementsSystem.shared.updateAllProgress()
            }
        }
    }
    
    // MARK: - Profile Header
    private var profileHeader: some View {
        VStack(spacing: AppSpacing.md) {
            // Avatar
            ZStack {
                Circle()
                    .fill(AppColors.brandPrimary.opacity(0.2))
                    .frame(width: 80, height: 80)
                
                Text(String(userData.profile.displayName.prefix(2)).uppercased())
                    .font(AppTypography.title2)
                    .foregroundColor(AppColors.brandPrimary)
            }
            
            // Name & Level
            VStack(spacing: AppSpacing.xxs) {
                Text(userData.profile.displayName)
                    .font(AppTypography.title2)
                    .foregroundColor(AppColors.textPrimary)
                
                HStack(spacing: AppSpacing.sm) {
                    Text("Level \(userData.profile.level)")
                        .font(AppTypography.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                    
                    Text("\u{2022}")
                        .foregroundColor(AppColors.textTertiary)
                    
                    HStack(spacing: AppSpacing.xxs) {
                        Image(systemName: userData.profile.rank.iconName)
                            .foregroundColor(AppColors.brandPrimary)
                        Text(userData.profile.rank.displayName)
                            .foregroundColor(AppColors.brandPrimary)
                    }
                    .font(AppTypography.subheadline)
                }
                
                // Streak
                if userData.profile.currentStreak > 0 {
                    HStack(spacing: AppSpacing.xxs) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(AppColors.warning)
                        Text("\(userData.profile.currentStreak) day streak")
                            .foregroundColor(AppColors.warning)
                    }
                    .font(AppTypography.caption1)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.lg)
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.radiusMd)
    }
    
    // MARK: - Stats Grid
    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.md) {
            statCard("Runs", value: "\(userData.profile.totalRuns)", icon: "figure.run")
            statCard("Sprints", value: "\(userData.profile.totalSprintsValid)", icon: "bolt.fill")
            statCard("Pets", value: "\(userData.ownedPets.count)/10", icon: "pawprint.fill")
            statCard("RP", value: "\(userData.profile.rp)", icon: "star.fill")
        }
    }
    
    private func statCard(_ title: String, value: String, icon: String) -> some View {
        VStack(spacing: AppSpacing.xs) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(AppColors.brandPrimary)
            
            Text(value)
                .font(AppTypography.title3)
                .foregroundColor(AppColors.textPrimary)
            
            Text(title)
                .font(AppTypography.caption1)
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.md)
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.radiusMd)
    }
    
    // MARK: - RP Section
    private var rpSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Text("Reputation Points")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                Text("\(userData.profile.rp) RP")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.brandPrimary)
            }
            
            if let nextRank = userData.profile.rank.nextRank {
                ProgressView(value: userData.profile.rpProgressInRank)
                    .tint(AppColors.brandPrimary)
                
                HStack {
                    Text(userData.profile.rank.displayName)
                        .font(AppTypography.caption2)
                        .foregroundColor(AppColors.textTertiary)
                    Spacer()
                    if let rpNeeded = userData.profile.rpToNextRank {
                        Text("\(rpNeeded) RP to \(nextRank.displayName)")
                            .font(AppTypography.caption2)
                            .foregroundColor(AppColors.textTertiary)
                    }
                }
            }
        }
        .cardStyle()
    }
    
    // MARK: - Level Section
    private var levelSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Level Progress")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textPrimary)
            
            HStack(spacing: AppSpacing.lg) {
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: "star.circle.fill")
                        .foregroundColor(AppColors.brandPrimary)
                        .font(.title2)
                    VStack(alignment: .leading, spacing: 0) {
                        Text("\(userData.abilities.abilityPoints)")
                            .font(AppTypography.headline)
                            .foregroundColor(AppColors.textPrimary)
                        Text("Ability Points")
                            .font(AppTypography.caption2)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: "pawprint.circle.fill")
                        .foregroundColor(AppColors.gems)
                        .font(.title2)
                    VStack(alignment: .leading, spacing: 0) {
                        Text("\(userData.abilities.petPoints)")
                            .font(AppTypography.headline)
                            .foregroundColor(AppColors.textPrimary)
                        Text("Pet Points")
                            .font(AppTypography.caption2)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // XP Progress
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                HStack {
                    Text("Level \(userData.profile.level)")
                        .font(AppTypography.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                    Spacer()
                    Text("\(userData.profile.xp) / \(userData.profile.xpForNextLevel) XP")
                        .font(AppTypography.caption1)
                        .foregroundColor(AppColors.textTertiary)
                }
                
                ProgressView(value: userData.profile.xpProgress)
                    .tint(AppColors.brandPrimary)
            }
        }
        .cardStyle()
    }
    
    // MARK: - Achievements Section
    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Text("Achievements")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                Button("See All") {
                    showingAllAchievements = true
                }
                .font(AppTypography.caption1)
                .foregroundColor(AppColors.brandPrimary)
            }
            
            let completed = userData.achievements.filter { $0.isCompleted }
            let total = userData.achievements.count
            
            HStack {
                Text("\(completed.count)/\(total) completed")
                    .font(AppTypography.caption1)
                    .foregroundColor(AppColors.textSecondary)
                Spacer()
                ProgressView(value: total > 0 ? Double(completed.count) / Double(total) : 0)
                    .tint(AppColors.success)
                    .frame(width: 100)
            }
            
            // Show last 3 achievements (in progress or recently completed)
            let display = userData.achievements
                .sorted { a, b in
                    if a.isCompleted != b.isCompleted { return a.isCompleted }
                    return a.progressFraction > b.progressFraction
                }
                .prefix(3)
            
            ForEach(Array(display)) { achievement in
                achievementRow(achievement)
            }
        }
        .cardStyle()
    }
    
    private func achievementRow(_ achievement: Achievement) -> some View {
        HStack(spacing: AppSpacing.md) {
            ZStack {
                Circle()
                    .fill(achievement.isCompleted ? AppColors.success.opacity(0.2) : AppColors.surfaceElevated)
                    .frame(width: 36, height: 36)
                Image(systemName: achievement.isCompleted ? "checkmark" : achievement.iconName)
                    .font(.caption)
                    .foregroundColor(achievement.isCompleted ? AppColors.success : AppColors.textTertiary)
            }
            
            VStack(alignment: .leading, spacing: AppSpacing.xxxs) {
                Text(achievement.name)
                    .font(AppTypography.subheadline)
                    .foregroundColor(achievement.isCompleted ? AppColors.textPrimary : AppColors.textSecondary)
                Text(achievement.description)
                    .font(AppTypography.caption2)
                    .foregroundColor(AppColors.textTertiary)
            }
            
            Spacer()
            
            if achievement.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(AppColors.success)
                    .font(.caption)
            } else {
                Text("\(achievement.progress)/\(achievement.requirement)")
                    .font(AppTypography.caption2)
                    .foregroundColor(AppColors.textTertiary)
            }
        }
        .padding(.vertical, AppSpacing.xxs)
    }
    
    // MARK: - Items Section
    private var itemsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Items")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textPrimary)
            
            HStack(spacing: AppSpacing.md) {
                // Loot Boxes
                itemBadge(
                    icon: "gift.fill",
                    color: AppColors.rarityRare,
                    count: userData.inventory.totalLootBoxes,
                    label: "Loot Boxes"
                )
                
                // Pet Food
                itemBadge(
                    icon: "leaf.fill",
                    color: AppColors.success,
                    count: userData.inventory.petFood,
                    label: "Pet Food"
                )
                
                // XP Boosts
                itemBadge(
                    icon: "bolt.fill",
                    color: AppColors.warning,
                    count: userData.inventory.xpBoosts,
                    label: "XP Boosts"
                )
            }
        }
        .cardStyle()
    }
    
    private func itemBadge(icon: String, color: Color, count: Int, label: String) -> some View {
        VStack(spacing: AppSpacing.xs) {
            ZStack {
                RoundedRectangle(cornerRadius: AppSpacing.radiusSm)
                    .fill(color.opacity(0.15))
                    .frame(height: 50)
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
            }
            Text("\(count)")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textPrimary)
            Text(label)
                .font(AppTypography.caption2)
                .foregroundColor(AppColors.textSecondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Recent Runs Section
    private var recentRunsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Text("Run History")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                Button("See All") {
                    showingRunHistory = true
                }
                .font(AppTypography.caption1)
                .foregroundColor(AppColors.brandPrimary)
            }
            
            if userData.runHistory.isEmpty {
                Text("No runs yet")
                    .font(AppTypography.subheadline)
                    .foregroundColor(AppColors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.lg)
            } else {
                ForEach(userData.runHistory.prefix(3)) { run in
                    runRow(run)
                    
                    if run.id != userData.runHistory.prefix(3).last?.id {
                        Divider()
                            .background(AppColors.surfaceElevated)
                    }
                }
            }
        }
        .cardStyle()
    }
    
    private func runRow(_ run: CompletedRun) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(run.date.formatted(date: .abbreviated, time: .shortened))
                    .font(AppTypography.subheadline)
                    .foregroundColor(AppColors.textPrimary)
                Text("\(run.formattedDuration) \u{2022} \(run.sprintsCompleted) sprints")
                    .font(AppTypography.caption1)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: AppSpacing.xxs) {
                Text("+\(run.rpEarned) RP")
                    .font(AppTypography.callout)
                    .foregroundColor(AppColors.success)
                
                if let pet = run.petCaught {
                    HStack(spacing: AppSpacing.xxxs) {
                        Image(systemName: "sparkles")
                        Text("Pet!")
                    }
                    .font(AppTypography.caption2)
                    .foregroundColor(AppColors.brandPrimary)
                }
            }
        }
        .padding(.vertical, AppSpacing.xs)
    }
    
    // MARK: - Quick Settings
    private var quickSettings: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Settings")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textPrimary)
            
            settingsRow("Health Permissions", icon: "heart.fill")
            settingsRow("Privacy", icon: "lock.fill")
            settingsRow("Help & Support", icon: "questionmark.circle.fill")
        }
        .cardStyle()
    }
    
    private func settingsRow(_ title: String, icon: String) -> some View {
        Button {
            // Navigate to settings
        } label: {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(AppColors.textSecondary)
                    .frame(width: 24)
                
                Text(title)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(AppColors.textTertiary)
            }
            .padding(.vertical, AppSpacing.sm)
        }
    }
}

// MARK: - Settings Sheet
struct SettingsSheet: View {
    @EnvironmentObject var userData: UserData
    @Environment(\.dismiss) var dismiss
    @State private var displayName: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Profile") {
                    TextField("Display Name", text: $displayName)
                        .onAppear {
                            displayName = userData.profile.displayName
                        }
                }
                
                Section("App") {
                    Button("Request Health Permissions") {
                        // Would request HealthKit permissions
                    }
                }
                
                Section("Debug") {
                    #if DEBUG
                    Button("Load Test Data") {
                        userData.loadTestData()
                    }
                    
                    Button("Reset All Data") {
                        userData.logout()
                    }
                    .foregroundColor(AppColors.danger)
                    #endif
                }
                
                Section("Account") {
                    Button("Sign Out") {
                        userData.logout()
                        dismiss()
                    }
                    .foregroundColor(AppColors.danger)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        userData.profile.displayName = displayName
                        userData.save()
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Run History Sheet
struct RunHistorySheet: View {
    @EnvironmentObject var userData: UserData
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                if userData.runHistory.isEmpty {
                    Text("No runs yet")
                        .foregroundColor(AppColors.textSecondary)
                } else {
                    ForEach(userData.runHistory) { run in
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            HStack {
                                Text(run.date.formatted(date: .abbreviated, time: .shortened))
                                    .font(AppTypography.headline)
                                Spacer()
                                Text("+\(run.rpEarned) RP")
                                    .foregroundColor(AppColors.success)
                            }
                            
                            HStack(spacing: AppSpacing.md) {
                                Label(run.formattedDuration, systemImage: "clock")
                                Label("\(run.sprintsCompleted)/\(run.sprintsTotal)", systemImage: "bolt.fill")
                                Label("+\(run.coinsEarned)", systemImage: "dollarsign.circle.fill")
                            }
                            .font(AppTypography.caption1)
                            .foregroundColor(AppColors.textSecondary)
                            
                            if let pet = run.petCaught,
                               let def = GameData.shared.pet(byId: pet) {
                                HStack {
                                    Image(systemName: "sparkles")
                                    Text("Caught \(def.name)!")
                                }
                                .font(AppTypography.caption1)
                                .foregroundColor(AppColors.brandPrimary)
                            }
                        }
                        .padding(.vertical, AppSpacing.xs)
                    }
                }
            }
            .navigationTitle("Run History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - All Achievements Sheet
struct AllAchievementsSheet: View {
    @EnvironmentObject var userData: UserData
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(AchievementCategory.allCases, id: \.self) { category in
                    let categoryAchievements = userData.achievements.filter { $0.category == category }
                    
                    if !categoryAchievements.isEmpty {
                        Section(category.displayName) {
                            ForEach(categoryAchievements) { achievement in
                                HStack(spacing: AppSpacing.md) {
                                    ZStack {
                                        Circle()
                                            .fill(achievement.isCompleted ? AppColors.success.opacity(0.2) : AppColors.surfaceElevated)
                                            .frame(width: 40, height: 40)
                                        Image(systemName: achievement.isCompleted ? "checkmark" : achievement.iconName)
                                            .foregroundColor(achievement.isCompleted ? AppColors.success : AppColors.textTertiary)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: AppSpacing.xxxs) {
                                        Text(achievement.name)
                                            .font(AppTypography.subheadline)
                                            .foregroundColor(AppColors.textPrimary)
                                        Text(achievement.description)
                                            .font(AppTypography.caption1)
                                            .foregroundColor(AppColors.textSecondary)
                                        
                                        if !achievement.isCompleted {
                                            ProgressView(value: achievement.progressFraction)
                                                .tint(AppColors.brandPrimary)
                                            Text("\(achievement.progress)/\(achievement.requirement)")
                                                .font(AppTypography.caption2)
                                                .foregroundColor(AppColors.textTertiary)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    if achievement.isCompleted {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(AppColors.success)
                                    }
                                }
                                .padding(.vertical, AppSpacing.xxs)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Achievements")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(UserData.shared)
}
