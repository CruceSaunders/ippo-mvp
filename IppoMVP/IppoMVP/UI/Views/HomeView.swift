import SwiftUI
import HealthKit
import UserNotifications

struct HomeView: View {
    @EnvironmentObject var userData: UserData
    @State private var showingRunPrompt = false
    @State private var showingRPBoxOpen = false
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
                    rpBoxSection
                    
                    // Stats Grid
                    statsGrid
                    
                    // Level Progress
                    levelSection
                    
                    // RP / Rank Progress
                    rpSection
                    
                    // Recent Runs
                    recentRunsSection
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
            
            // Open Box Button -- launches full-screen opening experience
            Button {
                showingRPBoxOpen = true
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
                        Text("Open RP Box")
                            .font(AppTypography.headline)
                            .foregroundColor(AppColors.textPrimary)
                        Text("1-25 Reputation Points inside")
                            .font(AppTypography.caption1)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(AppColors.textTertiary)
                }
                .padding(AppSpacing.cardPadding)
                .background(AppColors.brandPrimary.opacity(0.08))
                .cornerRadius(AppSpacing.radiusMd)
                .overlay(
                    RoundedRectangle(cornerRadius: AppSpacing.radiusMd)
                        .stroke(AppColors.brandPrimary.opacity(0.3), lineWidth: 1)
                )
            }
            .disabled(userData.totalRPBoxes == 0)
        }
        .cardStyle()
        .fullScreenCover(isPresented: $showingRPBoxOpen) {
            RPBoxOpenView()
                .environmentObject(userData)
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
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        HStack {
                            Text(run.date.formatted(.relative(presentation: .named)))
                                .font(AppTypography.subheadline)
                                .foregroundColor(AppColors.textPrimary)
                            Spacer()
                            Text("\(run.rpBoxesEarned) boxes")
                                .font(AppTypography.caption1)
                                .foregroundColor(AppColors.brandPrimary)
                        }
                        
                        // Metrics row
                        HStack(spacing: AppSpacing.md) {
                            Label(run.formattedDuration, systemImage: "clock")
                            Label(run.formattedDistance, systemImage: "figure.run")
                            if run.averageHR > 0 {
                                Label("\(run.averageHR)", systemImage: "heart.fill")
                            }
                        }
                        .font(AppTypography.caption1)
                        .foregroundColor(AppColors.textSecondary)
                        
                        HStack(spacing: AppSpacing.md) {
                            Label(run.formattedPace, systemImage: "gauge.medium")
                            Label("\(run.sprintsCompleted)/\(run.sprintsTotal) sprints", systemImage: "bolt.fill")
                            if run.totalCalories > 0 {
                                Label(run.formattedCalories, systemImage: "flame.fill")
                            }
                        }
                        .font(AppTypography.caption2)
                        .foregroundColor(AppColors.textTertiary)
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
    
}

// MARK: - Settings Sheet
struct SettingsSheet: View {
    @EnvironmentObject var userData: UserData
    @Environment(\.dismiss) var dismiss
    @State private var displayName: String = ""
    @State private var username: String = ""
    @State private var usernameError: String?
    @State private var showingSignOutConfirm = false
    @State private var showingDeleteConfirm = false
    @State private var showingDebugPanel = false
    @State private var isCheckingUsername = false
    
    private var isUsernameValid: Bool {
        let trimmed = username.trimmingCharacters(in: .whitespaces)
        guard trimmed.count >= 3, trimmed.count <= 20 else { return false }
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_"))
        return trimmed.unicodeScalars.allSatisfy { allowed.contains($0) }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Profile") {
                    TextField("Display Name", text: $displayName)
                        .onAppear {
                            displayName = userData.profile.displayName
                            username = userData.profile.username
                        }
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Username", text: $username)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .onChange(of: username) { _ in usernameError = nil }
                        if let error = usernameError {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(AppColors.danger)
                        } else if !username.isEmpty && !isUsernameValid {
                            Text("3-20 chars, letters/numbers/underscores")
                                .font(.caption)
                                .foregroundColor(AppColors.warning)
                        }
                    }
                    
