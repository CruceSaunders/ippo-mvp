import Foundation

// MARK: - Sprint Reward (given after each successful sprint)
struct SprintReward {
    let coins: Int
    let xp: Int
    let caughtPetId: String?

    var didCatchPet: Bool { caughtPetId != nil }
}

// MARK: - Shop Item
enum ShopItemType: String, Codable, CaseIterable {
    case food
    case water
    case foodPack
    case waterPack
    case xpBoost
    case encounterBoost
    case hibernation
}

struct ShopItem: Identifiable {
    let id: String
    let type: ShopItemType
    let name: String
    let description: String
    let cost: Int
    let iconName: String

    static let allItems: [ShopItem] = {
        let config = EconomyConfig.shared
        return [
            ShopItem(
                id: "food", type: .food,
                name: "Food", description: "Feed your pet once",
                cost: config.foodCost, iconName: "leaf.fill"
            ),
            ShopItem(
                id: "water", type: .water,
                name: "Water", description: "Give your pet a drink",
                cost: config.waterCost, iconName: "drop.fill"
            ),
            ShopItem(
                id: "food_pack", type: .foodPack,
                name: "Food Pack (x\(config.foodPackCount))",
                description: "\(config.foodPackCount) feedings",
                cost: config.foodPackCost, iconName: "leaf.fill"
            ),
            ShopItem(
                id: "water_pack", type: .waterPack,
                name: "Water Pack (x\(config.waterPackCount))",
                description: "\(config.waterPackCount) drinks",
                cost: config.waterPackCost, iconName: "drop.fill"
            ),
            ShopItem(
                id: "xp_boost", type: .xpBoost,
                name: "XP Boost",
                description: "+30% XP for 2 hours",
                cost: config.xpBoostCost, iconName: "arrow.up.circle.fill"
            ),
            ShopItem(
                id: "encounter_boost", type: .encounterBoost,
                name: "Lucky Charm",
                description: "+50% catch rate next run",
                cost: config.encounterBoostCost, iconName: "sparkles"
            ),
            ShopItem(
                id: "hibernation", type: .hibernation,
                name: "Hibernation",
                description: "Freeze mood & runaway for 7 days",
                cost: config.hibernationCost, iconName: "moon.zzz.fill"
            ),
        ]
    }()
}

// MARK: - Inventory
struct PlayerInventory: Codable, Equatable {
    var food: Int
    var water: Int
    var activeBoosts: [ActiveBoost]
    var hibernationEndsAt: Date?

    init(
        food: Int = EconomyConfig.shared.startingFood,
        water: Int = EconomyConfig.shared.startingWater,
        activeBoosts: [ActiveBoost] = [],
        hibernationEndsAt: Date? = nil
    ) {
        self.food = food
        self.water = water
        self.activeBoosts = activeBoosts
        self.hibernationEndsAt = hibernationEndsAt
    }

    var isHibernating: Bool {
        guard let ends = hibernationEndsAt else { return false }
        return Date() < ends
    }

    var activeXPBoost: ActiveBoost? {
        activeBoosts.first { $0.type == .xpBoost && $0.isActive }
    }

    var activeEncounterBoost: ActiveBoost? {
        activeBoosts.first { $0.type == .encounterBoost && $0.isActive }
    }

    mutating func cleanExpiredBoosts() {
        activeBoosts.removeAll { !$0.isActive }
        if let ends = hibernationEndsAt, Date() >= ends {
            hibernationEndsAt = nil
        }
    }
}
