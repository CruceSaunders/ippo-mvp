import Foundation
import Combine
import FirebaseFirestore

enum UsernameCheckResult {
    case available
    case taken
    case error(String)
}

@MainActor
final class FriendService: ObservableObject {
    static let shared = FriendService()
    
    @Published var friendProfiles: [FriendProfile] = []
    @Published var isLoading = false
    @Published var searchResults: [FriendProfile] = []
    @Published var isSearching = false
    @Published var searchError: String?
    
    private let db = Firestore.firestore()
    
    private init() {}
    
    // MARK: - Username Validation
    func isUsernameTaken(_ username: String) async -> Bool {
        guard !username.isEmpty else { return false }
        
        do {
            let snapshot = try await db.collection("users")
                .whereField("rankSearchFields.username", isEqualTo: username.lowercased())
                .limit(to: 1)
                .getDocuments()
            
            // If a doc exists and it's not the current user, the username is taken
            for doc in snapshot.documents {
                if doc.documentID != AuthService.shared.userId {
                    return true
                }
            }
            return false
        } catch {
            return false
        }
    }
    
    /// Checks username availability with proper error distinction.
    /// Unlike `isUsernameTaken`, this returns `.error` on network failure instead of silently allowing duplicates.
    func checkUsernameAvailability(_ username: String) async -> UsernameCheckResult {
        guard !username.isEmpty else { return .available }
        
        do {
            let snapshot = try await db.collection("users")
                .whereField("rankSearchFields.username", isEqualTo: username.lowercased())
                .limit(to: 1)
                .getDocuments()
            
            for doc in snapshot.documents {
                if doc.documentID != AuthService.shared.userId {
                    return .taken
                }
            }
            return .available
        } catch {
            return .error("Couldn't verify username. Check your connection.")
        }
    }
    
    // MARK: - Search by Username (prefix-based, as-you-type)
    func searchByUsername(_ username: String) async {
        guard !username.isEmpty else {
            searchResults = []
            searchError = nil
            return
        }
        guard let currentUid = AuthService.shared.userId else { return }
        
        isSearching = true
        searchError = nil
        defer { isSearching = false }
        
        let lowered = username.lowercased()
        let endPrefix = lowered + "\u{f8ff}"
        
        do {
            let snapshot = try await db.collection("users")
                .whereField("rankSearchFields.username", isGreaterThanOrEqualTo: lowered)
                .whereField("rankSearchFields.username", isLessThan: endPrefix)
                .limit(to: 15)
                .getDocuments()
            
            searchResults = snapshot.documents.compactMap { doc -> FriendProfile? in
                let data = doc.data()
                guard let searchFields = data["rankSearchFields"] as? [String: Any] else { return nil }
                guard doc.documentID != currentUid else { return nil }
                
                let displayName = searchFields["displayName"] as? String ?? "Runner"
                let username = searchFields["username"] as? String ?? ""
                let rp = searchFields["rp"] as? Int ?? 0
                let level = searchFields["level"] as? Int ?? 1
                
                return FriendProfile(
                    id: doc.documentID,
                    displayName: displayName,
                    username: username,
                    rp: rp,
                    level: level,
                    isCurrentUser: false
                )
            }
            
            if searchResults.isEmpty {
                searchError = "No users found matching \"\(username)\""
            }
        } catch {
            print("FriendService: Search failed - \(error)")
            searchError = "Search failed. Try again."
        }
    }
    
    // MARK: - Send Friend Request
    func sendFriendRequest(to targetUid: String) async -> Bool {
        guard let currentUid = AuthService.shared.userId else { return false }
        
        // Check if already friends
        if UserData.shared.friends.contains(targetUid) {
            return false
        }
        
        // Check if request already sent (read target's friendRequests)
        do {
            let targetDoc = try await db.collection("users").document(targetUid).getDocument()
            if let data = targetDoc.data(),
               let existingRequests = data["friendRequests"] as? [String],
               existingRequests.contains(currentUid) {
                return false  // Already sent
            }
            
            // Also check if they already sent us a request (auto-accept)
            if let data = targetDoc.data(),
               let theirFriends = data["friends"] as? [String],
               theirFriends.contains(currentUid) {
                return false  // Already friends
            }
        } catch {
            // Continue with sending if check fails
        }
        
        do {
            try await db.collection("users").document(targetUid).updateData([
                "friendRequests": FieldValue.arrayUnion([currentUid])
            ])
            return true
        } catch {
            print("FriendService: Failed to send friend request - \(error)")
            return false
        }
    }
    
