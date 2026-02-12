import Foundation

// MARK: - Loot Box
struct LootBox: Identifiable, Codable, Equatable {
    let id: String
    let rarity: Rarity
    let earnedAt: Date
    var isOpened: Bool
    
    init(
        id: String = UUID().uuidString,
        rarity: Rarity,
        earnedAt: Date = Date(),
        isOpened: Bool = false
    ) {
        self.id = id
        self.rarity = rarity
        self.earnedAt = earnedAt
        self.isOpened = isOpened
    }
}

// MARK: - Loot Box Contents
struct LootBoxContents: Equatable {
    let coins: Int
    let gems: Int
    let rarity: Rarity
    
    static func generate(for rarity: Rarity) -> LootBoxContents {
        switch rarity {
        case .common:
            return LootBoxContents(
                coins: Int.random(in: 50...100),
                gems: 0,
                rarity: rarity
            )
        case .uncommon:
            return LootBoxContents(
                coins: Int.random(in: 100...200),
                gems: Int.random(in: 5...10),
                rarity: rarity
            )
        case .rare:
            return LootBoxContents(
                coins: Int.random(in: 200...400),
                gems: Int.random(in: 10...25),
                rarity: rarity
            )
        case .epic:
            return LootBoxContents(
                coins: Int.random(in: 400...800),
                gems: Int.random(in: 25...50),
                rarity: rarity
            )
        case .legendary:
            return LootBoxContents(
                coins: Int.random(in: 800...1500),
                gems: Int.random(in: 50...100),
                rarity: rarity
            )
        }
    }
}

// MARK: - Shop Item
struct ShopItem: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let type: ShopItemType
    let price: Int
    let currency: Currency
    let iconName: String
    
    init(
        id: String,
        name: String,
        description: String,
        type: ShopItemType,
        price: Int,
        currency: Currency,
        iconName: String = "gift.fill"
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.type = type
        self.price = price
        self.currency = currency
        self.iconName = iconName
    }
}

enum ShopItemType: String, Codable {
    case petFood
    case xpBoost
    case lootBox
}

enum Currency: String, Codable {
    case coins
    case gems
}

// MARK: - Inventory
struct Inventory: Codable, Equatable {
    var lootBoxes: [Rarity: Int]
    var petFood: Int
    var xpBoosts: Int
    
    init(
        lootBoxes: [Rarity: Int] = [:],
        petFood: Int = 0,
        xpBoosts: Int = 0
    ) {
        self.lootBoxes = lootBoxes
        self.petFood = petFood
        self.xpBoosts = xpBoosts
    }
    
    var totalLootBoxes: Int {
        lootBoxes.values.reduce(0, +)
    }
    
    mutating func addLootBox(_ rarity: Rarity) {
        lootBoxes[rarity, default: 0] += 1
    }
    
    mutating func removeLootBox(_ rarity: Rarity) -> Bool {
        guard let count = lootBoxes[rarity], count > 0 else { return false }
        lootBoxes[rarity] = count - 1
        return true
    }
}
