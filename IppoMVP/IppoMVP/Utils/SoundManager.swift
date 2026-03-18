import Foundation
import AVFoundation
import AudioToolbox
import Combine

@MainActor
final class SoundManager: ObservableObject {
    static let shared = SoundManager()

    @Published var isSoundEnabled: Bool {
        didSet { UserDefaults.standard.set(isSoundEnabled, forKey: "ippo.soundEnabled") }
    }

    private var activePlayers: [AVAudioPlayer] = []

    private init() {
        self.isSoundEnabled = UserDefaults.standard.object(forKey: "ippo.soundEnabled") as? Bool ?? true
        configureAudioSession()
    }

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, options: .mixWithOthers)
            try session.setActive(true)
        } catch {
            print("SoundManager: Audio session setup failed: \(error)")
        }
    }

    private let maxConcurrentPlayers = 8

    func play(_ effect: SoundEffect) {
        guard isSoundEnabled else { return }

        Task.detached {
            let data = effect.generateAudio()
            guard let data else { return }

            do {
                let player = try AVAudioPlayer(data: data)
                player.volume = effect.volume
                player.prepareToPlay()

                await MainActor.run { [weak self] in
                    guard let self else { return }
                    self.activePlayers.removeAll { !$0.isPlaying }
                    if self.activePlayers.count >= self.maxConcurrentPlayers {
                        self.activePlayers.removeFirst()
                    }
                    player.play()
                    self.activePlayers.append(player)
                }
            } catch {
                print("SoundManager: Failed to play \(effect.displayName): \(error)")
            }
        }
    }
}

// MARK: - Sound Effect Definitions

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
        case .petCatch: return "Celebratory chime when a new pet is caught"
        case .evolution: return "Rising fanfare when pet evolves"
        case .feedPet: return "Soft pop when feeding"
        case .waterPet: return "Gentle bubble when watering"
        case .petPet: return "Warm tone when petting"
        case .coinEarned: return "Light clink when coins are awarded"
        case .xpGained: return "Brief ding when XP is gained"
        case .levelUp: return "Achievement chime when pet levels up"
        case .shopPurchase: return "Confirmation tone after buying"
        case .sprintStart: return "Alert tone when sprint begins"
        case .sprintSuccess: return "Positive chime when sprint passes"
        case .sprintFail: return "Gentle low tone when sprint fails"
        case .streakMilestone: return "Celebration chime for streak milestones"
        case .appOpen: return "Warm welcome tone on app open"
        case .error: return "Gentle warning tone"
        }
    }

    var volume: Float {
        switch self {
        case .petCatch, .evolution, .streakMilestone, .levelUp: return 0.7
        case .sprintStart: return 0.6
        case .appOpen: return 0.3
        case .error, .sprintFail: return 0.4
        default: return 0.5
        }
    }

    /// Each effect is a sequence of (frequency Hz, duration seconds).
    /// Synthesized as sine wave tones -- warm and simple.
    var toneSequence: [(frequency: Double, duration: Double)] {
        switch self {
        case .petCatch:
            return [(523.25, 0.1), (659.25, 0.1), (783.99, 0.1), (1046.50, 0.25)]
        case .evolution:
            return [(392.0, 0.15), (523.25, 0.15), (659.25, 0.15), (783.99, 0.15), (1046.50, 0.35)]
        case .feedPet:
            return [(440.0, 0.08), (554.37, 0.12)]
        case .waterPet:
            return [(493.88, 0.06), (587.33, 0.06), (659.25, 0.12)]
        case .petPet:
            return [(392.0, 0.1), (440.0, 0.15)]
        case .coinEarned:
            return [(1318.51, 0.06), (1567.98, 0.1)]
        case .xpGained:
            return [(880.0, 0.08), (1108.73, 0.1)]
        case .levelUp:
            return [(523.25, 0.1), (659.25, 0.1), (783.99, 0.2)]
        case .shopPurchase:
            return [(659.25, 0.08), (783.99, 0.08), (1046.50, 0.15)]
        case .sprintStart:
            return [(440.0, 0.12), (0, 0.06), (440.0, 0.12), (0, 0.06), (554.37, 0.18)]
        case .sprintSuccess:
            return [(523.25, 0.1), (783.99, 0.15), (1046.50, 0.2)]
        case .sprintFail:
            return [(392.0, 0.15), (329.63, 0.2)]
        case .streakMilestone:
            return [(523.25, 0.08), (659.25, 0.08), (783.99, 0.08), (1046.50, 0.08), (1318.51, 0.2)]
        case .appOpen:
            return [(523.25, 0.12), (659.25, 0.18)]
        case .error:
            return [(329.63, 0.12), (293.66, 0.18)]
        }
    }

    func generateAudio() -> Data? {
        let sampleRate: Double = 44100
        var allSamples: [Float] = []

        for tone in toneSequence {
            let numSamples = Int(tone.duration * sampleRate)
            for i in 0..<numSamples {
                let t = Double(i) / sampleRate
                let fadeDuration = min(0.01, tone.duration * 0.15)
                let fadeIn = min(1.0, t / fadeDuration)
                let fadeOut = min(1.0, (tone.duration - t) / fadeDuration)
                let envelope = Float(fadeIn * fadeOut)

                if tone.frequency > 0 {
                    let sample = sin(2.0 * .pi * tone.frequency * t)
                    let harmonicBlend = sin(2.0 * .pi * tone.frequency * 2.0 * t) * 0.15
                    allSamples.append(Float(sample + harmonicBlend) * envelope * 0.4)
                } else {
                    allSamples.append(0)
                }
            }
        }

        return createWAV(samples: allSamples, sampleRate: Int(sampleRate))
    }

    private func createWAV(samples: [Float], sampleRate: Int) -> Data? {
        let numChannels: Int16 = 1
        let bitsPerSample: Int16 = 16
        let byteRate = Int32(sampleRate * Int(numChannels) * Int(bitsPerSample / 8))
        let blockAlign = Int16(numChannels * bitsPerSample / 8)
        let dataSize = Int32(samples.count * Int(blockAlign))
        let fileSize = 36 + dataSize

        var data = Data()

        func appendString(_ s: String) { data.append(contentsOf: s.utf8) }
        func appendInt32(_ v: Int32) { withUnsafeBytes(of: v.littleEndian) { data.append(contentsOf: $0) } }
        func appendInt16(_ v: Int16) { withUnsafeBytes(of: v.littleEndian) { data.append(contentsOf: $0) } }

        appendString("RIFF")
        appendInt32(fileSize)
        appendString("WAVE")

        appendString("fmt ")
        appendInt32(16)
        appendInt16(1)
        appendInt16(numChannels)
        appendInt32(Int32(sampleRate))
        appendInt32(byteRate)
        appendInt16(blockAlign)
        appendInt16(bitsPerSample)

        appendString("data")
        appendInt32(dataSize)

        for sample in samples {
            let clamped = max(-1.0, min(1.0, sample))
            let int16Val = Int16(clamped * Float(Int16.max))
            withUnsafeBytes(of: int16Val.littleEndian) { data.append(contentsOf: $0) }
        }

        return data
    }
}
