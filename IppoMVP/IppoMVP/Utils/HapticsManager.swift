import Foundation
#if os(iOS)
import UIKit
#endif

@MainActor
final class HapticsManager {
    static let shared = HapticsManager()
    
    private init() {}
    
    #if os(iOS)
    // MARK: - iOS Haptics
    func playSuccess() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    func playError() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
    
    func playWarning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
    
    func playLight() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    func playMedium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    func playHeavy() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }
    
    func playSelection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
    
    // MARK: - Custom Patterns
    func playPetCatchCelebration() {
        Task {
            for _ in 0..<3 {
                playHeavy()
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
            try? await Task.sleep(nanoseconds: 200_000_000)
            playSuccess()
        }
    }
    
    func playLootBoxOpen() {
        Task {
            playMedium()
            try? await Task.sleep(nanoseconds: 500_000_000)
            playHeavy()
        }
    }
    
    func playEvolution() {
        Task {
            playLight()
            try? await Task.sleep(nanoseconds: 200_000_000)
            playMedium()
            try? await Task.sleep(nanoseconds: 200_000_000)
            playHeavy()
            try? await Task.sleep(nanoseconds: 100_000_000)
            playSuccess()
        }
    }
    
    func playAbilityUnlock() {
        Task {
            playMedium()
            try? await Task.sleep(nanoseconds: 100_000_000)
            playSuccess()
        }
    }
    
    func playTick() {
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.impactOccurred(intensity: 0.5)
    }
    
    func playSpinLanding() {
        Task {
            playHeavy()
            try? await Task.sleep(nanoseconds: 100_000_000)
            playHeavy()
            try? await Task.sleep(nanoseconds: 200_000_000)
            playSuccess()
        }
    }
    #endif
}
