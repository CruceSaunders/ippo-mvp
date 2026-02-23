import Foundation

struct RewardsConfig: Sendable {
    static let shared = RewardsConfig()

    let xpPerMinuteRunning: Int = 5
    let coinsPerMinuteRunning: Int = 1
    let coinsPerSprint: ClosedRange<Int> = 8...12
    let xpPerSprint: ClosedRange<Int> = 15...25
    let coinsForCatchingPet: Int = 25
    let baseCatchRate: Double = 0.08
    let pityTimerSprints: Int = 15
}
