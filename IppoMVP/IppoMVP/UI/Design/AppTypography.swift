import SwiftUI

struct AppTypography {
    // MARK: - Storybook Title Styles (Serif for fantasy feel)
    static let largeTitle = Font.system(size: 34, weight: .bold, design: .serif)
    static let title1 = Font.system(size: 28, weight: .bold, design: .serif)
    static let title2 = Font.system(size: 22, weight: .bold, design: .serif)
    static let title3 = Font.system(size: 20, weight: .semibold, design: .serif)

    // MARK: - Body Styles (Rounded for friendly readability)
    static let headline = Font.system(size: 17, weight: .semibold, design: .rounded)
    static let body = Font.system(size: 17, weight: .regular, design: .rounded)
    static let callout = Font.system(size: 16, weight: .regular, design: .rounded)
    static let subheadline = Font.system(size: 15, weight: .regular, design: .rounded)
    static let footnote = Font.system(size: 13, weight: .regular, design: .rounded)
    static let caption1 = Font.system(size: 12, weight: .regular, design: .rounded)
    static let caption2 = Font.system(size: 11, weight: .regular, design: .rounded)

    // MARK: - Special Styles
    static let statNumber = Font.system(size: 32, weight: .bold, design: .rounded)
    static let currency = Font.system(size: 16, weight: .semibold, design: .monospaced)
    static let timer = Font.system(size: 48, weight: .bold, design: .monospaced)

    // MARK: - Storybook-Specific
    static let ribbonTitle = Font.system(size: 16, weight: .bold, design: .serif)
    static let cardTitle = Font.system(size: 15, weight: .semibold, design: .serif)
    static let screenTitle = Font.system(size: 26, weight: .bold, design: .serif)
    static let petName = Font.system(size: 22, weight: .bold, design: .serif)
    static let sectionLabel = Font.system(size: 13, weight: .semibold, design: .serif)
}

// MARK: - Text Modifiers
extension View {
    func primaryText() -> some View {
        self.foregroundColor(AppColors.textPrimary)
    }

    func secondaryText() -> some View {
        self.foregroundColor(AppColors.textSecondary)
    }

    func tertiaryText() -> some View {
        self.foregroundColor(AppColors.textTertiary)
    }
}
