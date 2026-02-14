import SwiftUI

struct RanksView: View {
    @EnvironmentObject var userData: UserData
    @StateObject private var leaderboardService = RankLeaderboardService.shared
    
    @State private var expandedRank: Rank?
    @State private var hasAppearedOnce = false
    
    var body: some View {
        NavigationStack {
            ScrollViewReader { scrollProxy in
                ScrollView {
                    VStack(spacing: AppSpacing.lg) {
                        // Current Rank Display
                        currentRankSection
                        
                        // Progress to Next Rank
                        progressSection
                        
                        // RP Decay Info
                        rpDecaySection
                        
                        // All Ranks & Player Rosters
                        allRanksSection
                    }
                    .padding(.horizontal, AppSpacing.screenPadding)
                    .padding(.bottom, AppSpacing.xxl)
                }
                .background(AppColors.background)
                .navigationTitle("Ranks")
                .onChange(of: expandedRank) { newRank in
                    // When a rank expands, scroll to it after a brief layout delay
                    if let rank = newRank {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                scrollProxy.scrollTo("rank_\(rank.rawValue)", anchor: .top)
                            }
                        }
                    }
                }
            }
            .task {
                guard !hasAppearedOnce else { return }
                hasAppearedOnce = true
                
                // Auto-expand the user's current rank
                let currentRank = userData.profile.rank
                expandedRank = currentRank
                
                // Fetch players for the user's rank and counts for all ranks
                async let playersFetch: () = leaderboardService.fetchPlayers(for: currentRank)
                async let countsFetch: () = leaderboardService.fetchAllRankCounts()
                _ = await (playersFetch, countsFetch)
            }
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
    
