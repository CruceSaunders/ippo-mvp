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
                                .onAppear {
                                    Task {
                                        await friendService.refreshFriendRequests()
                                        await friendService.loadFriendProfiles()
                                    }
                                }
                        } else {
                            groupsSection
                                .onAppear {
                                    Task { await groupService.fetchUserGroups() }
                                }
                        }
                    }
                    .padding(.horizontal, AppSpacing.screenPadding)
                    .padding(.top, AppSpacing.md)
                    .padding(.bottom, AppSpacing.xxl)
                }
                .refreshable {
                    if selectedSection == 0 {
                        await friendService.refreshFriendRequests()
                        await friendService.loadFriendProfiles()
                    } else {
                        await groupService.fetchUserGroups()
                    }
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
            .onAppear {
                friendService.startListening()
            }
            .onDisappear {
                friendService.stopListening()
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
                        FriendRequestRow(requestUid: requestUid, friendService: friendService)
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
    @EnvironmentObject var userData: UserData
    @StateObject private var groupService = GroupService.shared
    @State private var leaderboard: [GroupLeaderboardEntry] = []
    @State private var members: [FriendProfile] = []
    @State private var isLoading = true
    @State private var showingLeaveConfirm = false
    @State private var showingDeleteConfirm = false
    @State private var showingInviteFriends = false
    @State private var showingRenameAlert = false
    @State private var newGroupName = ""
    @State private var memberToKick: FriendProfile?
    @State private var showingKickConfirm = false
    @Environment(\.dismiss) var dismiss
    
    private var isOwner: Bool {
        group.ownerUid == AuthService.shared.userId
    }
    
    /// Friends who are not already in this group
    private var invitableFriends: [String] {
        let currentMembers = Set(group.memberIds)
        return UserData.shared.friends.filter { !currentMembers.contains($0) }
    }
    
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
                    
                    if isOwner {
                        Button {
                            newGroupName = group.name
                            showingRenameAlert = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "pencil")
                                Text("Rename")
                            }
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(AppColors.brandPrimary)
                        }
                    }
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
                    HStack {
                        Text("Members")
                            .font(AppTypography.headline)
                            .foregroundColor(AppColors.textPrimary)
                        Spacer()
                        if !invitableFriends.isEmpty {
                            Button {
                                showingInviteFriends = true
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "person.badge.plus")
                                    Text("Invite")
                                }
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(AppColors.brandPrimary)
                            }
                        }
                    }
                    
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
                                    if member.id == group.ownerUid {
                                        Text("HOST")
                                            .font(.system(size: 8, weight: .heavy))
                                            .foregroundColor(AppColors.warning)
                                            .padding(.horizontal, 4)
                                            .padding(.vertical, 2)
                                            .background(AppColors.warning.opacity(0.15))
                                            .cornerRadius(3)
                                    }
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
                            
                            if isOwner && !member.isCurrentUser {
                                Button {
                                    memberToKick = member
                                    showingKickConfirm = true
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(AppColors.textTertiary)
                                        .font(.system(size: 16))
                                }
                            }
                        }
                        .padding(.vertical, AppSpacing.xxs)
                    }
                }
                .cardStyle()
                
                // Leave or delete group
                if isOwner {
                    Button {
                        showingDeleteConfirm = true
                    } label: {
                        Text("Delete Group")
                            .font(AppTypography.subheadline)
                            .foregroundColor(AppColors.danger)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppSpacing.md)
                            .background(AppColors.danger.opacity(0.1))
                            .cornerRadius(AppSpacing.radiusMd)
                    }
                } else {
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
        .alert("Delete Group?", isPresented: $showingDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    await groupService.deleteGroup(group.id)
                    dismiss()
                }
            }
        } message: {
            Text("This will permanently delete the group and its leaderboard for all members.")
        }
        .sheet(isPresented: $showingInviteFriends) {
            InviteToGroupSheet(group: group) {
                Task {
                    members = await groupService.fetchMemberProfiles(for: group.memberIds)
                }
            }
        }
        .alert("Rename Group", isPresented: $showingRenameAlert) {
            TextField("Group name", text: $newGroupName)
            Button("Cancel", role: .cancel) {}
            Button("Save") {
                guard !newGroupName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                Task {
                    await groupService.renameGroup(group.id, newName: newGroupName.trimmingCharacters(in: .whitespaces))
                }
            }
        } message: {
            Text("Enter a new name for this group.")
        }
        .alert("Kick Member?", isPresented: $showingKickConfirm) {
            Button("Cancel", role: .cancel) { memberToKick = nil }
            Button("Kick", role: .destructive) {
                if let member = memberToKick {
                    Task {
                        await groupService.kickMember(uid: member.id, fromGroup: group.id)
                        members.removeAll { $0.id == member.id }
                        memberToKick = nil
                    }
                }
            }
        } message: {
            Text("Remove \(memberToKick?.displayName ?? "this member") from the group?")
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

// MARK: - Invite to Group Sheet
struct InviteToGroupSheet: View {
    let group: IppoGroup
    var onInvited: () -> Void
    @StateObject private var groupService = GroupService.shared
    @StateObject private var friendService = FriendService.shared
    @Environment(\.dismiss) var dismiss
    @State private var invitedIds: Set<String> = []
    
    private var invitableFriendProfiles: [FriendProfile] {
        let currentMembers = Set(group.memberIds)
        return friendService.friendProfiles.filter { !currentMembers.contains($0.id) }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: AppSpacing.lg) {
                if invitableFriendProfiles.isEmpty {
                    VStack(spacing: AppSpacing.sm) {
                        Image(systemName: "person.2.slash")
                            .font(.largeTitle)
                            .foregroundColor(AppColors.textTertiary)
                        Text("No friends to invite")
                            .font(AppTypography.subheadline)
                            .foregroundColor(AppColors.textSecondary)
                        Text("All your friends are already in this group, or add more friends first.")
                            .font(AppTypography.caption1)
                            .foregroundColor(AppColors.textTertiary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.xxl)
                } else {
                    List {
                        ForEach(invitableFriendProfiles) { friend in
                            HStack {
                                VStack(alignment: .leading, spacing: 0) {
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
                                
                                if invitedIds.contains(friend.id) {
                                    Text("Invited")
                                        .font(AppTypography.caption1)
                                        .foregroundColor(AppColors.success)
                                } else {
                                    Button("Invite") {
                                        Task {
                                            await groupService.inviteFriend(uid: friend.id, toGroup: group.id)
                                            invitedIds.insert(friend.id)
                                        }
                                    }
                                    .font(AppTypography.caption1)
                                    .foregroundColor(AppColors.brandPrimary)
                                }
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .navigationTitle("Invite Friends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        if !invitedIds.isEmpty {
                            onInvited()
                        }
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Add Friend Sheet
struct AddFriendSheet: View {
    @EnvironmentObject var userData: UserData
    @StateObject private var friendService = FriendService.shared
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    @State private var requestSentTo: Set<String> = []
    @State private var searchTask: Task<Void, Never>?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: AppSpacing.lg) {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Find by Username")
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.textPrimary)
                    
                    HStack {
                        TextField("Search username...", text: $searchText)
                            .textFieldStyle(.roundedBorder)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .onChange(of: searchText) { newValue in
                                searchTask?.cancel()
                                searchTask = Task {
                                    try? await Task.sleep(nanoseconds: 400_000_000)
                                    guard !Task.isCancelled else { return }
                                    await friendService.searchByUsername(newValue)
                                }
                            }
                        
                        if friendService.isSearching {
                            ProgressView()
                                .padding(.horizontal, AppSpacing.sm)
                        }
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
    
}

// MARK: - Create Group Sheet
struct CreateGroupSheet: View {
    @EnvironmentObject var userData: UserData
    @StateObject private var groupService = GroupService.shared
    @StateObject private var friendService = FriendService.shared
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
                        ForEach(friendService.friendProfiles) { friend in
                            let isSelected = selectedFriendIds.contains(friend.id)
                            Button {
                                if isSelected {
                                    selectedFriendIds.remove(friend.id)
                                } else {
                                    selectedFriendIds.insert(friend.id)
                                }
                            } label: {
                                HStack {
                                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(isSelected ? AppColors.brandPrimary : AppColors.textTertiary)
                                    
                                    VStack(alignment: .leading, spacing: 0) {
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
                                }
                            }
                            .padding(.vertical, AppSpacing.xs)
                        }
                    }
                }
                
                Spacer()
                
                // Group limit warning
                if !groupService.canCreateGroup {
                    Text("You've reached the maximum of \(GroupService.maxGroups) groups.")
                        .font(AppTypography.caption1)
                        .foregroundColor(AppColors.danger)
                        .multilineTextAlignment(.center)
                }
                
                if let error = groupService.createError {
                    Text(error)
                        .font(AppTypography.caption1)
                        .foregroundColor(AppColors.danger)
                }
                
                Button {
                    isCreating = true
                    Task {
                        _ = await groupService.createGroup(
                            name: groupName,
                            invitedFriendIds: Array(selectedFriendIds)
                        )
                        isCreating = false
                        if groupService.createError == nil {
                            dismiss()
                        }
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
                    .background((groupName.isEmpty || !groupService.canCreateGroup) ? AppColors.textTertiary : AppColors.brandPrimary)
                    .cornerRadius(AppSpacing.radiusMd)
                }
                .disabled(groupName.isEmpty || isCreating || !groupService.canCreateGroup)
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

// MARK: - Friend Request Row (loads profile for display name)
struct FriendRequestRow: View {
    let requestUid: String
    let friendService: FriendService
    @State private var profile: FriendProfile?
    
    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(AppColors.brandPrimary.opacity(0.2))
                    .frame(width: 40, height: 40)
                if let p = profile {
                    Text(String(p.displayName.prefix(2)).uppercased())
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppColors.brandPrimary)
                } else {
                    Image(systemName: "person.fill.questionmark")
                        .font(.system(size: 16))
                        .foregroundColor(AppColors.brandPrimary)
                }
            }
            
            VStack(alignment: .leading) {
                Text(profile?.displayName ?? "Loading...")
                    .font(AppTypography.subheadline)
                    .foregroundColor(AppColors.textPrimary)
                if let username = profile?.username, !username.isEmpty {
                    Text("@\(username)")
                        .font(AppTypography.caption2)
                        .foregroundColor(AppColors.textTertiary)
                } else {
                    Text("Wants to be your friend")
                        .font(AppTypography.caption2)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            
            Spacer()
            
            Button {
                Task {
                    await friendService.acceptFriendRequest(from: requestUid)
                    await friendService.refreshFriendRequests()
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
        .task {
            profile = await friendService.fetchProfile(uid: requestUid)
        }
    }
}

#Preview {
    SocialView()
        .environmentObject(UserData.shared)
}
