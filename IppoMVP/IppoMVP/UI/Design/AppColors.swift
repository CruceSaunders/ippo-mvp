import SwiftUI

struct AppColors {
    // MARK: - Backgrounds (Parchment)
    static let background = Color(hex: "#F0DFC8")
    static let surface = Color(hex: "#F7EBDA")
    static let surfaceElevated = Color(hex: "#FFF3E4")
    static let surfaceDark = Color(hex: "#D9C4A8")

    // MARK: - Text
    static let textPrimary = Color(hex: "#2D2016")
    static let textSecondary = Color(hex: "#6B5D4F")
    static let textTertiary = Color(hex: "#A39484")

    // MARK: - Accent
    static let accent = Color(hex: "#D4943C")
    static let accentSoft = Color(hex: "#F0C87A")

    // MARK: - Storybook Elements
    static let borderBrown = Color(hex: "#8B7355")
    static let borderLight = Color(hex: "#C4A882")
    static let ribbonBrown = Color(hex: "#6B5140")
    static let ribbonEdge = Color(hex: "#543E30")
    static let vineDark = Color(hex: "#4A6B3A")
    static let vineLight = Color(hex: "#7FA868")
    static let parchmentDark = Color(hex: "#D4B896")
    static let parchmentEdge = Color(hex: "#B89C78")

    // MARK: - Gold (buttons, progress fills)
    static let goldLight = Color(hex: "#F0D080")
    static let goldMid = Color(hex: "#D4A843")
    static let goldDark = Color(hex: "#B08930")
    static let goldShine = Color(hex: "#FFF0C0")

    // MARK: - Semantic
    static let success = Color(hex: "#6BBF6B")
    static let warning = Color(hex: "#E8B44A")
    static let danger = Color(hex: "#D96B6B")

    // MARK: - Brand (aliases)
    static let brandPrimary = accent
    static let brandSecondary = accentSoft
    static let gold = goldMid

    // MARK: - Currency
    static let coins = Color(hex: "#D4A843")

    // MARK: - XP
    static let xp = Color(hex: "#7BB8E0")

    // MARK: - Pet Mood
    static let petHappy = Color(hex: "#8BC68B")
    static let petNeutral = Color(hex: "#E8C86B")
    static let petSad = Color(hex: "#D98B8B")

    // MARK: - Tab Bar (Dark Brown Storybook)
    static let tabBar = Color(hex: "#3D2E1F")
    static let tabActive = Color(hex: "#D4A843")
    static let tabInactive = Color(hex: "#8B7B6B")

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