    // MARK: - All Ranks (Expandable Accordion)
    private var allRanksSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("All Ranks")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textPrimary)
            
            ForEach(Rank.allCases, id: \.self) { rank in
                let isCurrent = rank == userData.profile.rank
                let isAchieved = userData.profile.rp >= rank.baseRPRequired
                let isExpanded = expandedRank == rank
                
                VStack(spacing: 0) {
                    // Rank Header Row (tappable)
                    rankHeaderRow(rank: rank, isCurrent: isCurrent, isAchieved: isAchieved, isExpanded: isExpanded)
                        .id("rank_\(rank.rawValue)")
                    
                    // Expanded Player Roster
                    if isExpanded {
                        rankPlayersSection(for: rank)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .background(isExpanded ? rankColor(rank).opacity(0.03) : Color.clear)
                .cornerRadius(AppSpacing.radiusSm)
                .overlay(
                    RoundedRectangle(cornerRadius: AppSpacing.radiusSm)
                        .stroke(isExpanded ? rankColor(rank).opacity(0.15) : Color.clear, lineWidth: 1)
                )
                
                if rank != Rank.allCases.last && !isExpanded {
                    Divider()
                        .background(AppColors.surfaceElevated)
                }
            }
        }
        .cardStyle()
    }
    
    // MARK: - Rank Header Row
    private func rankHeaderRow(rank: Rank, isCurrent: Bool, isAchieved: Bool, isExpanded: Bool) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                if expandedRank == rank {
                    expandedRank = nil
                } else {
                    expandedRank = rank
                }
            }
            // Fetch players when expanding (uses cache if fresh)
            if expandedRank == rank {
                Task {
                    await leaderboardService.fetchPlayers(for: rank)
                }
            }
        } label: {
            HStack(spacing: AppSpacing.md) {
                // Rank Icon
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
                    
                    // Divisions row
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
                
                // Player count badge
                if let count = leaderboardService.rankTotalCounts[rank], count > 0 {
                    Text("\(count)")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundColor(AppColors.textTertiary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(AppColors.surfaceElevated)
                        .cornerRadius(8)
                }
                
                // Status badge / chevron
                if isCurrent {
                    Text("YOU")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(rankColor(rank))
                        .padding(.horizontal, AppSpacing.xs)
                        .padding(.vertical, AppSpacing.xxxs)
                        .background(rankColor(rank).opacity(0.15))
                        .cornerRadius(AppSpacing.radiusSm)
                } else if !isAchieved {
                    Text("\(rank.baseRPRequired)")
                        .font(AppTypography.caption2)
                        .foregroundColor(AppColors.textTertiary)
                }
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppColors.textTertiary)
                    .rotationEffect(.degrees(isExpanded ? -180 : 0))
            }
            .padding(.vertical, AppSpacing.sm)
            .padding(.horizontal, AppSpacing.sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Rank Players Section (Expanded Content)
    private func rankPlayersSection(for rank: Rank) -> some View {
        VStack(spacing: 0) {
            Divider()
                .background(rankColor(rank).opacity(0.2))
                .padding(.horizontal, AppSpacing.sm)
            
            let isLoading = leaderboardService.loadingRanks.contains(rank)
            let players = leaderboardService.rankPlayers[rank] ?? []
            let error = leaderboardService.rankErrors[rank]
            let hasMore = leaderboardService.hasMorePlayers[rank] ?? false
            
            if let error = error {
                // Error State
                errorStateView(message: error, rank: rank)
            } else if isLoading && players.isEmpty {
                // Loading State (first load)
                loadingStateView(rank: rank)
            } else if players.isEmpty {
                // Empty State
                emptyStateView(rank: rank)
            } else {
                // Player List
                VStack(spacing: 0) {
                    ForEach(Array(players.enumerated()), id: \.element.id) { index, player in
                        playerRow(player: player, position: index + 1, rank: rank)
                            .id("player_\(player.id)")
                        
                        if index < players.count - 1 {
                            Divider()
                                .background(AppColors.surfaceElevated.opacity(0.5))
                                .padding(.leading, 48)
                        }
                    }
                    
                    // Load More button
                    if hasMore {
                        loadMoreButton(for: rank, isLoading: isLoading)
                    }
                    
                    // Total count footer
                    if let totalCount = leaderboardService.rankTotalCounts[rank], totalCount > players.count {
                        Text("Showing \(players.count) of \(totalCount) runners")
                            .font(AppTypography.caption2)
                            .foregroundColor(AppColors.textTertiary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppSpacing.sm)
                    }
                }
            }
        }
        .padding(.bottom, AppSpacing.sm)
    }
    
    // MARK: - Player Row
    private func playerRow(player: RankPlayerEntry, position: Int, rank: Rank) -> some View {
        HStack(spacing: AppSpacing.md) {
            // Position number
            Text("#\(position)")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(player.isCurrentUser ? rankColor(rank) : AppColors.textTertiary)
                .frame(width: 32, alignment: .leading)
            
            // Player info
            VStack(alignment: .leading, spacing: AppSpacing.xxxs) {
                HStack(spacing: AppSpacing.xs) {
                    Text(player.displayName)
                        .font(.system(size: 14, weight: player.isCurrentUser ? .bold : .medium, design: .rounded))
                        .foregroundColor(player.isCurrentUser ? AppColors.textPrimary : AppColors.textSecondary)
                        .lineLimit(1)
                    
                    if player.isCurrentUser {
                        Text("YOU")
                            .font(.system(size: 8, weight: .heavy))
                            .foregroundColor(rankColor(rank))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(rankColor(rank).opacity(0.15))
                            .cornerRadius(4)
                    }
                }
                
                if !player.username.isEmpty {
                    Text("@\(player.username)")
                        .font(AppTypography.caption2)
                        .foregroundColor(AppColors.textTertiary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Division badge
            Text(player.rankTier.division.displayName)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(rankColor(rank).opacity(0.8))
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(rankColor(rank).opacity(0.08))
                .cornerRadius(3)
            
            // RP + Level
            VStack(alignment: .trailing, spacing: AppSpacing.xxxs) {
                Text("\(player.rp) RP")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(player.isCurrentUser ? rankColor(rank) : AppColors.textSecondary)
                
                Text("Lv. \(player.level)")
                    .font(AppTypography.caption2)
                    .foregroundColor(AppColors.textTertiary)
            }
        }
        .padding(.vertical, AppSpacing.sm)
        .padding(.horizontal, AppSpacing.md)
        .background(player.isCurrentUser ? rankColor(rank).opacity(0.06) : Color.clear)
    }
    
    // MARK: - Loading State
    private func loadingStateView(rank: Rank) -> some View {
        VStack(spacing: AppSpacing.sm) {
            ForEach(0..<3, id: \.self) { _ in
                HStack(spacing: AppSpacing.md) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(AppColors.surfaceElevated)
                        .frame(width: 32, height: 14)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(AppColors.surfaceElevated)
                            .frame(width: 100, height: 14)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(AppColors.surfaceElevated)
                            .frame(width: 60, height: 10)
                    }
                    
                    Spacer()
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(AppColors.surfaceElevated)
                        .frame(width: 50, height: 14)
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.xs)
            }
            .redacted(reason: .placeholder)
            .shimmer()
        }
        .padding(.vertical, AppSpacing.sm)
    }
    
    // MARK: - Empty State
    private func emptyStateView(rank: Rank) -> some View {
        VStack(spacing: AppSpacing.sm) {
            Image(systemName: "person.3")
                .font(.title2)
                .foregroundColor(AppColors.textTertiary)
            
            Text("No runners in \(rank.displayName) yet")
                .font(AppTypography.caption1)
                .foregroundColor(AppColors.textTertiary)
            
            Text("Be the first to reach this rank!")
                .font(AppTypography.caption2)
                .foregroundColor(AppColors.textTertiary.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.lg)
    }
    
    // MARK: - Error State
    private func errorStateView(message: String, rank: Rank) -> some View {
        VStack(spacing: AppSpacing.sm) {
            Image(systemName: "wifi.exclamationmark")
                .font(.title3)
                .foregroundColor(AppColors.danger)
            
            Text(message)
                .font(AppTypography.caption1)
                .foregroundColor(AppColors.textTertiary)
            
            Button {
                Task {
                    await leaderboardService.fetchPlayers(for: rank, forceRefresh: true)
                }
            } label: {
                Text("Retry")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppColors.brandPrimary)
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.vertical, AppSpacing.xs)
                    .background(AppColors.brandPrimary.opacity(0.12))
                    .cornerRadius(AppSpacing.radiusSm)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.lg)
    }
    
    // MARK: - Load More Button
    private func loadMoreButton(for rank: Rank, isLoading: Bool) -> some View {
        Button {
            Task {
                await leaderboardService.fetchMorePlayers(for: rank)
            }
        } label: {
            HStack(spacing: AppSpacing.xs) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                        .tint(AppColors.brandPrimary)
                } else {
                    Image(systemName: "arrow.down.circle")
                        .font(.system(size: 13))
                }
                Text("Load More")
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(AppColors.brandPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.sm)
            .background(AppColors.brandPrimary.opacity(0.06))
            .cornerRadius(AppSpacing.radiusSm)
        }
        .disabled(isLoading)
        .padding(.horizontal, AppSpacing.md)
        .padding(.top, AppSpacing.xs)
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

// MARK: - Shimmer Effect
private struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        .clear,
                        Color.white.opacity(0.08),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase)
                .onAppear {
                    withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                        phase = 300
                    }
                }
            )
            .clipped()
    }
}

extension View {
    fileprivate func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

#Preview {
    RanksView()
        .environmentObject(UserData.shared)
}
