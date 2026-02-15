import Foundation
import FirebaseFirestore

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
    
    // MARK: - Search by Username
    func searchByUsername(_ username: String) async {
        guard !username.isEmpty else {
            searchResults = []
            return
        }
        guard let currentUid = AuthService.shared.userId else { return }
        
        isSearching = true
        searchError = nil
        defer { isSearching = false }
        
        do {
            // Search for exact username match (case-insensitive would require a lowercase field)
            let snapshot = try await db.collection("users")
                .whereField("rankSearchFields.username", isEqualTo: username.lowercased())
                .limit(to: 10)
                .getDocuments()
            
            searchResults = snapshot.documents.compactMap { doc -> FriendProfile? in
                let data = doc.data()
                guard let searchFields = data["rankSearchFields"] as? [String: Any] else { return nil }
                
                // Don't show self in results
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
                searchError = "No user found with username \"\(username)\""
            }
        } catch {
            print("FriendService: Search failed - \(error)")
            searchError = "Search failed. Try again."
        }
    }
    
    // MARK: - Send Friend Request
    func sendFriendRequest(to targetUid: String) async -> Bool {
        guard let currentUid = AuthService.shared.userId else { return false }
        
        do {
            // Add current user's UID to the target's friendRequests array
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
