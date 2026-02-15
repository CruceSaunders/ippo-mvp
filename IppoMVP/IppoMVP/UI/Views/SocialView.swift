import SwiftUI

struct SocialView: View {
    @EnvironmentObject var userData: UserData
    @StateObject private var friendService = FriendService.shared
    @StateObject private var groupService = GroupService.shared
    @State private var selectedSection = 0
    @State private var showingAddFriend = false
    @State private var showingCreateGroup = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Section", selection: $selectedSection) {
                    Text("Friends").tag(0)
                    Text("Groups").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, AppSpacing.screenPadding)
                .padding(.top, AppSpacing.sm)
                
                ScrollView {
                    VStack(spacing: AppSpacing.lg) {
                        if selectedSection == 0 {
                            friendsSection
                        } else {
                            groupsSection
                        }
                    }
                    .padding(.horizontal, AppSpacing.screenPadding)
                    .padding(.top, AppSpacing.md)
                    .padding(.bottom, AppSpacing.xxl)
                }
            }
            .background(AppColors.background)
            .navigationTitle("Social")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if selectedSection == 0 {
                            showingAddFriend = true
                        } else {
                            showingCreateGroup = true
                        }
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(AppColors.brandPrimary)
                    }
                }
            }
            .sheet(isPresented: $showingAddFriend) {
                AddFriendSheet()
                    .environmentObject(userData)
            }
            .sheet(isPresented: $showingCreateGroup) {
                CreateGroupSheet()
                    .environmentObject(userData)
            }
            .task {
                await friendService.refreshFriendRequests()
                await friendService.loadFriendProfiles()
                await groupService.fetchUserGroups()
            }
        }
    }
    
    // MARK: - Friends Section
    private var friendsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Friend requests
            if !userData.friendRequests.isEmpty {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Friend Requests (\(userData.friendRequests.count))")
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.textPrimary)
                    
                    ForEach(userData.friendRequests, id: \.self) { requestUid in
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(AppColors.brandPrimary.opacity(0.2))
                                    .frame(width: 40, height: 40)
                                Image(systemName: "person.fill.questionmark")
                                    .font(.system(size: 16))
                                    .foregroundColor(AppColors.brandPrimary)
                            }
                            
                            VStack(alignment: .leading) {
                                Text(requestUid.prefix(8) + "...")
                                    .font(AppTypography.subheadline)
                                    .foregroundColor(AppColors.textPrimary)
                                Text("Wants to be your friend")
                                    .font(AppTypography.caption2)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            
                            Spacer()
                            
                            Button {
                                Task {
                                    await friendService.acceptFriendRequest(from: requestUid)
                                    await friendService.loadFriendProfiles()
                                }
                            } label: {
                                Text("Accept")
                                    .font(AppTypography.caption1)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, AppSpacing.sm)
                                    .padding(.vertical, AppSpacing.xs)
                                    .background(AppColors.brandPrimary)
                                    .cornerRadius(AppSpacing.radiusSm)
                            }
                        }
                        .padding(.vertical, AppSpacing.xs)
                    }
                }
                .cardStyle()
            }
            
            // Friends list
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Friends (\(friendService.friendProfiles.count))")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)
                
                if friendService.friendProfiles.isEmpty && userData.friends.isEmpty {
                    VStack(spacing: AppSpacing.sm) {
                        Image(systemName: "person.2.slash")
                            .font(.largeTitle)
                            .foregroundColor(AppColors.textTertiary)
                        Text("No friends yet")
                            .font(AppTypography.subheadline)
                            .foregroundColor(AppColors.textSecondary)
                        Text("Tap + to add friends by username")
                            .font(AppTypography.caption1)
                            .foregroundColor(AppColors.textTertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.xl)
                } else if friendService.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.lg)
                } else {
                    ForEach(friendService.friendProfiles) { friend in
                        friendProfileRow(friend)
                        
                        if friend.id != friendService.friendProfiles.last?.id {
                            Divider()
                                .background(AppColors.surfaceElevated)
                        }
                    }
                }
            }
            .cardStyle()
        }
    }
    
    private func friendProfileRow(_ friend: FriendProfile) -> some View {
        HStack(spacing: AppSpacing.md) {
            ZStack {
                Circle()
                    .fill(AppColors.brandPrimary.opacity(0.2))
                    .frame(width: 40, height: 40)
                Text(String(friend.displayName.prefix(2)).uppercased())
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppColors.brandPrimary)
            }
            
            VStack(alignment: .leading, spacing: AppSpacing.xxxs) {
                Text(friend.displayName)
                    .font(AppTypography.subheadline)
                    .foregroundColor(AppColors.textPrimary)
                if !friend.username.isEmpty {
                    Text("@\(friend.username)")
                        .font(AppTypography.caption2)
                        .foregroundColor(AppColors.textTertiary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: AppSpacing.xxxs) {
                Text("\(friend.rp) RP")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppColors.brandPrimary)
                Text("Lv. \(friend.level)")
                    .font(AppTypography.caption2)
                    .foregroundColor(AppColors.textTertiary)
            }
            
            Button {
                Task {
                    await friendService.removeFriend(friend.id)
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(AppColors.textTertiary)
            }
        }
        .padding(.vertical, AppSpacing.xs)
    }
    
    // MARK: - Groups Section
    private var groupsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Your Groups (\(groupService.userGroups.count))")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)
                
                if groupService.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.lg)
                } else if groupService.userGroups.isEmpty {
                    VStack(spacing: AppSpacing.sm) {
                        Image(systemName: "person.3.fill")
                            .font(.largeTitle)
                            .foregroundColor(AppColors.textTertiary)
                        Text("No groups yet")
                            .font(AppTypography.subheadline)
                            .foregroundColor(AppColors.textSecondary)
                        Text("Create a group and invite friends to compete on a weekly leaderboard!")
                            .font(AppTypography.caption1)
                            .foregroundColor(AppColors.textTertiary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.xl)
                } else {
                    ForEach(groupService.userGroups) { group in
                        NavigationLink(destination: GroupDetailView(group: group)) {
                            groupRow(group)
                        }
                        .buttonStyle(.plain)
                        
                        if group.id != groupService.userGroups.last?.id {
                            Divider()
                                .background(AppColors.surfaceElevated)
                        }
                    }
                }
            }
            .cardStyle()
            
            // Info card
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack {
                    Image(systemName: "trophy.fill")
                        .foregroundColor(AppColors.warning)
                    Text("Weekly Leaderboards")
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.textPrimary)
                }
                
                Text("Groups have weekly leaderboards that track RP earned. Resets every Monday. Compete with friends to see who earns the most RP each week!")
                    .font(AppTypography.caption1)
                    .foregroundColor(AppColors.textSecondary)
            }
            .cardStyle()
        }
    }
    
    private func groupRow(_ group: IppoGroup) -> some View {
        HStack(spacing: AppSpacing.md) {
            ZStack {
                Circle()
                    .fill(AppColors.brandSecondary.opacity(0.2))
                    .frame(width: 44, height: 44)
                Image(systemName: "person.3.fill")
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.brandSecondary)
            }
            
            VStack(alignment: .leading, spacing: AppSpacing.xxxs) {
                Text(group.name)
                    .font(AppTypography.subheadline)
                    .foregroundColor(AppColors.textPrimary)
                Text("\(group.memberIds.count) members")
                    .font(AppTypography.caption2)
                    .foregroundColor(AppColors.textTertiary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(AppColors.textTertiary)
        }
        .padding(.vertical, AppSpacing.xs)
    }
}

