import Foundation

// MARK: - RP Box (Loot Box for Reputation Points)
struct RPBox: Identifiable, Codable, Equatable {
    let id: String
    let earnedAt: Date
    var isOpened: Bool
    
    init(
        id: String = UUID().uuidString,
        earnedAt: Date = Date(),
        isOpened: Bool = false
    ) {
        self.id = id
        self.earnedAt = earnedAt
        self.isOpened = isOpened
    }
}

// MARK: - RP Box Contents
struct RPBoxContents: Equatable {
    let rpAmount: Int
    let tier: RPBoxTier
    
    /// Weighted random RP distribution (1-25 RP per box)
    /// Uses gacha-style weighting for exciting opening moments
    static func generate() -> RPBoxContents {
        let roll = Double.random(in: 0...1)
        
        if roll < 0.50 {
            // Common: 1-5 RP (50% chance)
            let rp = Int.random(in: 1...5)
            return RPBoxContents(rpAmount: rp, tier: .common)
        } else if roll < 0.75 {
            // Uncommon: 6-10 RP (25% chance)
            let rp = Int.random(in: 6...10)
            return RPBoxContents(rpAmount: rp, tier: .uncommon)
        } else if roll < 0.90 {
            // Rare: 11-15 RP (15% chance)
            let rp = Int.random(in: 11...15)
            return RPBoxContents(rpAmount: rp, tier: .rare)
        } else if roll < 0.97 {
            // Epic: 16-20 RP (7% chance)
            let rp = Int.random(in: 16...20)
            return RPBoxContents(rpAmount: rp, tier: .epic)
        } else {
            // Legendary: 21-25 RP (3% chance)
            let rp = Int.random(in: 21...25)
            return RPBoxContents(rpAmount: rp, tier: .legendary)
        }
    }
}

// MARK: - RP Box Tier
enum RPBoxTier: String, Codable, CaseIterable {
    case common
    case uncommon
    case rare
    case epic
    case legendary
    
    var displayName: String {
        switch self {
        case .common: return "Common"
        case .uncommon: return "Uncommon"
        case .rare: return "Rare"
        case .epic: return "Epic"
        case .legendary: return "Legendary"
        }
    }
    
    var color: String {
        switch self {
        case .common: return "gray"
        case .uncommon: return "green"
        case .rare: return "blue"
        case .epic: return "purple"
        case .legendary: return "gold"
        }
    }
}
