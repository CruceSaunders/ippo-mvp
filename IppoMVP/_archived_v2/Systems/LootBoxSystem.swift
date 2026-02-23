import Foundation
import Combine

/// RPBoxSystem -- handles RP Box opening logic
/// Animation is now handled by RPBoxOpenView, so this is instant
@MainActor
final class RPBoxSystem: ObservableObject {
    static let shared = RPBoxSystem()
    
    @Published var isOpening: Bool = false
    @Published var lastContents: RPBoxContents?
    @Published var lastTier: RPBoxTier?
    
    private init() {}
    
    // MARK: - Open RP Box (instant -- animation handled by view)
    func openRPBox() -> RPBoxContents? {
        let userData = UserData.shared
        
        guard userData.totalRPBoxes > 0 else { return nil }
        
        guard let contents = userData.openRPBox() else { return nil }
        
        lastContents = contents
        lastTier = contents.tier
        
        return contents
    }
    
    // MARK: - Inventory
    var totalRPBoxes: Int {
        UserData.shared.totalRPBoxes
    }
}
