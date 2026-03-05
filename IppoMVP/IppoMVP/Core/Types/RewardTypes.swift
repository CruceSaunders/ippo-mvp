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
    case encounterCharm
    case coinBoost
    case hibernation
    case streakFreeze
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
                id: "encounter_charm", type: .encounterCharm,
                name: "Encounter Charm",
                description: "Better chance to find a pet next run",
                cost: config.encounterCharmCost, iconName: "sparkles"
            ),
            ShopItem(
                id: "coin_boost", type: .coinBoost,
                name: "Golden Stride",
                description: "+40% coins earned next run",
                cost: config.coinBoostCost, iconName: "star.circle.fill"
            ),
            ShopItem(
                id: "hibernation", type: .hibernation,
                name: "Hibernation",
                description: "Freeze mood & runaway for 7 days",
                cost: config.hibernationCost, iconName: "moon.zzz.fill"
            ),
            ShopItem(
                id: "streak_freeze", type: .streakFreeze,
                name: "Streak Shield",
                description: "Protect your streak for 3 days",
                cost: config.streakFreezeCost, iconName: "shield.fill"
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
    var streakFreezeEndsAt: Date?

    init(
        food: Int = EconomyConfig.shared.startingFood,
        water: Int = EconomyConfig.shared.startingWater,
        activeBoosts: [ActiveBoost] = [],
        hibernationEndsAt: Date? = nil,
        streakFreezeEndsAt: Date? = nil
    ) {
        self.food = food
        self.water = water
        self.activeBoosts = activeBoosts
        self.hibernationEndsAt = hibernationEndsAt
        self.streakFreezeEndsAt = streakFreezeEndsAt
    }

    var isHibernating: Bool {
        guard let ends = hibernationEndsAt else { return false }
        return Date() < ends
    }

    var isStreakFrozen: Bool {
        guard let ends = streakFreezeEndsAt else { return false }
        return Date() < ends
    }

    var activeXPBoost: ActiveBoost? {
        activeBoosts.first { $0.type == .xpBoost && $0.isActive }
    }

    var activeEncounterCharm: ActiveBoost? {
        activeBoosts.first { $0.type == .encounterCharm && $0.isActive }
    }

    var activeCoinBoost: ActiveBoost? {
        activeBoosts.first { $0.type == .coinBoost && $0.isActive }
    }

    // Legacy support
    var activeEncounterBoost: ActiveBoost? {
        activeBoosts.first { $0.type == .encounterBoost && $0.isActive }
    }

    mutating func cleanExpiredBoosts() {
        activeBoosts.removeAll { !$0.isActive }
        if let ends = hibernationEndsAt, Date() >= ends {
            hibernationEndsAt = nil
        }
        if let ends = streakFreezeEndsAt, Date() >= ends {
            streakFreezeEndsAt = nil
        }
    }

    mutating func consumePerRunBoosts() {
        activeBoosts.removeAll { $0.type == .encounterCharm || $0.type == .coinBoost }
    }
}
