import Foundation
import WatchKit

@MainActor
final class WatchHapticsManager {
    static let shared = WatchHapticsManager()
    
    private let device = WKInterfaceDevice.current()
    
    private init() {}
    
    // MARK: - Run Lifecycle
    func playRunStart() {
        device.play(.start)
    }
    
    func playRunEnd() {
        device.play(.stop)
    }
    
    // MARK: - Sprint Signals
    func playSprintStart() {
        // 3 strong vibrations
        Task {
            for _ in 0..<3 {
                device.play(.notification)
                try? await Task.sleep(nanoseconds: 150_000_000) // 0.15s
            }
        }
    }
    
    func playSprintEnd() {
        // 3 strong vibrations
        Task {
            for _ in 0..<3 {
                device.play(.notification)
                try? await Task.sleep(nanoseconds: 150_000_000)
            }
        }
    }
    
    func playTick() {
        device.play(.click)
    }
    
    func playSprintSuccess() {
        device.play(.success)
    }
    
    func playSprintFail() {
        device.play(.failure)
    }
    
    // MARK: - Pet Catch
    func playPetCatch() {
        Task {
            // Dramatic buildup
            for _ in 0..<5 {
                device.play(.notification)
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
            }
            
            // Big celebration
            try? await Task.sleep(nanoseconds: 200_000_000)
            device.play(.success)
        }
    }
    
    // MARK: - General
    func playSuccess() {
        device.play(.success)
    }
    
    func playFailure() {
        device.play(.failure)
    }
    
    func playNotification() {
        device.play(.notification)
    }
}
