import SwiftUI

// MARK: - Color Theme
enum AppColorTheme: String, CaseIterable, Identifiable {
    case midnight = "Midnight"
    case ocean = "Ocean"
    case ember = "Ember"
    case forest = "Forest"
    case monochrome = "Monochrome"
    
    var id: String { rawValue }
    
    var brandPrimary: Color {
        switch self {
        case .midnight: return Color(hex: "#6366F1")
        case .ocean: return Color(hex: "#06B6D4")
        case .ember: return Color(hex: "#F97316")
        case .forest: return Color(hex: "#10B981")
        case .monochrome: return Color(hex: "#9CA3AF")
        }
    }
    
    var brandSecondary: Color {
        switch self {
        case .midnight: return Color(hex: "#8B5CF6")
        case .ocean: return Color(hex: "#0EA5E9")
        case .ember: return Color(hex: "#EF4444")
        case .forest: return Color(hex: "#22C55E")
        case .monochrome: return Color(hex: "#F9FAFB")
        }
    }
    
    var gradientStart: Color { brandPrimary }
    var gradientEnd: Color { brandSecondary }
    
    var previewColor: Color { brandPrimary }
}

// MARK: - Theme Manager
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var current: AppColorTheme {
        didSet {
            UserDefaults.standard.set(current.rawValue, forKey: "appColorTheme")
        }
    }
    
    private init() {
        let saved = UserDefaults.standard.string(forKey: "appColorTheme") ?? "Midnight"
        self.current = AppColorTheme(rawValue: saved) ?? .midnight
    }
}

struct AppColors {
    private static var theme: AppColorTheme { ThemeManager.shared.current }
    
    // MARK: - Backgrounds (same across all themes)
    static let background = Color(hex: "#0A0A0F")
    static let surface = Color(hex: "#12121A")
    static let surfaceElevated = Color(hex: "#1A1A25")
    
    // MARK: - Text (same across all themes)
    static let textPrimary = Color(hex: "#F9FAFB")
    static let textSecondary = Color(hex: "#9CA3AF")
    static let textTertiary = Color(hex: "#6B7280")
    
    // MARK: - Brand (theme-dependent)
    static var brandPrimary: Color { theme.brandPrimary }
    static var brandSecondary: Color { theme.brandSecondary }
    
    // MARK: - Gradients (theme-dependent)
    static var gradientStart: Color { theme.gradientStart }
    static var gradientEnd: Color { theme.gradientEnd }
    
    // MARK: - Sprint/Action
    static let sprintActive = Color(hex: "#F97316")
    static let sprintSuccess = Color(hex: "#22C55E")
    
    // MARK: - Semantic (same across all themes)
    static let success = Color(hex: "#22C55E")
    static let warning = Color(hex: "#F59E0B")
    static let danger = Color(hex: "#EF4444")
    
    // MARK: - Currencies
    static let gold = Color(hex: "#FFD700")
    static let gems = Color(hex: "#E879F9")
    
    // MARK: - RP Box Tier Colors
    static let tierCommon = Color(hex: "#9CA3AF")
    static let tierUncommon = Color(hex: "#22C55E")
    static let tierRare = Color(hex: "#3B82F6")
    static let tierEpic = Color(hex: "#A855F7")
    static let tierLegendary = Color(hex: "#F97316")
    
    // MARK: - Helper
    static func forTier(_ tier: RPBoxTier) -> Color {
        switch tier {
        case .common: return tierCommon
        case .uncommon: return tierUncommon
        case .rare: return tierRare
        case .epic: return tierEpic
        case .legendary: return tierLegendary
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
