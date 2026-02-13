import SwiftUI

struct HomeView: View {
    @EnvironmentObject var userData: UserData
    @StateObject private var rpBoxSystem = RPBoxSystem.shared
    @State private var showingRunPrompt = false
    @State private var showingRPBoxOpen = false
    @State private var lastOpenedContents: RPBoxContents?
    @State private var showingSettings = false
    @State private var showingRunHistory = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Profile Header
                    profileHeader
                    
                    // Start Run CTA
                    startRunSection
                    
                    // RP Boxes Section
                    if userData.totalRPBoxes > 0 {
                        rpBoxSection
                    }
                    
                    // Stats Grid
                    statsGrid
                    
                    // Level Progress
                    levelSection
                    
                    // RP / Rank Progress
                    rpSection
                    
                    // Recent Runs
                    recentRunsSection
                    
                    // Quick Settings
                    quickSettings
                }
                .padding(.horizontal, AppSpacing.screenPadding)
                .padding(.bottom, AppSpacing.xxl)
            }
            .background(AppColors.background)
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.large)
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
            
            // Name & Rank Tier
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
                        Text(userData.profile.rankTier.displayName)
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
    
    // MARK: - Start Run Section
    private var startRunSection: some View {
        Button {
            showingRunPrompt = true
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text("Start Run on Watch")
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.textPrimary)
                    Text("Sprint. Earn RP Boxes. Rise in rank.")
                        .font(AppTypography.caption1)
                        .foregroundColor(AppColors.textSecondary)
                }
                Spacer()
                Image(systemName: "applewatch")
                    .font(.largeTitle)
                    .foregroundColor(AppColors.brandPrimary)
            }
            .padding(AppSpacing.lg)
            .background(
                LinearGradient(
                    colors: [AppColors.brandPrimary.opacity(0.2), AppColors.surface],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(AppSpacing.radiusMd)
            .overlay(
                RoundedRectangle(cornerRadius: AppSpacing.radiusMd)
                    .stroke(AppColors.brandPrimary.opacity(0.3), lineWidth: 1)
            )
        }
        .alert("Start Run", isPresented: $showingRunPrompt) {
            Button("OK") {}
        } message: {
            Text("Open the Ippo app on your Apple Watch to start a run.")
        }
    }
    
    // MARK: - RP Box Section
    private var rpBoxSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Text("RP Boxes")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                Text("\(userData.totalRPBoxes) available")
                    .font(AppTypography.caption1)
                    .foregroundColor(AppColors.brandPrimary)
            }
            
            // Open Box Button
            Button {
                Task {
                    if let contents = await rpBoxSystem.openRPBox() {
                        lastOpenedContents = contents
                        showingRPBoxOpen = true
                        HapticsManager.shared.playSuccess()
                    }
                }
            } label: {
                HStack(spacing: AppSpacing.md) {
                    Image(systemName: "gift.fill")
                        .font(.title)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AppColors.brandPrimary, Color.purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    VStack(alignment: .leading, spacing: AppSpacing.xxxs) {
                        Text(rpBoxSystem.isOpening ? "Opening..." : "Open RP Box")
                            .font(AppTypography.headline)
                            .foregroundColor(AppColors.textPrimary)
                        Text("1-25 Reputation Points inside")
                            .font(AppTypography.caption1)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    
                    Spacer()
                    
                    if rpBoxSystem.isOpening {
                        ProgressView()
                            .tint(AppColors.brandPrimary)
                    } else {
                        Image(systemName: "chevron.right")
                            .foregroundColor(AppColors.textTertiary)
                    }
                }
                .padding(AppSpacing.cardPadding)
                .background(AppColors.brandPrimary.opacity(0.08))
                .cornerRadius(AppSpacing.radiusMd)
                .overlay(
                    RoundedRectangle(cornerRadius: AppSpacing.radiusMd)
                        .stroke(AppColors.brandPrimary.opacity(0.3), lineWidth: 1)
                )
            }
            .disabled(rpBoxSystem.isOpening || userData.totalRPBoxes == 0)
            
            // Show last opened result
            if showingRPBoxOpen, let contents = lastOpenedContents {
                rpBoxResultView(contents)
            }
        }
        .cardStyle()
    }
    
    private func rpBoxResultView(_ contents: RPBoxContents) -> some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: "sparkles")
                .font(.title2)
                .foregroundColor(tierColor(contents.tier))
            
            VStack(alignment: .leading, spacing: AppSpacing.xxxs) {
                Text("+\(contents.rpAmount) RP")
                    .font(AppTypography.headline)
                    .foregroundColor(tierColor(contents.tier))
                Text(contents.tier.displayName)
                    .font(AppTypography.caption2)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Spacer()
            
            Button {
                showingRPBoxOpen = false
                lastOpenedContents = nil
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(AppColors.textTertiary)
            }
        }
        .padding(AppSpacing.sm)
        .background(tierColor(contents.tier).opacity(0.1))
        .cornerRadius(AppSpacing.radiusSm)
    }
    
    private func tierColor(_ tier: RPBoxTier) -> Color {
        switch tier {
        case .common: return AppColors.textSecondary
        case .uncommon: return .green
        case .rare: return .blue
        case .epic: return .purple
        case .legendary: return .orange
        }
    }
    
    // MARK: - Stats Grid
    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.md) {
            statCard("Runs", value: "\(userData.profile.totalRuns)", icon: "figure.run")
            statCard("Sprints", value: "\(userData.profile.totalSprintsValid)", icon: "bolt.fill")
            statCard("RP", value: "\(userData.profile.rp)", icon: "star.fill")
            statCard("Streak", value: "\(userData.profile.currentStreak)d", icon: "flame.fill")
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
    
    // MARK: - Level Section
    private var levelSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Level Progress")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textPrimary)
            
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
                
                Text("1 XP per minute of running")
                    .font(AppTypography.caption2)
                    .foregroundColor(AppColors.textTertiary)
            }
        }
        .cardStyle()
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
            
            // Rank tier display
            HStack {
                Image(systemName: userData.profile.rank.iconName)
                    .foregroundColor(AppColors.brandPrimary)
                Text(userData.profile.rankTier.displayName)
                    .font(AppTypography.subheadline)
                    .foregroundColor(AppColors.brandPrimary)
            }
            
            if let nextRank = userData.profile.rank.nextRank {
                ProgressView(value: userData.profile.rpProgressInRank)
                    .tint(AppColors.brandPrimary)
                
                if let rpNeeded = userData.profile.rpToNextRank {
                    Text("\(rpNeeded) RP to \(nextRank.displayName)")
                        .font(AppTypography.caption2)
                        .foregroundColor(AppColors.textTertiary)
                }
            }
            
            // Weekly RP
            HStack {
                Text("This week")
                    .font(AppTypography.caption1)
                    .foregroundColor(AppColors.textSecondary)
                Spacer()
                Text("+\(userData.profile.weeklyRP) RP")
                    .font(AppTypography.caption1)
                    .foregroundColor(AppColors.success)
            }
        }
        .cardStyle()
    }
    
    // MARK: - Recent Runs
    private var recentRunsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Text("Recent Runs")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                if !userData.runHistory.isEmpty {
                    Button("See All") {
                        showingRunHistory = true
                    }
                    .font(AppTypography.caption1)
                    .foregroundColor(AppColors.brandPrimary)
                }
            }
            
            if userData.runHistory.isEmpty {
                Text("No runs yet. Start your first run!")
                    .font(AppTypography.subheadline)
                    .foregroundColor(AppColors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.lg)
            } else {
                ForEach(userData.runHistory.prefix(3)) { run in
                    HStack {
                        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                            Text(run.date, style: .relative)
                                .font(AppTypography.subheadline)
                                .foregroundColor(AppColors.textPrimary)
                            Text("\(run.formattedDuration) \u{2022} \(run.sprintsCompleted)/\(run.sprintsTotal) sprints")
                                .font(AppTypography.caption1)
                                .foregroundColor(AppColors.textSecondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: AppSpacing.xxs) {
                            Text("\(run.rpBoxesEarned) boxes")
                                .font(AppTypography.callout)
                                .foregroundColor(AppColors.brandPrimary)
                            Text("+\(run.xpEarned) XP")
                                .font(AppTypography.caption2)
                                .foregroundColor(AppColors.success)
                        }
                    }
                    .padding(.vertical, AppSpacing.xs)
                    
                    if run.id != userData.runHistory.prefix(3).last?.id {
                        Divider()
                            .background(AppColors.surfaceElevated)
                    }
                }
            }
        }
        .cardStyle()
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
    @State private var username: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Profile") {
                    TextField("Display Name", text: $displayName)
                        .onAppear {
                            displayName = userData.profile.displayName
                            username = userData.profile.username
                        }
                    TextField("Username", text: $username)
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
                        userData.profile.username = username
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
                                Text("\(run.rpBoxesEarned) RP Boxes")
                                    .foregroundColor(AppColors.brandPrimary)
                            }
                            
                            HStack(spacing: AppSpacing.md) {
                                Label(run.formattedDuration, systemImage: "clock")
                                Label("\(run.sprintsCompleted)/\(run.sprintsTotal)", systemImage: "bolt.fill")
                                Label("+\(run.xpEarned) XP", systemImage: "arrow.up.circle.fill")
                            }
                            .font(AppTypography.caption1)
                            .foregroundColor(AppColors.textSecondary)
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

#Preview {
    HomeView()
        .environmentObject(UserData.shared)
}
