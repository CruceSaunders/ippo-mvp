import Foundation

// MARK: - Group
struct IppoGroup: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let ownerUid: String
    var memberIds: [String]
    let createdAt: Date
    
    init(
        id: String = UUID().uuidString,
        name: String,
        ownerUid: String,
        memberIds: [String] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.ownerUid = ownerUid
        self.memberIds = memberIds
        self.createdAt = createdAt
    }
}

// MARK: - Group Leaderboard Entry
struct GroupLeaderboardEntry: Identifiable, Equatable {
    let id: String          // uid
    let displayName: String
    let username: String
    let weeklyRP: Int
    let isCurrentUser: Bool
}

// MARK: - Friend Profile (for display in friends list)
struct FriendProfile: Identifiable, Equatable {
    let id: String          // uid
    let displayName: String
    let username: String
    let rp: Int
    let level: Int
    let isCurrentUser: Bool
}
