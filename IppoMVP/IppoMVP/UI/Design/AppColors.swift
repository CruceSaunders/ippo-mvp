import SwiftUI

struct AppColors {
    // MARK: - Backgrounds (Midnight Runner Theme)
    static let background = Color(hex: "#0A0A0F")      // Deeper black
    static let surface = Color(hex: "#12121A")          // Subtle elevation
    static let surfaceElevated = Color(hex: "#1A1A25")  // Cards
    
    // MARK: - Text
    static let textPrimary = Color(hex: "#F9FAFB")      // Almost white
    static let textSecondary = Color(hex: "#9CA3AF")    // Gray 400
    static let textTertiary = Color(hex: "#6B7280")     // Gray 500
    
    // MARK: - Brand (Indigo-Purple gradient)
    static let brandPrimary = Color(hex: "#6366F1")     // Indigo (softer than cyan)
    static let brandSecondary = Color(hex: "#8B5CF6")   // Purple accent
    
    // MARK: - Gradients
    static let gradientStart = Color(hex: "#6366F1")    // Indigo
    static let gradientEnd = Color(hex: "#A855F7")      // Purple
    
    // MARK: - Sprint/Action
    static let sprintActive = Color(hex: "#F97316")     // Energetic orange
    static let sprintSuccess = Color(hex: "#22C55E")    // Victory green
    
    // MARK: - Semantic
    static let success = Color(hex: "#22C55E")
    static let warning = Color(hex: "#F59E0B")
    static let danger = Color(hex: "#EF4444")
    
    // MARK: - Currencies
    static let gold = Color(hex: "#FFD700")
    static let gems = Color(hex: "#E879F9")
    
    // MARK: - Loot Box Rarity
    static let rarityCommon = Color(hex: "#9CA3AF")
    static let rarityUncommon = Color(hex: "#22C55E")
    static let rarityRare = Color(hex: "#3B82F6")
    static let rarityEpic = Color(hex: "#A855F7")
    static let rarityLegendary = Color(hex: "#F97316")
    
    // MARK: - Pet Colors
    static let ember = Color(hex: "#EF4444")
    static let splash = Color(hex: "#3B82F6")
    static let sprout = Color(hex: "#22C55E")
    static let zephyr = Color(hex: "#A5F3FC")
    static let pebble = Color(hex: "#A8A29E")
    static let spark = Color(hex: "#FBBF24")
    static let shadow = Color(hex: "#6366F1")
    static let frost = Color(hex: "#67E8F9")
    static let blaze = Color(hex: "#F97316")
    static let luna = Color(hex: "#E879F9")
    
    // MARK: - Helper
    static func forRarity(_ rarity: Rarity) -> Color {
        switch rarity {
        case .common: return rarityCommon
        case .uncommon: return rarityUncommon
        case .rare: return rarityRare
        case .epic: return rarityEpic
        case .legendary: return rarityLegendary
        }
    }
    
    static func forPet(_ petId: String) -> Color {
        switch petId {
        case "pet_01": return ember
        case "pet_02": return splash
        case "pet_03": return sprout
        case "pet_04": return zephyr
        case "pet_05": return pebble
        case "pet_06": return spark
        case "pet_07": return shadow
        case "pet_08": return frost
        case "pet_09": return blaze
        case "pet_10": return luna
        default: return brandPrimary
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
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
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
