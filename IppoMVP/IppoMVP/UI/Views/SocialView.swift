import SwiftUI

struct SocialView: View {
    @EnvironmentObject var userData: UserData
    @State private var selectedSection = 0
    @State private var showingAddFriend = false
    @State private var showingCreateGroup = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Segment picker
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
            }
            .sheet(isPresented: $showingCreateGroup) {
                CreateGroupSheet()
            }
        }
    }
    
    // MARK: - Friends Section
    private var friendsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Friend requests
            if !userData.friendRequests.isEmpty {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Friend Requests")
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.textPrimary)
                    
                    ForEach(userData.friendRequests, id: \.self) { requestId in
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(AppColors.brandPrimary.opacity(0.2))
                                    .frame(width: 40, height: 40)
                                Text("?")
                                    .font(AppTypography.headline)
                                    .foregroundColor(AppColors.brandPrimary)
                            }
                            
                            VStack(alignment: .leading) {
                                Text(requestId)
                                    .font(AppTypography.subheadline)
                                    .foregroundColor(AppColors.textPrimary)
                                Text("Wants to be your friend")
                                    .font(AppTypography.caption2)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            
                            Spacer()
                            
                            Button {
                                userData.addFriend(requestId)
                                userData.friendRequests.removeAll { $0 == requestId }
                                userData.save()
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
                Text("Friends (\(userData.friends.count))")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)
                
                if userData.friends.isEmpty {
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
                } else {
                    ForEach(userData.friends, id: \.self) { friendId in
                        friendRow(friendId)
                        
                        if friendId != userData.friends.last {
                            Divider()
                                .background(AppColors.surfaceElevated)
                        }
                    }
                }
            }
            .cardStyle()
        }
    }
    
    private func friendRow(_ friendId: String) -> some View {
        HStack(spacing: AppSpacing.md) {
            ZStack {
                Circle()
                    .fill(AppColors.brandPrimary.opacity(0.2))
                    .frame(width: 40, height: 40)
                Text(String(friendId.prefix(2)).uppercased())
                    .font(AppTypography.caption1)
                    .foregroundColor(AppColors.brandPrimary)
            }
            
            VStack(alignment: .leading, spacing: AppSpacing.xxxs) {
                Text(friendId)
                    .font(AppTypography.subheadline)
                    .foregroundColor(AppColors.textPrimary)
                Text("Friend")
                    .font(AppTypography.caption2)
                    .foregroundColor(AppColors.textTertiary)
            }
            
            Spacer()
            
            Button {
                userData.removeFriend(friendId)
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
                Text("Your Groups")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)
                
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
            }
            .cardStyle()
            
            // Info card about leaderboards
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
}

// MARK: - Add Friend Sheet
struct AddFriendSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    @State private var searchResult: String?
    @State private var isSearching = false
    @State private var requestSent = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: AppSpacing.lg) {
                // Search field
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Find by Username")
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.textPrimary)
                    
                    HStack {
                        TextField("Enter username", text: $searchText)
                            .textFieldStyle(.roundedBorder)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                        
                        Button {
                            // TODO: Search Firestore for username
                            isSearching = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                isSearching = false
                                if !searchText.isEmpty {
                                    searchResult = searchText
                                }
                            }
                        } label: {
                            if isSearching {
                                ProgressView()
                            } else {
                                Image(systemName: "magnifyingglass")
                            }
                        }
                        .padding(.horizontal, AppSpacing.sm)
                    }
                }
                
                // Search result
                if let result = searchResult {
                    HStack {
                        ZStack {
                            Circle()
                                .fill(AppColors.brandPrimary.opacity(0.2))
                                .frame(width: 40, height: 40)
                            Text(String(result.prefix(2)).uppercased())
                                .font(AppTypography.caption1)
                                .foregroundColor(AppColors.brandPrimary)
                        }
                        
                        Text(result)
                            .font(AppTypography.subheadline)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Spacer()
                        
                        if requestSent {
                            Text("Request Sent")
                                .font(AppTypography.caption1)
                                .foregroundColor(AppColors.success)
                        } else {
                            Button {
                                // TODO: Send friend request via Firestore
                                requestSent = true
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
    @Environment(\.dismiss) var dismiss
    @State private var groupName = ""
    
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
                            HStack {
                                Text(friendId)
                                    .font(AppTypography.subheadline)
                                    .foregroundColor(AppColors.textPrimary)
                                Spacer()
                                Button("Invite") {
                                    // TODO: Add to group via Firestore
                                }
                                .font(AppTypography.caption1)
                                .foregroundColor(AppColors.brandPrimary)
                            }
                            .padding(.vertical, AppSpacing.xs)
                        }
                    }
                }
                
                Spacer()
                
                Button {
                    // TODO: Create group in Firestore
                    dismiss()
                } label: {
                    Text("Create Group")
                        .font(AppTypography.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.md)
                        .background(groupName.isEmpty ? AppColors.textTertiary : AppColors.brandPrimary)
                        .cornerRadius(AppSpacing.radiusMd)
                }
                .disabled(groupName.isEmpty)
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