    // MARK: - Accept Friend Request
    func acceptFriendRequest(from senderUid: String) async {
        guard let currentUid = AuthService.shared.userId else { return }
        
        let userData = UserData.shared
        
        do {
            // Add each other as friends
            let batch = db.batch()
            
            let myDoc = db.collection("users").document(currentUid)
            batch.updateData([
                "friends": FieldValue.arrayUnion([senderUid]),
                "friendRequests": FieldValue.arrayRemove([senderUid])
            ], forDocument: myDoc)
            
            let theirDoc = db.collection("users").document(senderUid)
            batch.updateData([
                "friends": FieldValue.arrayUnion([currentUid])
            ], forDocument: theirDoc)
            
            try await batch.commit()
            
            // Update local state
            userData.addFriend(senderUid)
            userData.friendRequests.removeAll { $0 == senderUid }
            userData.save()
            
        } catch {
            print("FriendService: Failed to accept friend request - \(error)")
        }
    }
    
    // MARK: - Remove Friend
    func removeFriend(_ friendUid: String) async {
        guard let currentUid = AuthService.shared.userId else { return }
        
        let userData = UserData.shared
        
        do {
            let batch = db.batch()
            
            let myDoc = db.collection("users").document(currentUid)
            batch.updateData([
                "friends": FieldValue.arrayRemove([friendUid])
            ], forDocument: myDoc)
            
            let theirDoc = db.collection("users").document(friendUid)
            batch.updateData([
                "friends": FieldValue.arrayRemove([currentUid])
            ], forDocument: theirDoc)
            
            try await batch.commit()
            
            // Update local state
            userData.removeFriend(friendUid)
            friendProfiles.removeAll { $0.id == friendUid }
            
        } catch {
            print("FriendService: Failed to remove friend - \(error)")
        }
    }
    
    // MARK: - Load Friend Profiles
    func loadFriendProfiles() async {
        let userData = UserData.shared
        guard !userData.friends.isEmpty else {
            friendProfiles = []
            return
        }
        guard let currentUid = AuthService.shared.userId else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        var profiles: [FriendProfile] = []
        
        for friendUid in userData.friends {
            do {
                let doc = try await db.collection("users").document(friendUid).getDocument()
                guard let data = doc.data(),
                      let searchFields = data["rankSearchFields"] as? [String: Any] else { continue }
                
                let displayName = searchFields["displayName"] as? String ?? "Runner"
                let username = searchFields["username"] as? String ?? ""
                let rp = searchFields["rp"] as? Int ?? 0
                let level = searchFields["level"] as? Int ?? 1
                
                profiles.append(FriendProfile(
                    id: friendUid,
                    displayName: displayName,
                    username: username,
                    rp: rp,
                    level: level,
                    isCurrentUser: friendUid == currentUid
                ))
            } catch {
                print("FriendService: Failed to load profile for \(friendUid) - \(error)")
            }
        }
        
        friendProfiles = profiles
    }
    
    // MARK: - Fetch Single Profile
    func fetchProfile(uid: String) async -> FriendProfile? {
        do {
            let doc = try await db.collection("users").document(uid).getDocument()
            guard let data = doc.data(),
                  let searchFields = data["rankSearchFields"] as? [String: Any] else { return nil }
            
            let displayName = searchFields["displayName"] as? String ?? "Runner"
            let username = searchFields["username"] as? String ?? ""
            let rp = searchFields["rp"] as? Int ?? 0
            let level = searchFields["level"] as? Int ?? 1
            
            return FriendProfile(
                id: uid,
                displayName: displayName,
                username: username,
                rp: rp,
                level: level,
                isCurrentUser: uid == AuthService.shared.userId
            )
        } catch {
            return nil
        }
    }
    
    // MARK: - Cleanup Before Account Deletion
    /// Removes user from all friends' friend lists
    func removeUserFromAllFriends() async {
        guard let currentUid = AuthService.shared.userId else { return }
        let userData = UserData.shared
        
        let batch = db.batch()
        
        // Remove self from each friend's friends array
        for friendUid in userData.friends {
            let friendDoc = db.collection("users").document(friendUid)
            batch.updateData([
                "friends": FieldValue.arrayRemove([currentUid])
            ], forDocument: friendDoc)
        }
        
        do {
            try await batch.commit()
        } catch {
            print("FriendService: Failed to clean up friends - \(error)")
        }
        
        friendProfiles = []
    }
    
    // MARK: - Refresh Friend Requests
    func refreshFriendRequests() async {
        guard let currentUid = AuthService.shared.userId else { return }
        
        do {
            let doc = try await db.collection("users").document(currentUid).getDocument()
            guard let data = doc.data() else { return }
            
            if let requests = data["friendRequests"] as? [String] {
                UserData.shared.friendRequests = requests
            }
            if let friends = data["friends"] as? [String] {
                UserData.shared.friends = friends
            }
        } catch {
            print("FriendService: Failed to refresh friend requests - \(error)")
        }
    }
}
