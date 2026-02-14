import Foundation
import FirebaseFirestore

@MainActor
final class RankLeaderboardService: ObservableObject {
    static let shared = RankLeaderboardService()
    
    // MARK: - Published State
    
    /// Cached player entries per rank
    @Published private(set) var rankPlayers: [Rank: [RankPlayerEntry]] = [:]
    
    /// Total player count per rank (from Firestore count aggregation)
    @Published private(set) var rankTotalCounts: [Rank: Int] = [:]
    
    /// Ranks currently being loaded
    @Published private(set) var loadingRanks: Set<Rank> = []
    
    /// Ranks that have more players to load beyond what's cached
    @Published private(set) var hasMorePlayers: [Rank: Bool] = [:]
    
    /// Error messages per rank (nil = no error)
    @Published private(set) var rankErrors: [Rank: String] = [:]
    
    // MARK: - Private State
    
    private let db = Firestore.firestore()
    private let pageSize = 50
    
    /// Last document snapshot per rank for cursor-based pagination
    private var lastDocuments: [Rank: DocumentSnapshot] = [:]
    
    /// Timestamp of last fetch per rank (for cache invalidation)
    private var lastFetchTimes: [Rank: Date] = [:]
    
    /// Cache TTL in seconds (5 minutes)
    private let cacheTTL: TimeInterval = 300
    
    private init() {}
    
    // MARK: - Public API
    
    /// Fetch the first page of players for a rank. Uses cache if fresh.
    func fetchPlayers(for rank: Rank, forceRefresh: Bool = false) async {
        // Return cached data if fresh and not force-refreshing
        if !forceRefresh,
           let lastFetch = lastFetchTimes[rank],
           Date().timeIntervalSince(lastFetch) < cacheTTL,
           rankPlayers[rank] != nil {
            return
        }
        
        // Clear previous data for fresh fetch
        rankPlayers[rank] = []
        lastDocuments[rank] = nil
        rankErrors[rank] = nil
        loadingRanks.insert(rank)
        
        defer { loadingRanks.remove(rank) }
        
        do {
            let query = buildQuery(for: rank, startAfter: nil)
            let snapshot = try await query.getDocuments()
            
            let currentUserId = AuthService.shared.userId
            let entries = snapshot.documents.compactMap { doc -> RankPlayerEntry? in
                parsePlayerEntry(from: doc, currentUserId: currentUserId)
            }
            
            rankPlayers[rank] = entries
            hasMorePlayers[rank] = snapshot.documents.count >= pageSize
            lastFetchTimes[rank] = Date()
            
            if let lastDoc = snapshot.documents.last {
                lastDocuments[rank] = lastDoc
            }
            
            // Fetch total count in parallel (fire-and-forget update)
            Task {
                await fetchPlayerCount(for: rank)
            }
        } catch {
            print("RankLeaderboardService: Failed to fetch players for \(rank) - \(error)")
            rankErrors[rank] = "Failed to load players"
        }
    }
    
    /// Load the next page of players for a rank (append to existing list).
    func fetchMorePlayers(for rank: Rank) async {
        guard let lastDoc = lastDocuments[rank],
              hasMorePlayers[rank] == true else { return }
        
        loadingRanks.insert(rank)
        defer { loadingRanks.remove(rank) }
        
        do {
            let query = buildQuery(for: rank, startAfter: lastDoc)
            let snapshot = try await query.getDocuments()
            
            let currentUserId = AuthService.shared.userId
            let newEntries = snapshot.documents.compactMap { doc -> RankPlayerEntry? in
                parsePlayerEntry(from: doc, currentUserId: currentUserId)
            }
            
            // Append to existing entries
            var existing = rankPlayers[rank] ?? []
            existing.append(contentsOf: newEntries)
            rankPlayers[rank] = existing
            
            hasMorePlayers[rank] = snapshot.documents.count >= pageSize
            
            if let lastDoc = snapshot.documents.last {
                lastDocuments[rank] = lastDoc
            }
        } catch {
            print("RankLeaderboardService: Failed to fetch more players for \(rank) - \(error)")
        }
    }
    
    /// Fetch the total count of players in a given rank using Firestore aggregation.
    func fetchPlayerCount(for rank: Rank) async {
        do {
            let query = buildCountQuery(for: rank)
            let countQuery = query.count
            let snapshot = try await countQuery.getAggregation(source: .server)
            rankTotalCounts[rank] = Int(truncating: snapshot.count)
        } catch {
            print("RankLeaderboardService: Failed to count players for \(rank) - \(error)")
            // Fallback: use cached array count if available
            if let cached = rankPlayers[rank] {
                rankTotalCounts[rank] = cached.count
            }
        }
    }
    
    /// Fetch counts for all ranks (used on view appear for badge display).
    func fetchAllRankCounts() async {
        await withTaskGroup(of: Void.self) { group in
            for rank in Rank.allCases {
                group.addTask { [weak self] in
                    await self?.fetchPlayerCount(for: rank)
                }
            }
        }
    }
    
    /// Invalidate cache for a specific rank.
    func invalidateCache(for rank: Rank) {
        lastFetchTimes[rank] = nil
        lastDocuments[rank] = nil
    }
    
    /// Invalidate all caches.
    func invalidateAllCaches() {
        lastFetchTimes.removeAll()
        lastDocuments.removeAll()
        rankPlayers.removeAll()
        rankTotalCounts.removeAll()
        hasMorePlayers.removeAll()
        rankErrors.removeAll()
    }
    
    // MARK: - Private Helpers
    
    /// Build the Firestore query for players within a rank's RP range.
    private func buildQuery(for rank: Rank, startAfter: DocumentSnapshot?) -> Query {
        var query: Query = db.collection("users")
            .whereField("rankSearchFields.rp", isGreaterThanOrEqualTo: rank.baseRPRequired)
        
        // Add upper bound (except for Diamond which has no ceiling)
        if let nextRank = rank.nextRank {
            query = query.whereField("rankSearchFields.rp", isLessThan: nextRank.baseRPRequired)
        }
        
        query = query
            .order(by: "rankSearchFields.rp", descending: true)
            .limit(to: pageSize)
        
        if let startAfter = startAfter {
            query = query.start(afterDocument: startAfter)
        }
        
        return query
    }
    
    /// Build a count-only query (no limit needed for aggregation).
    private func buildCountQuery(for rank: Rank) -> Query {
        var query: Query = db.collection("users")
            .whereField("rankSearchFields.rp", isGreaterThanOrEqualTo: rank.baseRPRequired)
        
        if let nextRank = rank.nextRank {
            query = query.whereField("rankSearchFields.rp", isLessThan: nextRank.baseRPRequired)
        }
        
        return query
    }
    
    /// Parse a Firestore document into a RankPlayerEntry.
    private func parsePlayerEntry(from document: DocumentSnapshot, currentUserId: String?) -> RankPlayerEntry? {
        guard let data = document.data(),
              let searchFields = data["rankSearchFields"] as? [String: Any],
              let rp = searchFields["rp"] as? Int else {
            return nil
        }
        
        let displayName = searchFields["displayName"] as? String ?? "Runner"
        let username = searchFields["username"] as? String ?? ""
        let level = searchFields["level"] as? Int ?? 1
        
        return RankPlayerEntry(
            id: document.documentID,
            displayName: displayName,
            username: username,
            rp: rp,
            level: level,
            isCurrentUser: document.documentID == currentUserId
        )
    }
}
