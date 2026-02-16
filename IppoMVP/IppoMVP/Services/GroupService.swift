import Foundation
import Combine
import FirebaseFirestore

@MainActor
final class GroupService: ObservableObject {
    static let shared = GroupService()
    
    @Published var userGroups: [IppoGroup] = []
    @Published var isLoading = false
    @Published var groupLeaderboards: [String: [GroupLeaderboardEntry]] = [:]  // groupId -> entries
    @Published var createError: String?
    
    static let maxGroups = 5
    
    private let db = Firestore.firestore()
    
    private init() {}
    
    var canCreateGroup: Bool {
        userGroups.count < Self.maxGroups
    }
    
    // MARK: - Create Group
    func createGroup(name: String, invitedFriendIds: [String] = []) async -> IppoGroup? {
        guard let uid = AuthService.shared.userId else { return nil }
        
        guard canCreateGroup else {
            createError = "You can only create up to \(Self.maxGroups) groups."
            return nil
        }
        createError = nil
        
        var memberIds = [uid] + invitedFriendIds
        memberIds = Array(Set(memberIds))  // deduplicate
        
        let group = IppoGroup(
            name: name,
            ownerUid: uid,
            memberIds: memberIds
        )
        
        do {
            let data: [String: Any] = [
                "name": group.name,
                "ownerUid": group.ownerUid,
                "memberIds": group.memberIds,
                "createdAt": Timestamp(date: group.createdAt)
            ]
            
            try await db.collection("groups").document(group.id).setData(data)
            
            // Update local state
            userGroups.append(group)
            
            // Initialize leaderboard entry for the creator
            await updateLeaderboardEntry(groupId: group.id)
            
            return group
        } catch {
            print("GroupService: Failed to create group - \(error)")
            return nil
        }
    }
    
