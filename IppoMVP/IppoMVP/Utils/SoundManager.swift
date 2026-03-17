import Foundation
import AVFoundation
import AudioToolbox

@MainActor
final class SoundManager: ObservableObject {
    static let shared = SoundManager()

    @Published var isSoundEnabled: Bool {
        didSet { UserDefaults.standard.set(isSoundEnabled, forKey: "ippo.soundEnabled") }
    }

    private var players: [SoundEffect: AVAudioPlayer] = [:]

    private init() {
        self.isSoundEnabled = UserDefaults.standard.object(forKey: "ippo.soundEnabled") as? Bool ?? true
        configureAudioSession()
    }

    private func configureAudioSession() {
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: .mixWithOthers)
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    func play(_ effect: SoundEffect) {
        guard isSoundEnabled else { return }
        AudioServicesPlaySystemSound(effect.systemSoundID)
    }

    func playWithHaptic(_ effect: SoundEffect) {
        guard isSoundEnabled else { return }
        AudioServicesPlaySystemSoundWithCompletion(effect.systemSoundID, nil)
    }
}

enum SoundEffect: String, CaseIterable, Identifiable {
    case petCatch
    case evolution
    case feedPet
    case waterPet
    case petPet
    case coinEarned
    case xpGained
    case levelUp
    case shopPurchase
    case sprintStart
    case sprintSuccess
    case sprintFail
    case streakMilestone
    case appOpen
    case error

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .petCatch: return "Pet Caught!"
        case .evolution: return "Evolution"
        case .feedPet: return "Feed Pet"
        case .waterPet: return "Water Pet"
        case .petPet: return "Pet (Rub)"
        case .coinEarned: return "Coin Earned"
        case .xpGained: return "XP Gained"
        case .levelUp: return "Level Up"
        case .shopPurchase: return "Shop Purchase"
        case .sprintStart: return "Sprint Start"
        case .sprintSuccess: return "Sprint Success"
        case .sprintFail: return "Sprint Failed"
        case .streakMilestone: return "Streak Milestone"
        case .appOpen: return "App Open"
        case .error: return "Error"
        }
    }

    var icon: String {
        switch self {
        case .petCatch: return "sparkles"
        case .evolution: return "arrow.up.circle.fill"
        case .feedPet: return "fork.knife"
        case .waterPet: return "drop.fill"
        case .petPet: return "hand.wave.fill"
        case .coinEarned: return "circle.fill"
        case .xpGained: return "star.fill"
        case .levelUp: return "chevron.up.2"
        case .shopPurchase: return "bag.fill"
        case .sprintStart: return "figure.run"
        case .sprintSuccess: return "checkmark.circle.fill"
        case .sprintFail: return "xmark.circle.fill"
        case .streakMilestone: return "flame.fill"
        case .appOpen: return "app.badge"
        case .error: return "exclamationmark.triangle.fill"
        }
    }

    var description: String {
        switch self {
        case .petCatch: return "Celebratory reveal when a new pet is caught during a run"
        case .evolution: return "Fanfare when pet evolves to a new stage"
        case .feedPet: return "Soft crunch when feeding the pet"
        case .waterPet: return "Gentle splash when watering the pet"
        case .petPet: return "Warm purr when petting/rubbing the pet"
        case .coinEarned: return "Light clink when coins are awarded"
        case .xpGained: return "Brief ding when XP is gained"
        case .levelUp: return "Achievement tone when pet levels up"
        case .shopPurchase: return "Confirmation chime after buying an item"
        case .sprintStart: return "Alert tone when sprint encounter begins on Watch"
        case .sprintSuccess: return "Positive chime when sprint is validated"
        case .sprintFail: return "Gentle negative tone when sprint fails validation"
        case .streakMilestone: return "Celebration when reaching a streak milestone"
        case .appOpen: return "Warm welcome tone when opening the app"
        case .error: return "Gentle warning for errors like insufficient coins"
        }
    }

    /// System sound IDs used as labeled placeholders.
    /// Replace with custom bundled audio files for production.
    var systemSoundID: SystemSoundID {
        switch self {
        case .petCatch: return 1025
        case .evolution: return 1104
        case .feedPet: return 1057
        case .waterPet: return 1104
        case .petPet: return 1105
        case .coinEarned: return 1057
        case .xpGained: return 1003
        case .levelUp: return 1025
        case .shopPurchase: return 1105
        case .sprintStart: return 1110
        case .sprintSuccess: return 1105
        case .sprintFail: return 1107
        case .streakMilestone: return 1025
        case .appOpen: return 1003
        case .error: return 1107
        }
    }
}