// MARK: - Group Detail View
struct GroupDetailView: View {
    let group: IppoGroup
    @StateObject private var groupService = GroupService.shared
    @State private var leaderboard: [GroupLeaderboardEntry] = []
    @State private var members: [FriendProfile] = []
    @State private var isLoading = true
    @State private var showingLeaveConfirm = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                // Group header
                VStack(spacing: AppSpacing.sm) {
                    ZStack {
                        Circle()
                            .fill(AppColors.brandSecondary.opacity(0.2))
                            .frame(width: 60, height: 60)
                        Image(systemName: "person.3.fill")
                            .font(.title2)
                            .foregroundColor(AppColors.brandSecondary)
                    }
                    
                    Text(group.name)
                        .font(AppTypography.title2)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("\(group.memberIds.count) members")
                        .font(AppTypography.caption1)
                        .foregroundColor(AppColors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(AppSpacing.lg)
                .background(AppColors.surface)
                .cornerRadius(AppSpacing.radiusMd)
                
                // Weekly Leaderboard
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    HStack {
                        Image(systemName: "trophy.fill")
                            .foregroundColor(AppColors.warning)
                        Text("Weekly Leaderboard")
                            .font(AppTypography.headline)
                            .foregroundColor(AppColors.textPrimary)
                    }
                    
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppSpacing.lg)
                    } else if leaderboard.isEmpty {
                        Text("No RP earned this week yet. Start running!")
                            .font(AppTypography.caption1)
                            .foregroundColor(AppColors.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppSpacing.lg)
                    } else {
                        ForEach(Array(leaderboard.enumerated()), id: \.element.id) { index, entry in
                            leaderboardRow(entry: entry, position: index + 1)
                            
                            if index < leaderboard.count - 1 {
                                Divider()
                                    .background(AppColors.surfaceElevated)
                            }
                        }
                    }
                }
                .cardStyle()
                
                // Members
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Members")
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.textPrimary)
                    
                    ForEach(members) { member in
                        HStack(spacing: AppSpacing.md) {
                            ZStack {
                                Circle()
                                    .fill(AppColors.brandPrimary.opacity(0.2))
                                    .frame(width: 36, height: 36)
                                Text(String(member.displayName.prefix(2)).uppercased())
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(AppColors.brandPrimary)
                            }
                            
                            VStack(alignment: .leading, spacing: 0) {
                                HStack(spacing: AppSpacing.xs) {
                                    Text(member.displayName)
                                        .font(AppTypography.subheadline)
                                        .foregroundColor(AppColors.textPrimary)
                                    if member.isCurrentUser {
                                        Text("YOU")
                                            .font(.system(size: 8, weight: .heavy))
                                            .foregroundColor(AppColors.brandPrimary)
                                            .padding(.horizontal, 4)
                                            .padding(.vertical, 2)
                                            .background(AppColors.brandPrimary.opacity(0.15))
                                            .cornerRadius(3)
                                    }
                                }
                                if !member.username.isEmpty {
                                    Text("@\(member.username)")
                                        .font(AppTypography.caption2)
                                        .foregroundColor(AppColors.textTertiary)
                                }
                            }
                            
                            Spacer()
                            
                            Text("Lv. \(member.level)")
                                .font(AppTypography.caption2)
                                .foregroundColor(AppColors.textTertiary)
                        }
                        .padding(.vertical, AppSpacing.xxs)
                    }
                }
                .cardStyle()
                
                // Leave group
                Button {
                    showingLeaveConfirm = true
                } label: {
                    Text("Leave Group")
                        .font(AppTypography.subheadline)
                        .foregroundColor(AppColors.danger)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.md)
                        .background(AppColors.danger.opacity(0.1))
                        .cornerRadius(AppSpacing.radiusMd)
                }
            }
            .padding(.horizontal, AppSpacing.screenPadding)
            .padding(.bottom, AppSpacing.xxl)
        }
        .background(AppColors.background)
        .navigationTitle(group.name)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            isLoading = true
            async let lb: () = groupService.fetchLeaderboard(for: group.id)
            async let mb = groupService.fetchMemberProfiles(for: group.memberIds)
            _ = await lb
            members = await mb
            leaderboard = groupService.groupLeaderboards[group.id] ?? []
            isLoading = false
        }
        .alert("Leave Group?", isPresented: $showingLeaveConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Leave", role: .destructive) {
                Task {
                    await groupService.leaveGroup(group.id)
                    dismiss()
                }
            }
        } message: {
            Text("You can be re-invited later.")
        }
    }
    
    private func leaderboardRow(entry: GroupLeaderboardEntry, position: Int) -> some View {
        HStack(spacing: AppSpacing.md) {
            // Position
            Text("#\(position)")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(position <= 3 ? AppColors.warning : AppColors.textTertiary)
                .frame(width: 30, alignment: .leading)
            
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: AppSpacing.xs) {
                    Text(entry.displayName)
                        .font(AppTypography.subheadline)
                        .foregroundColor(entry.isCurrentUser ? AppColors.textPrimary : AppColors.textSecondary)
                        .fontWeight(entry.isCurrentUser ? .bold : .regular)
                    if entry.isCurrentUser {
                        Text("YOU")
                            .font(.system(size: 8, weight: .heavy))
                            .foregroundColor(AppColors.brandPrimary)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(AppColors.brandPrimary.opacity(0.15))
                            .cornerRadius(3)
                    }
                }
                if !entry.username.isEmpty {
                    Text("@\(entry.username)")
                        .font(AppTypography.caption2)
                        .foregroundColor(AppColors.textTertiary)
                }
            }
            
            Spacer()
            
            Text("+\(entry.weeklyRP) RP")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(entry.isCurrentUser ? AppColors.brandPrimary : AppColors.textSecondary)
        }
        .padding(.vertical, AppSpacing.xs)
        .background(entry.isCurrentUser ? AppColors.brandPrimary.opacity(0.06) : Color.clear)
        .cornerRadius(AppSpacing.radiusSm)
    }
}