    // MARK: - Fetch User's Groups
    func fetchUserGroups() async {
        guard let uid = AuthService.shared.userId else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let snapshot = try await db.collection("groups")
                .whereField("memberIds", arrayContains: uid)
                .order(by: "createdAt", descending: true)
                .getDocuments()
            
            userGroups = snapshot.documents.compactMap { doc -> IppoGroup? in
                let data = doc.data()
                guard let name = data["name"] as? String,
                      let ownerUid = data["ownerUid"] as? String,
                      let memberIds = data["memberIds"] as? [String],
                      let createdTs = data["createdAt"] as? Timestamp else { return nil }
                
                return IppoGroup(
                    id: doc.documentID,
                    name: name,
                    ownerUid: ownerUid,
                    memberIds: memberIds,
                    createdAt: createdTs.dateValue()
                )
            }
        } catch {
            print("GroupService: Failed to fetch groups - \(error)")
        }
    }
    
    // MARK: - Invite Friend to Group
    func inviteFriend(uid friendUid: String, toGroup groupId: String) async {
        do {
            try await db.collection("groups").document(groupId).updateData([
                "memberIds": FieldValue.arrayUnion([friendUid])
            ])
            
            // Update local state
            if let index = userGroups.firstIndex(where: { $0.id == groupId }) {
                if !userGroups[index].memberIds.contains(friendUid) {
                    userGroups[index].memberIds.append(friendUid)
                }
            }
        } catch {
            print("GroupService: Failed to invite friend - \(error)")
        }
    }
    
    // MARK: - Leave Group
    func leaveGroup(_ groupId: String) async {
        guard let uid = AuthService.shared.userId else { return }
        
        do {
            try await db.collection("groups").document(groupId).updateData([
                "memberIds": FieldValue.arrayRemove([uid])
            ])
            
            userGroups.removeAll { $0.id == groupId }
            
            // Auto-delete group if no members left
            let doc = try await db.collection("groups").document(groupId).getDocument()
            if let data = doc.data(),
               let memberIds = data["memberIds"] as? [String],
               memberIds.isEmpty {
                try await db.collection("groups").document(groupId).delete()
            }
        } catch {
            print("GroupService: Failed to leave group - \(error)")
        }
    }
    
    // MARK: - Rename Group (owner only)
    func renameGroup(_ groupId: String, newName: String) async {
        do {
            try await db.collection("groups").document(groupId).updateData([
                "name": newName
            ])
            if let index = userGroups.firstIndex(where: { $0.id == groupId }) {
                userGroups[index] = IppoGroup(
                    id: userGroups[index].id,
                    name: newName,
                    ownerUid: userGroups[index].ownerUid,
                    memberIds: userGroups[index].memberIds,
                    createdAt: userGroups[index].createdAt
                )
            }
        } catch {
            print("GroupService: Failed to rename group - \(error)")
        }
    }
    
    // MARK: - Kick Member (owner only)
    func kickMember(uid memberUid: String, fromGroup groupId: String) async {
        do {
            try await db.collection("groups").document(groupId).updateData([
                "memberIds": FieldValue.arrayRemove([memberUid])
            ])
            if let index = userGroups.firstIndex(where: { $0.id == groupId }) {
                userGroups[index].memberIds.removeAll { $0 == memberUid }
            }
        } catch {
            print("GroupService: Failed to kick member - \(error)")
        }
    }
    
    // MARK: - Delete Group (owner only)
    func deleteGroup(_ groupId: String) async {
        do {
            // Delete the weekly leaderboard sub-collection docs
            let leaderboardDocs = try await db.collection("groups").document(groupId)
                .collection("weeklyLeaderboard").getDocuments()
            for doc in leaderboardDocs.documents {
                try await doc.reference.delete()
            }
            
            // Delete the group document
            try await db.collection("groups").document(groupId).delete()
            
            userGroups.removeAll { $0.id == groupId }
        } catch {
            print("GroupService: Failed to delete group - \(error)")
        }
    }
    
    // MARK: - Weekly Leaderboard
    
    /// Get the start of the current week (Monday midnight)
    private var currentWeekStart: Date {
        let calendar = Calendar.current
        let now = Date()
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
        components.weekday = 2  // Monday
        components.hour = 0
        components.minute = 0
        components.second = 0
        return calendar.date(from: components) ?? now
    }
    
    /// Update the current user's weekly RP entry in a group
    func updateLeaderboardEntry(groupId: String) async {
        guard let uid = AuthService.shared.userId else { return }
        let userData = UserData.shared
        
        let entry: [String: Any] = [
            "displayName": userData.profile.displayName,
            "username": userData.profile.username,
            "weeklyRP": userData.profile.weeklyRP,
            "updatedAt": Timestamp(date: Date()),
            "weekStartDate": Timestamp(date: currentWeekStart)
        ]
        
        do {
            try await db.collection("groups").document(groupId)
                .collection("weeklyLeaderboard").document(uid).setData(entry, merge: true)
        } catch {
            print("GroupService: Failed to update leaderboard - \(error)")
        }
    }
    
    /// Fetch leaderboard for a group (only entries from current week)
    func fetchLeaderboard(for groupId: String) async {
        guard let currentUid = AuthService.shared.userId else { return }
        
        let weekStart = currentWeekStart
        
        do {
            let snapshot = try await db.collection("groups").document(groupId)
                .collection("weeklyLeaderboard")
                .order(by: "weeklyRP", descending: true)
                .getDocuments()
            
            let entries = snapshot.documents.compactMap { doc -> GroupLeaderboardEntry? in
                let data = doc.data()
                
                // Filter to only show current week entries
                if let weekStartTs = data["weekStartDate"] as? Timestamp {
                    let entryWeekStart = weekStartTs.dateValue()
                    // If the entry's week start is before the current week, it's stale
                    if entryWeekStart < weekStart {
                        return nil
                    }
                }
                
                let displayName = data["displayName"] as? String ?? "Runner"
                let username = data["username"] as? String ?? ""
                let weeklyRP = data["weeklyRP"] as? Int ?? 0
                
                // Skip entries with 0 RP
                guard weeklyRP > 0 else { return nil }
                
                return GroupLeaderboardEntry(
                    id: doc.documentID,
                    displayName: displayName,
                    username: username,
                    weeklyRP: weeklyRP,
                    isCurrentUser: doc.documentID == currentUid
                )
            }
            
            groupLeaderboards[groupId] = entries
        } catch {
            print("GroupService: Failed to fetch leaderboard - \(error)")
        }
    }
    
    /// Update leaderboard entries for all groups (call after RP changes)
    func updateAllLeaderboards() async {
        for group in userGroups {
            await updateLeaderboardEntry(groupId: group.id)
        }
    }
    
    // MARK: - Fetch Member Profiles
    func fetchMemberProfiles(for memberIds: [String]) async -> [FriendProfile] {
        guard let currentUid = AuthService.shared.userId else { return [] }
        
        var profiles: [FriendProfile] = []
        
        for uid in memberIds {
            do {
                let doc = try await db.collection("users").document(uid).getDocument()
                guard let data = doc.data(),
                      let searchFields = data["rankSearchFields"] as? [String: Any] else { continue }
                
                let displayName = searchFields["displayName"] as? String ?? "Runner"
                let username = searchFields["username"] as? String ?? ""
                let rp = searchFields["rp"] as? Int ?? 0
                let level = searchFields["level"] as? Int ?? 1
                
                profiles.append(FriendProfile(
                    id: uid,
                    displayName: displayName,
                    username: username,
                    rp: rp,
                    level: level,
                    isCurrentUser: uid == currentUid
                ))
            } catch {
                print("GroupService: Failed to fetch profile for \(uid) - \(error)")
            }
        }
        
        return profiles
    }
}
