import Foundation
import Combine

/// RPBoxSystem — handles opening RP Boxes with animation delay
@MainActor
final class RPBoxSystem: ObservableObject {
    static let shared = RPBoxSystem()
    
    @Published var isOpening: Bool = false
    @Published var lastContents: RPBoxContents?
    @Published var lastTier: RPBoxTier?
    
    private init() {}
    
    // MARK: - Open RP Box
    func openRPBox() async -> RPBoxContents? {
        let userData = UserData.shared
        
        // Check we have boxes
        guard userData.totalRPBoxes > 0 else { return nil }
        
        isOpening = true
        
        // Animation delay (1.5 seconds for suspense)
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        
        // Open and get contents
        guard let contents = userData.openRPBox() else {
            isOpening = false
            return nil
        }
        
        lastContents = contents
        lastTier = contents.tier
        isOpening = false
        
        return contents
    }
    
    // MARK: - Inventory
    var totalRPBoxes: Int {
        UserData.shared.totalRPBoxes
    }
}