                    if let email = AuthService.shared.email {
                        HStack {
                            Text("Email")
                                .foregroundColor(AppColors.textSecondary)
                            Spacer()
                            Text(email)
                                .foregroundColor(AppColors.textTertiary)
                        }
                    }
                }
                
                Section("App") {
                    Button {
                        let healthStore = HKHealthStore()
                        let readTypes: Set<HKObjectType> = [
                            HKObjectType.quantityType(forIdentifier: .heartRate)!,
                            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
                            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
                            HKObjectType.workoutType()
                        ]
                        healthStore.requestAuthorization(toShare: [], read: readTypes) { _, _ in }
                    } label: {
                        Label("Request Health Permissions", systemImage: "heart.fill")
                    }
                    
                    Button {
                        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
                            if !granted {
                                DispatchQueue.main.async {
                                    if let url = URL(string: UIApplication.openSettingsURLString) {
                                        UIApplication.shared.open(url)
                                    }
                                }
                            }
                        }
                    } label: {
                        Label("Request Notification Permissions", systemImage: "bell.fill")
                    }
                }
                
                // Admin panel -- only visible to crucesaunders@icloud.com
                if AuthService.shared.isAdmin {
                    Section("Admin") {
                        Button("Debug Panel") {
                            showingDebugPanel = true
                        }
                        .foregroundColor(AppColors.brandPrimary)
                    }
                }
                
                Section("Account") {
                    Button("Sign Out") {
                        showingSignOutConfirm = true
                    }
                    .foregroundColor(AppColors.danger)
                    
                    Button("Delete Account") {
                        showingDeleteConfirm = true
                    }
                    .foregroundColor(AppColors.danger)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if isCheckingUsername {
                        ProgressView()
                    } else {
                        Button("Done") {
                            let trimmedUsername = username.trimmingCharacters(in: .whitespaces)
                            let usernameChanged = trimmedUsername.lowercased() != userData.profile.username && !trimmedUsername.isEmpty
                            
                            if usernameChanged {
                                guard isUsernameValid else {
                                    usernameError = "3-20 chars, letters/numbers/underscores only"
                                    return
                                }
                                isCheckingUsername = true
                                Task {
                                    let result = await FriendService.shared.checkUsernameAvailability(trimmedUsername.lowercased())
                                    isCheckingUsername = false
                                    switch result {
                                    case .available:
                                        applyProfileChanges(displayName: displayName, username: trimmedUsername)
                                    case .taken:
                                        usernameError = "Username is already taken"
                                    case .error(let message):
                                        usernameError = message
                                    }
                                }
                            } else {
                                applyProfileChanges(displayName: displayName, username: trimmedUsername)
                            }
                        }
                    }
                }
            }
            .alert("Sign Out?", isPresented: $showingSignOutConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) {
                    AuthService.shared.signOut()
                    dismiss()
                }
            } message: {
                Text("Your data is saved to the cloud. You can sign back in anytime.")
            }
            .alert("Delete Account?", isPresented: $showingDeleteConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    Task {
                        await AuthService.shared.deleteAccount()
                        dismiss()
                    }
                }
            } message: {
                Text("This will permanently delete your account and all data. This cannot be undone.")
            }
            .sheet(isPresented: $showingDebugPanel) {
                AdminDebugView()
                    .environmentObject(userData)
            }
        }
    }
    
    private func applyProfileChanges(displayName: String, username: String) {
        userData.profile.displayName = displayName
        if !username.isEmpty {
            userData.profile.username = username.trimmingCharacters(in: .whitespaces).lowercased()
        }
        userData.save()
        // Push updated profile (maxHR) to Watch
        WatchConnectivityService.shared.pushProfileToWatch()
        dismiss()
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
                            
                            // Primary metrics
                            HStack(spacing: AppSpacing.md) {
                                Label(run.formattedDuration, systemImage: "clock")
                                Label(run.formattedDistance, systemImage: "figure.run")
                                Label(run.formattedPace, systemImage: "gauge.medium")
                            }
                            .font(AppTypography.caption1)
                            .foregroundColor(AppColors.textSecondary)
                            
                            // Secondary metrics
                            HStack(spacing: AppSpacing.md) {
                                Label("\(run.sprintsCompleted)/\(run.sprintsTotal) sprints", systemImage: "bolt.fill")
                                if run.averageHR > 0 {
                                    Label("\(run.averageHR) bpm", systemImage: "heart.fill")
                                }
                                if run.totalCalories > 0 {
                                    Label(run.formattedCalories, systemImage: "flame.fill")
                                }
                            }
                            .font(AppTypography.caption2)
                            .foregroundColor(AppColors.textTertiary)
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
