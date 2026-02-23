import SwiftUI

struct AppColors {
    // MARK: - Backgrounds
    static let background = Color(hex: "#FFF8F0")
    static let surface = Color(hex: "#FFF1E6")
    static let surfaceElevated = Color(hex: "#FFE8D6")

    // MARK: - Text
    static let textPrimary = Color(hex: "#2D2A26")
    static let textSecondary = Color(hex: "#6B6560")
    static let textTertiary = Color(hex: "#A39E98")

    // MARK: - Accent
    static let accent = Color(hex: "#E88D5A")
    static let accentSoft = Color(hex: "#F5C89A")

    // MARK: - Semantic
    static let success = Color(hex: "#6BBF6B")
    static let warning = Color(hex: "#E8B44A")
    static let danger = Color(hex: "#D96B6B")

    // MARK: - Brand (aliases for legacy references)
    static let brandPrimary = accent
    static let brandSecondary = accentSoft
    static let gold = Color(hex: "#D4A843")

    // MARK: - Currency
    static let coins = Color(hex: "#D4A843")

    // MARK: - XP
    static let xp = Color(hex: "#7BB8E0")

    // MARK: - Pet Mood
    static let petHappy = Color(hex: "#8BC68B")
    static let petNeutral = Color(hex: "#E8C86B")
    static let petSad = Color(hex: "#D98B8B")

    // MARK: - Tab Bar
    static let tabBar = Color(hex: "#FFFAF5")
    static let tabActive = Color(hex: "#E88D5A")
    static let tabInactive = Color(hex: "#C4BBB2")

    // MARK: - Mood Color Helper
    static func forMood(_ mood: Int) -> Color {
        switch mood {
        case 3: return petHappy
        case 2: return petNeutral
        default: return petSad
        }
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
