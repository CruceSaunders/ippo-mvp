import Foundation
import Combine

@MainActor
final class UserData: ObservableObject {
    static let shared = UserData()
    
    // MARK: - Published Properties
    @Published var profile: PlayerProfile
    @Published var pendingRPBoxes: [RPBox]
    @Published var runHistory: [CompletedRun]
    @Published var isLoggedIn: Bool = false
    @Published var friends: [String]          // Friend user IDs
    @Published var friendRequests: [String]   // Pending incoming friend request user IDs
    
    // MARK: - Derived Properties
    var totalRPBoxes: Int {
        pendingRPBoxes.filter { !$0.isOpened }.count
    }
    
    // MARK: - Init
    private init() {
        // Load from persistence or use defaults
        if let savedData = DataPersistence.shared.loadUserData() {
            self.profile = savedData.profile
            self.pendingRPBoxes = savedData.pendingRPBoxes
            self.runHistory = savedData.runHistory
            self.friends = savedData.friends
            self.friendRequests = savedData.friendRequests
            self.isLoggedIn = true
        } else {
            // New user defaults
            self.profile = PlayerProfile()
            self.pendingRPBoxes = []
            self.runHistory = []
            self.friends = []
            self.friendRequests = []
        }
    }
    
    // MARK: - RP Box Management
    func addRPBox() {
        let box = RPBox()
        pendingRPBoxes.append(box)
        save()
    }
    
    func addRPBoxes(count: Int) {
        for _ in 0..<count {
            pendingRPBoxes.append(RPBox())
        }
        save()
    }
    
    func openRPBox() -> RPBoxContents? {
        guard let index = pendingRPBoxes.firstIndex(where: { !$0.isOpened }) else { return nil }
        
        let contents = RPBoxContents.generate()
        pendingRPBoxes[index].isOpened = true
        
        // Apply RP to profile
        addRP(contents.rpAmount)
        
        save()
        return contents
    }
    
    // MARK: - Progression
    func addRP(_ amount: Int) {
        profile.rp += amount
        profile.weeklyRP += amount
        save()
    }
    
    func addXP(_ amount: Int) {
        profile.xp += amount
        let newLevel = PlayerLevelConfig.level(forXP: profile.xp)
        if newLevel > profile.level {
            profile.level = newLevel
        }
        save()
    }
    
    // MARK: - RP Decay
    /// Call on app launch to apply RP decay if user didn't run yesterday
    func applyRPDecayIfNeeded() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        guard let lastRun = profile.lastRunDate else { return }
        let lastRunDay = calendar.startOfDay(for: lastRun)
        let daysMissed = calendar.dateComponents([.day], from: lastRunDay, to: today).day ?? 0
        
        guard daysMissed > 1 else { return }  // Ran yesterday or today, no decay
        
        let rank = profile.rank
        let decayRange = rank.rpDecayPerDay
        
        // Apply decay for each missed day (minus the run day itself)
        let daysToDecay = daysMissed - 1
        for _ in 0..<daysToDecay {
            let decay = Int.random(in: decayRange)
            profile.rp = max(0, profile.rp - decay)
        }
        
        save()
    }
    
    // MARK: - Weekly Reset
    func checkWeeklyReset() {
        profile.checkWeeklyReset()
        save()
    }
    
    // MARK: - Run Completion
    func completeRun(_ run: CompletedRun) {
        runHistory.insert(run, at: 0)
        profile.totalRuns += 1
        profile.totalSprints += run.sprintsTotal
        profile.totalSprintsValid += run.sprintsCompleted
        profile.totalDurationSeconds += run.durationSeconds
        profile.totalDistanceMeters += run.distanceMeters
        
        // XP: 1 per minute of running
        let xpFromRun = run.durationSeconds / 60
        addXP(xpFromRun)
        
        // Update streak
        updateStreak()
        
        save()
    }
    
    private func updateStreak() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        if let lastRun = profile.lastRunDate {
            let lastRunDay = calendar.startOfDay(for: lastRun)
            let daysDiff = calendar.dateComponents([.day], from: lastRunDay, to: today).day ?? 0
            
            if daysDiff == 1 {
                // Consecutive day
                profile.currentStreak += 1
                profile.longestStreak = max(profile.longestStreak, profile.currentStreak)
            } else if daysDiff > 1 {
                // Streak broken
                profile.currentStreak = 1
            }
            // daysDiff == 0 means same day, streak unchanged
        } else {
            // First run
            profile.currentStreak = 1
        }
        
        profile.lastRunDate = Date()
    }
    
    // MARK: - Friends
    func addFriend(_ friendId: String) {
        guard !friends.contains(friendId) else { return }
        friends.append(friendId)
        save()
    }
    
    func removeFriend(_ friendId: String) {
        friends.removeAll { $0 == friendId }
        save()
    }
    
    // MARK: - Persistence
    func save() {
        DataPersistence.shared.saveUserData(self)
    }
    
    func logout() {
        profile = PlayerProfile()
        pendingRPBoxes = []
        runHistory = []
        friends = []
        friendRequests = []
        isLoggedIn = false
        DataPersistence.shared.clearUserData()
    }
    
    // MARK: - Debug
    #if DEBUG
    func loadTestData() {
        profile.rp = 2450
        profile.xp = 850
        profile.level = 8
        profile.currentStreak = 5
        profile.longestStreak = 7
        profile.totalRuns = 23
        profile.totalSprints = 67
        profile.totalSprintsValid = 58
        profile.username = "testrunner"
        profile.displayName = "Test Runner"
        
        // Add some RP boxes
        for _ in 0..<5 {
            pendingRPBoxes.append(RPBox())
        }
        
        // Add some run history
        runHistory = [
            CompletedRun(
                durationSeconds: 1920,
                sprintsCompleted: 4,
                sprintsTotal: 4,
                rpBoxesEarned: 3,
                xpEarned: 32
            ),
            CompletedRun(
                date: Date().addingTimeInterval(-86400),
                durationSeconds: 1500,
                sprintsCompleted: 3,
                sprintsTotal: 4,
                rpBoxesEarned: 2,
                xpEarned: 25
            )
        ]
        
        isLoggedIn = true
        save()
    }
    #endif
}

// MARK: - Saveable Data Structure
struct SaveableUserData: Codable {
    let profile: PlayerProfile
    let pendingRPBoxes: [RPBox]
    let runHistory: [CompletedRun]
    let friends: [String]
    let friendRequests: [String]
}