// MARK: - Add Friend Sheet
struct AddFriendSheet: View {
    @EnvironmentObject var userData: UserData
    @StateObject private var friendService = FriendService.shared
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    @State private var requestSentTo: Set<String> = []
    
    var body: some View {
        NavigationStack {
            VStack(spacing: AppSpacing.lg) {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Find by Username")
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.textPrimary)
                    
                    HStack {
                        TextField("Enter username", text: $searchText)
                            .textFieldStyle(.roundedBorder)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .onSubmit { performSearch() }
                        
                        Button { performSearch() } label: {
                            if friendService.isSearching {
                                ProgressView()
                            } else {
                                Image(systemName: "magnifyingglass")
                            }
                        }
                        .disabled(friendService.isSearching || searchText.isEmpty)
                        .padding(.horizontal, AppSpacing.sm)
                    }
                    
                    // Your username hint
                    if !userData.profile.username.isEmpty {
                        Text("Your username: @\(userData.profile.username)")
                            .font(AppTypography.caption2)
                            .foregroundColor(AppColors.textTertiary)
                    } else {
                        Text("Set your username in Settings so friends can find you!")
                            .font(AppTypography.caption2)
                            .foregroundColor(AppColors.warning)
                    }
                }
                
                // Error
                if let error = friendService.searchError {
                    Text(error)
                        .font(AppTypography.caption1)
                        .foregroundColor(AppColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.md)
                }
                
                // Search results
                ForEach(friendService.searchResults) { profile in
                    HStack {
                        ZStack {
                            Circle()
                                .fill(AppColors.brandPrimary.opacity(0.2))
                                .frame(width: 40, height: 40)
                            Text(String(profile.displayName.prefix(2)).uppercased())
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(AppColors.brandPrimary)
                        }
                        
                        VStack(alignment: .leading, spacing: 0) {
                            Text(profile.displayName)
                                .font(AppTypography.subheadline)
                                .foregroundColor(AppColors.textPrimary)
                            if !profile.username.isEmpty {
                                Text("@\(profile.username)")
                                    .font(AppTypography.caption2)
                                    .foregroundColor(AppColors.textTertiary)
                            }
                        }
                        
                        Spacer()
                        
                        if userData.friends.contains(profile.id) {
                            Text("Already Friends")
                                .font(AppTypography.caption1)
                                .foregroundColor(AppColors.success)
                        } else if requestSentTo.contains(profile.id) {
                            Text("Request Sent")
                                .font(AppTypography.caption1)
                                .foregroundColor(AppColors.success)
                        } else {
                            Button {
                                Task {
                                    if await friendService.sendFriendRequest(to: profile.id) {
                                        requestSentTo.insert(profile.id)
                                    }
                                }
                            } label: {
                                Text("Add Friend")
                                    .font(AppTypography.caption1)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, AppSpacing.sm)
                                    .padding(.vertical, AppSpacing.xs)
                                    .background(AppColors.brandPrimary)
                                    .cornerRadius(AppSpacing.radiusSm)
                            }
                        }
                    }
                    .padding()
                    .background(AppColors.surface)
                    .cornerRadius(AppSpacing.radiusMd)
                }
                
