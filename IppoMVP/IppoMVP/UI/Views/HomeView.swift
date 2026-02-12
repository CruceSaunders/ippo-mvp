import SwiftUI

struct HomeView: View {
    @EnvironmentObject var userData: UserData
    @State private var showingRunPrompt = false
    @State private var showingDailyRewards = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Welcome
                    welcomeSection
                    
                    // Start Run CTA
                    startRunSection
                    
                    // Daily Rewards Card
                    dailyRewardsCard
                    
                    // Equipped Pet
                    if let pet = userData.equippedPet {
                        equippedPetSection(pet)
                    }
                    
                    // Challenges (Weekly + Monthly grouped)
                    challengesSection
                    
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
                    currencyDisplay
                }
            }
            .sheet(isPresented: $showingDailyRewards) {
                DailyRewardsView()
            }
            .onAppear {
                ChallengesSystem.shared.refreshIfNeeded()
                AchievementsSystem.shared.initializeIfNeeded()
            }
        }
    }
    
    // MARK: - Welcome Section
    private var welcomeSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text("Welcome back,")
                    .font(AppTypography.subheadline)
                    .foregroundColor(AppColors.textSecondary)
                Text(userData.profile.displayName)
                    .font(AppTypography.title2)
                    .foregroundColor(AppColors.textPrimary)
            }
            Spacer()
            
            // Streak badge
            if userData.profile.currentStreak > 0 {
                HStack(spacing: AppSpacing.xxs) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(AppColors.warning)
                    Text("\(userData.profile.currentStreak)")
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.warning)
                }
                .padding(.horizontal, AppSpacing.sm)
                .padding(.vertical, AppSpacing.xs)
                .background(AppColors.warning.opacity(0.15))
                .cornerRadius(AppSpacing.radiusSm)
            }
        }
        .padding(.top, AppSpacing.sm)
    }
    
    // MARK: - Currency Display
    private var currencyDisplay: some View {
        HStack(spacing: AppSpacing.md) {
            HStack(spacing: AppSpacing.xxs) {
                Image(systemName: "dollarsign.circle.fill")
                    .foregroundColor(AppColors.gold)
                Text("\(userData.coins)")
                    .font(AppTypography.currency)
                    .foregroundColor(AppColors.textPrimary)
            }
            
            HStack(spacing: AppSpacing.xxs) {
                Image(systemName: "diamond.fill")
                    .foregroundColor(AppColors.gems)
                Text("\(userData.gems)")
                    .font(AppTypography.currency)
                    .foregroundColor(AppColors.textPrimary)
            }
        }
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
                    Text(userData.equippedPet != nil ? "1 pet equipped" : "No pet equipped")
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
    
    // MARK: - Daily Rewards Card
    private var dailyRewardsCard: some View {
        Button {
            showingDailyRewards = true
        } label: {
            HStack(spacing: AppSpacing.md) {
                Image(systemName: "gift.fill")
                    .font(.title2)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [AppColors.warning, AppColors.sprintActive],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                VStack(alignment: .leading, spacing: AppSpacing.xxxs) {
                    Text("Daily Rewards")
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.textPrimary)
                    
                    if DailyRewardsSystem.shared.canClaimToday() {
                        Text("Tap to claim today's reward!")
                            .font(AppTypography.caption1)
                            .foregroundColor(AppColors.success)
                    } else {
                        Text("Come back tomorrow")
                            .font(AppTypography.caption1)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                
                Spacer()
                
                // Streak display
                if userData.dailyRewards.currentStreak > 0 {
                    HStack(spacing: AppSpacing.xxs) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(AppColors.warning)
                            .font(.caption)
                        Text("\(userData.dailyRewards.currentStreak)")
                            .font(AppTypography.callout)
                            .foregroundColor(AppColors.warning)
                    }
                }
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(AppColors.textTertiary)
            }
            .padding(AppSpacing.cardPadding)
            .background(
                DailyRewardsSystem.shared.canClaimToday() ?
                AppColors.brandPrimary.opacity(0.08) : AppColors.surface
            )
            .cornerRadius(AppSpacing.radiusMd)
            .overlay(
                RoundedRectangle(cornerRadius: AppSpacing.radiusMd)
                    .stroke(
                        DailyRewardsSystem.shared.canClaimToday() ?
                        AppColors.brandPrimary.opacity(0.3) : Color.clear,
                        lineWidth: 1
                    )
            )
        }
    }
    
    // MARK: - Equipped Pet Section
    private func equippedPetSection(_ pet: OwnedPet) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Equipped Pet")
                .font(AppTypography.footnote)
                .foregroundColor(AppColors.textTertiary)
            
            HStack(spacing: AppSpacing.md) {
                // Pet Image
                ZStack {
                    Circle()
                        .fill(AppColors.forPet(pet.petDefinitionId).opacity(0.2))
                        .frame(width: 60, height: 60)
                    Text(pet.definition?.emoji ?? "🐾")
                        .font(.system(size: 30))
                }
                
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text(pet.definition?.name ?? "Unknown")
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.textPrimary)
                    Text("\(pet.stageName) (Stage \(pet.evolutionStage))")
                        .font(AppTypography.caption1)
                        .foregroundColor(AppColors.textSecondary)
                    
                    // XP Progress
                    ProgressView(value: pet.xpProgress)
                        .tint(AppColors.forPet(pet.petDefinitionId))
                }
                
                Spacer()
                
                Text(pet.moodEmoji)
                    .font(.title)
            }
        }
        .cardStyle()
    }
    
    // MARK: - Challenges Section
    private var challengesSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Challenges")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textPrimary)
            
            // Monthly Challenge
            if let monthly = userData.challengeData.monthlyChallenge {
                challengeRow(monthly, isMonthly: true)
            }
            
            // Weekly Challenges
            ForEach(userData.challengeData.weeklyChallenges) { challenge in
                challengeRow(challenge, isMonthly: false)
            }
            
            if userData.challengeData.weeklyChallenges.isEmpty && userData.challengeData.monthlyChallenge == nil {
                Text("No active challenges")
                    .font(AppTypography.subheadline)
                    .foregroundColor(AppColors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.md)
            }
        }
        .cardStyle()
    }
    
    private func challengeRow(_ challenge: Challenge, isMonthly: Bool) -> some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: challenge.iconName)
                .font(.title3)
                .foregroundColor(isMonthly ? AppColors.warning : AppColors.brandPrimary)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: AppSpacing.xxxs) {
                HStack {
                    Text(challenge.name)
                        .font(AppTypography.subheadline)
                        .foregroundColor(AppColors.textPrimary)
                    if isMonthly {
                        Text("MONTHLY")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(AppColors.warning)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(AppColors.warning.opacity(0.15))
                            .cornerRadius(3)
                    }
                }
                
                ProgressView(value: challenge.progressFraction)
                    .tint(challenge.isCompleted ? AppColors.success : AppColors.brandPrimary)
                
                Text("\(challenge.progress)/\(challenge.target)")
                    .font(AppTypography.caption2)
                    .foregroundColor(AppColors.textTertiary)
            }
            
            Spacer()
            
            if challenge.isCompleted && !challenge.isClaimed {
                Button {
                    _ = ChallengesSystem.shared.claimReward(challengeId: challenge.id)
                    HapticsManager.shared.playSuccess()
                } label: {
                    Text("Claim")
                        .font(AppTypography.caption1)
                        .foregroundColor(AppColors.textPrimary)
                        .padding(.horizontal, AppSpacing.sm)
                        .padding(.vertical, AppSpacing.xs)
                        .background(AppColors.brandPrimary)
                        .cornerRadius(AppSpacing.radiusSm)
                }
            } else if challenge.isClaimed {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(AppColors.success)
            }
        }
        .padding(.vertical, AppSpacing.xs)
    }
    
    // MARK: - Recent Runs
    private var recentRunsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Text("Recent Runs")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
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
                        Text("+\(run.rpEarned) RP")
                            .font(AppTypography.callout)
                            .foregroundColor(AppColors.success)
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

#Preview {
    HomeView()
        .environmentObject(UserData.shared)
}
