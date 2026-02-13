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
                    
                    // RP Decay Info
                    rpDecaySection
                    
                    // All Ranks & Divisions
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
            
            // Rank Tier Name (e.g., "Gold II")
            Text(userData.profile.rankTier.displayName)
                .font(AppTypography.title1)
                .foregroundColor(AppColors.textPrimary)
            
            Text("\(userData.profile.rp) Reputation Points")
                .font(AppTypography.callout)
                .foregroundColor(AppColors.textSecondary)
            
            // Weekly RP
            HStack(spacing: AppSpacing.xxs) {
                Image(systemName: "calendar")
                    .foregroundColor(AppColors.textTertiary)
                Text("This week: +\(userData.profile.weeklyRP) RP")
                    .font(AppTypography.caption1)
                    .foregroundColor(AppColors.textSecondary)
            }
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
                    .tint(rankColor(userData.profile.rank))
                
                if let rpNeeded = userData.profile.rpToNextRank {
                    Text("\(rpNeeded) RP to reach \(nextRank.displayName)")
                        .font(AppTypography.caption1)
                        .foregroundColor(AppColors.textTertiary)
                }
            } else {
                HStack {
                    Image(systemName: "trophy.fill")
                        .foregroundColor(.orange)
                    Text("Maximum Rank Achieved!")
                        .font(AppTypography.headline)
                        .foregroundColor(.orange)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .cardStyle()
    }
    
    // MARK: - RP Decay Info
    private var rpDecaySection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(AppColors.brandPrimary)
                Text("RP Decay")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)
            }
            
            let decayRange = userData.profile.rank.rpDecayPerDay
            if decayRange.lowerBound == 0 && decayRange.upperBound == 0 {
                Text("Bronze rank is protected from RP decay. Keep running to rank up!")
                    .font(AppTypography.caption1)
                    .foregroundColor(AppColors.textSecondary)
            } else {
                Text("If you don't run, you lose \(decayRange.lowerBound)-\(decayRange.upperBound) RP per day. Higher ranks decay faster, so stay consistent!")
                    .font(AppTypography.caption1)
                    .foregroundColor(AppColors.textSecondary)
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
                let isAchieved = userData.profile.rp >= rank.baseRPRequired
                
                VStack(spacing: AppSpacing.xs) {
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
                            
                            // Show divisions
                            HStack(spacing: AppSpacing.xs) {
                                ForEach([Division.three, .two, .one], id: \.self) { division in
                                    let tier = RankTier(rank: rank, division: division)
                                    let isCurrentTier = userData.profile.rankTier == tier
                                    Text(division.displayName)
                                        .font(.system(size: 10, weight: isCurrentTier ? .bold : .regular))
                                        .foregroundColor(isCurrentTier ? rankColor(rank) : AppColors.textTertiary)
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 2)
                                        .background(isCurrentTier ? rankColor(rank).opacity(0.15) : Color.clear)
                                        .cornerRadius(3)
                                }
                            }
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
                            Text("\(rank.baseRPRequired) RP")
                                .font(AppTypography.caption2)
                                .foregroundColor(AppColors.textTertiary)
                        }
                    }
                    .padding(.vertical, AppSpacing.xs)
                    .padding(.horizontal, AppSpacing.sm)
                    .background(isCurrent ? rankColor(rank).opacity(0.05) : Color.clear)
                    .cornerRadius(AppSpacing.radiusSm)
                }
                
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
        case .gold: return Color(hex: "#FFD700")
        case .platinum: return Color(hex: "#E5E4E2")
        case .diamond: return Color(hex: "#B9F2FF")
        }
    }
}

#Preview {
    RanksView()
        .environmentObject(UserData.shared)
}