                Spacer()
            }
            .padding(AppSpacing.screenPadding)
            .background(AppColors.background)
            .navigationTitle("Add Friend")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private func performSearch() {
        Task {
            await friendService.searchByUsername(searchText)
        }
    }
}

// MARK: - Create Group Sheet
struct CreateGroupSheet: View {
    @EnvironmentObject var userData: UserData
    @StateObject private var groupService = GroupService.shared
    @Environment(\.dismiss) var dismiss
    @State private var groupName = ""
    @State private var selectedFriendIds: Set<String> = []
    @State private var isCreating = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: AppSpacing.lg) {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Group Name")
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.textPrimary)
                    
                    TextField("Enter group name", text: $groupName)
                        .textFieldStyle(.roundedBorder)
                }
                
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Invite Friends")
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.textPrimary)
                    
                    if userData.friends.isEmpty {
                        Text("Add friends first to invite them to your group")
                            .font(AppTypography.caption1)
                            .foregroundColor(AppColors.textSecondary)
                    } else {
                        ForEach(userData.friends, id: \.self) { friendId in
                            let isSelected = selectedFriendIds.contains(friendId)
                            Button {
                                if isSelected {
                                    selectedFriendIds.remove(friendId)
                                } else {
                                    selectedFriendIds.insert(friendId)
                                }
                            } label: {
                                HStack {
                                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(isSelected ? AppColors.brandPrimary : AppColors.textTertiary)
                                    
                                    Text(friendId.prefix(12) + (friendId.count > 12 ? "..." : ""))
                                        .font(AppTypography.subheadline)
                                        .foregroundColor(AppColors.textPrimary)
                                    
                                    Spacer()
                                }
                            }
                            .padding(.vertical, AppSpacing.xs)
                        }
                    }
                }
                
                Spacer()
                
                Button {
                    isCreating = true
                    Task {
                        _ = await groupService.createGroup(
                            name: groupName,
                            invitedFriendIds: Array(selectedFriendIds)
                        )
                        isCreating = false
                        dismiss()
                    }
                } label: {
                    HStack {
                        if isCreating {
                            ProgressView()
                                .tint(.white)
                        }
                        Text("Create Group")
                    }
                    .font(AppTypography.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.md)
                    .background(groupName.isEmpty ? AppColors.textTertiary : AppColors.brandPrimary)
                    .cornerRadius(AppSpacing.radiusMd)
                }
                .disabled(groupName.isEmpty || isCreating)
            }
            .padding(AppSpacing.screenPadding)
            .background(AppColors.background)
            .navigationTitle("Create Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    SocialView()
        .environmentObject(UserData.shared)
}
