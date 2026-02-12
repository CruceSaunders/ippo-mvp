import SwiftUI

struct RanksView: View {
    @EnvironmentObject var userData: UserData
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Current Rank Display
                    currentRankSection
                    
                    // Progress to Next Rank
                    progressSection
                    
                    // Current Rank Boosts
                    currentBoostsSection
                    
                    // Next Rank Preview
                    if let nextRank = userData.profile.rank.nextRank {
                        nextRankBoostsSection(nextRank)
                    }
                    
                    // All Ranks
                    allRanksSection
                }
                .padding(.horizontal, AppSpacing.screenPadding)
                .padding(.bottom, AppSpacing.xxl)
            }
            .background(AppColors.background)
            .navigationTitle("Ranks")
        }
    }
    
    // MARK: - Current Rank Display
    private var currentRankSection: some View {
        VStack(spacing: AppSpacing.md) {
            // Rank Emblem
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [rankColor(userData.profile.rank).opacity(0.3), rankColor(userData.profile.rank).opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Circle()
                    .stroke(rankColor(userData.profile.rank), lineWidth: 3)
                    .frame(width: 120, height: 120)
                
                Image(systemName: userData.profile.rank.iconName)
                    .font(.system(size: 48))
                    .foregroundColor(rankColor(userData.profile.rank))
            }
            
            Text(userData.profile.rank.displayName)
                .font(AppTypography.title1)
                .foregroundColor(AppColors.textPrimary)
            
            Text("\(userData.profile.rp) Reputation Points")
                .font(AppTypography.callout)
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.xl)
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.radiusMd)
    }
    
    // MARK: - Progress Section
    private var progressSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            if let nextRank = userData.profile.rank.nextRank {
                HStack {
                    Text(userData.profile.rank.displayName)
                        .font(AppTypography.caption1)
                        .foregroundColor(rankColor(userData.profile.rank))
                    Spacer()
                    Text(nextRank.displayName)
                        .font(AppTypography.caption1)
                        .foregroundColor(rankColor(nextRank))
                }
                
                ProgressView(value: userData.profile.rpProgressInRank)
                    .tint(
                        LinearGradient(
                            colors: [rankColor(userData.profile.rank), rankColor(nextRank)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                if let rpNeeded = userData.profile.rpToNextRank {
                    Text("\(rpNeeded) RP to reach \(nextRank.displayName)")
                        .font(AppTypography.caption1)
                        .foregroundColor(AppColors.textTertiary)
                }
            } else {
                HStack {
                    Image(systemName: "trophy.fill")
                        .foregroundColor(AppColors.gold)
                    Text("Maximum Rank Achieved!")
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.gold)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .cardStyle()
    }
    
    // MARK: - Current Boosts
    private var currentBoostsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Current Rank Boosts")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textPrimary)
            
            ForEach(userData.profile.rank.boosts, id: \.description) { boost in
                HStack(spacing: AppSpacing.md) {
                    Image(systemName: boostIcon(boost.type))
                        .foregroundColor(AppColors.success)
                        .frame(width: 24)
                    
                    Text(boost.description)
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Spacer()
                    
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppColors.success)
                        .font(.caption)
                }
                .padding(.vertical, AppSpacing.xxs)
            }
        }
        .cardStyle()
    }
    
    // MARK: - Next Rank Boosts
    private func nextRankBoostsSection(_ nextRank: Rank) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Text("Next Rank: \(nextRank.displayName)")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                Image(systemName: nextRank.iconName)
                    .foregroundColor(rankColor(nextRank))
            }
            
            ForEach(nextRank.boosts, id: \.description) { boost in
                HStack(spacing: AppSpacing.md) {
                    Image(systemName: boostIcon(boost.type))
                        .foregroundColor(AppColors.textTertiary)
                        .frame(width: 24)
                    
                    Text(boost.description)
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)
                    
                    Spacer()
                    
                    Image(systemName: "lock.fill")
                        .foregroundColor(AppColors.textTertiary)
                        .font(.caption)
                }
                .padding(.vertical, AppSpacing.xxs)
            }
        }
        .cardStyle()
    }
    
    // MARK: - All Ranks
    private var allRanksSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("All Ranks")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textPrimary)
            
            ForEach(Rank.allCases, id: \.self) { rank in
                let isCurrent = rank == userData.profile.rank
                let isAchieved = userData.profile.rp >= rank.rpRequired
                
                HStack(spacing: AppSpacing.md) {
                    ZStack {
                        Circle()
                            .fill(isAchieved ? rankColor(rank).opacity(0.2) : AppColors.surfaceElevated)
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: rank.iconName)
                            .font(.title3)
                            .foregroundColor(isAchieved ? rankColor(rank) : AppColors.textTertiary)
                    }
                    
                    VStack(alignment: .leading, spacing: AppSpacing.xxxs) {
                        Text(rank.displayName)
                            .font(AppTypography.subheadline)
                            .foregroundColor(isCurrent ? AppColors.textPrimary : AppColors.textSecondary)
                            .fontWeight(isCurrent ? .bold : .regular)
                        
                        Text(rank.rpRangeDisplay + " RP")
                            .font(AppTypography.caption2)
                            .foregroundColor(AppColors.textTertiary)
                    }
                    
                    Spacer()
                    
                    if isCurrent {
                        Text("CURRENT")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(rankColor(rank))
                            .padding(.horizontal, AppSpacing.sm)
                            .padding(.vertical, AppSpacing.xxs)
                            .background(rankColor(rank).opacity(0.15))
                            .cornerRadius(AppSpacing.radiusSm)
                    } else if isAchieved {
                        Image(systemName: "checkmark")
                            .foregroundColor(AppColors.success)
                            .font(.caption)
                    } else {
                        Image(systemName: "lock.fill")
                            .foregroundColor(AppColors.textTertiary)
                            .font(.caption)
                    }
                }
                .padding(.vertical, AppSpacing.xs)
                .padding(.horizontal, AppSpacing.sm)
                .background(isCurrent ? rankColor(rank).opacity(0.05) : Color.clear)
                .cornerRadius(AppSpacing.radiusSm)
                
                if rank != Rank.allCases.last {
                    Divider()
                        .background(AppColors.surfaceElevated)
                }
            }
        }
        .cardStyle()
    }
    
    // MARK: - Helpers
    private func rankColor(_ rank: Rank) -> Color {
        switch rank {
        case .bronze: return Color(hex: "#CD7F32")
        case .silver: return Color(hex: "#C0C0C0")
        case .gold: return AppColors.gold
        case .platinum: return Color(hex: "#E5E4E2")
        case .diamond: return Color(hex: "#B9F2FF")
        }
    }
    
    private func boostIcon(_ type: RankBoost.BoostType) -> String {
        switch type {
        case .coins: return "dollarsign.circle.fill"
        case .xp: return "arrow.up.circle.fill"
        case .rp: return "star.circle.fill"
        case .all: return "sparkles"
        }
    }
}

#Preview {
    RanksView()
        .environmentObject(UserData.shared)
}
