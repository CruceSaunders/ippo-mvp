import SwiftUI

struct DailyRewardsView: View {
    @EnvironmentObject var userData: UserData
    @Environment(\.dismiss) var dismiss
    @State private var justClaimed = false
    @State private var claimedRewardType: DailyRewardType?
    @State private var showClaimAnimation = false
    
    private let dailyRewards = DailyRewardsSystem.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Close button
            HStack {
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(AppColors.textTertiary)
                }
            }
            .padding(.horizontal, AppSpacing.screenPadding)
            .padding(.top, AppSpacing.md)
            
            ScrollView {
                VStack(spacing: AppSpacing.xl) {
                    // Header
                    headerSection
                    
                    // Streak & Week Info
                    streakInfoBar
                    
                    // 7-Day Grid
                    rewardGrid
                    
                    Spacer(minLength: AppSpacing.xl)
                }
                .padding(.horizontal, AppSpacing.screenPadding)
            }
            
            // Bottom Button
            bottomButton
                .padding(AppSpacing.screenPadding)
        }
        .background(AppColors.background)
    }
    
    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: AppSpacing.sm) {
            Image(systemName: "gift.fill")
                .font(.system(size: 48))
                .foregroundStyle(
                    LinearGradient(
                        colors: [AppColors.warning, AppColors.sprintActive],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text("Daily Rewards")
                .font(AppTypography.title1)
                .foregroundColor(AppColors.textPrimary)
            
            Text("Log in every day to earn rewards!")
                .font(AppTypography.subheadline)
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(.top, AppSpacing.md)
    }
    
    // MARK: - Streak Info Bar
    private var streakInfoBar: some View {
        HStack(spacing: AppSpacing.md) {
            // Day Streak
            VStack(spacing: AppSpacing.xxs) {
                HStack(spacing: AppSpacing.xxs) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(AppColors.warning)
                    Text("\(userData.dailyRewards.currentStreak)")
                        .font(AppTypography.title2)
                        .foregroundColor(AppColors.textPrimary)
                }
                Text("Day Streak")
                    .font(AppTypography.caption1)
                    .foregroundColor(AppColors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(AppSpacing.md)
            .background(AppColors.surface)
            .cornerRadius(AppSpacing.radiusMd)
            
            // This Week
            VStack(spacing: AppSpacing.xxs) {
                ProgressRing(
                    progress: Double(userData.dailyRewards.claimedDays.count) / 7.0,
                    color: AppColors.brandPrimary,
                    size: 50,
                    lineWidth: 5,
                    showLabel: true,
                    labelFormat: .fraction(current: userData.dailyRewards.claimedDays.count, total: 7)
                )
                Text("This Week")
                    .font(AppTypography.caption1)
                    .foregroundColor(AppColors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(AppSpacing.md)
            .background(AppColors.surface)
            .cornerRadius(AppSpacing.radiusMd)
        }
    }
    
    // MARK: - Reward Grid
    private var rewardGrid: some View {
        VStack(spacing: AppSpacing.md) {
            // Top row: Days 1-4
            HStack(spacing: AppSpacing.sm) {
                ForEach(1...4, id: \.self) { day in
                    rewardCell(day: day)
                }
            }
            
            // Bottom row: Days 5-7
            HStack(spacing: AppSpacing.sm) {
                ForEach(5...7, id: \.self) { day in
                    rewardCell(day: day)
                }
            }
        }
    }
    
    private func rewardCell(day: Int) -> some View {
        let isClaimed = userData.dailyRewards.claimedDays.contains(day)
        let isCurrentDay = dailyRewards.currentClaimDay() == day
        let canClaim = dailyRewards.canClaimToday() && isCurrentDay
        let reward = DailyRewardDefinition.reward(forDay: day)
        
        return VStack(spacing: AppSpacing.xs) {
            Text("Day \(day)")
                .font(AppTypography.caption1)
                .foregroundColor(isCurrentDay ? AppColors.brandPrimary : AppColors.textSecondary)
            
            ZStack {
                RoundedRectangle(cornerRadius: AppSpacing.radiusMd)
                    .fill(isClaimed ? AppColors.surface : AppColors.surfaceElevated)
                    .frame(height: 70)
                
                if isClaimed {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title)
                        .foregroundColor(AppColors.success)
                } else if let reward = reward {
                    VStack(spacing: AppSpacing.xxxs) {
                        Image(systemName: reward.iconName)
                            .font(.title3)
                            .foregroundColor(rewardColor(for: reward.rewardType))
                        Text(reward.displayName)
                            .font(AppTypography.caption2)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: AppSpacing.radiusMd)
                    .stroke(
                        isCurrentDay && canClaim ? AppColors.brandPrimary :
                        isClaimed ? AppColors.success.opacity(0.3) :
                        Color.clear,
                        lineWidth: isCurrentDay && canClaim ? 2 : 1
                    )
            )
        }
        .frame(maxWidth: .infinity)
    }
    
    private func rewardColor(for type: DailyRewardType) -> Color {
        switch type {
        case .coins: return AppColors.gold
        case .gems: return AppColors.gems
        case .lootBox: return AppColors.rarityRare
        }
    }
    
    // MARK: - Bottom Button
    private var bottomButton: some View {
        Group {
            if justClaimed {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppColors.success)
                    Text("Claimed!")
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.success)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppColors.success.opacity(0.1))
                .cornerRadius(AppSpacing.radiusMd)
            } else if dailyRewards.canClaimToday() {
                Button {
                    claimReward()
                } label: {
                    HStack {
                        Image(systemName: "gift.fill")
                        Text("Claim Reward")
                    }
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [AppColors.brandPrimary, AppColors.brandSecondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(AppSpacing.radiusMd)
                }
            } else {
                HStack {
                    Text("Come back tomorrow!")
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.textSecondary)
                    Spacer()
                    Image(systemName: "arrow.right")
                        .foregroundColor(AppColors.textTertiary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppColors.surfaceElevated)
                .cornerRadius(AppSpacing.radiusMd)
            }
        }
    }
    
    // MARK: - Actions
    private func claimReward() {
        if let reward = dailyRewards.claimReward() {
            claimedRewardType = reward
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                justClaimed = true
            }
            HapticsManager.shared.playSuccess()
        }
    }
}

#Preview {
    DailyRewardsView()
        .environmentObject(UserData.shared)
}
