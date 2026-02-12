import Foundation

@MainActor
final class LootBoxSystem: ObservableObject {
    static let shared = LootBoxSystem()
    
    @Published var isOpening: Bool = false
    @Published var lastContents: LootBoxContents?
    
    private init() {}
    
    // MARK: - Open Loot Box
    func openLootBox(_ rarity: Rarity) async -> LootBoxContents? {
        let userData = UserData.shared
        
        // Check inventory
        guard userData.inventory.lootBoxes[rarity, default: 0] > 0 else { return nil }
        
        isOpening = true
        
        // Animate delay
        try? await Task.sleep(nanoseconds: 1_500_000_000)  // 1.5 seconds
        
        // Open and get contents
        guard let contents = userData.openLootBox(rarity) else {
            isOpening = false
            return nil
        }
        
        lastContents = contents
        isOpening = false
        
        return contents
    }
    
    // MARK: - Inventory
    var lootBoxCounts: [Rarity: Int] {
        UserData.shared.inventory.lootBoxes
    }
    
    var totalLootBoxes: Int {
        UserData.shared.inventory.totalLootBoxes
    }
    
    func count(for rarity: Rarity) -> Int {
        UserData.shared.inventory.lootBoxes[rarity, default: 0]
    }
}
