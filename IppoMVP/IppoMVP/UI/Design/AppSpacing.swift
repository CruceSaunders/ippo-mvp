import SwiftUI

struct AppSpacing {
    static let xxxs: CGFloat = 2
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 6
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    static let xxxl: CGFloat = 48

    static let screenPadding: CGFloat = 20
    static let cardPadding: CGFloat = 16

    static let radiusSm: CGFloat = 8
    static let radiusMd: CGFloat = 12
    static let radiusLg: CGFloat = 16
    static let radiusXl: CGFloat = 20
}

// MARK: - Storybook Card Modifier
struct CardStyle: ViewModifier {
    var hasBorder: Bool = true

    func body(content: Content) -> some View {
        content
            .padding(AppSpacing.cardPadding)
            .background(AppColors.surface)
            .cornerRadius(AppSpacing.radiusMd)
            .overlay(
                RoundedRectangle(cornerRadius: AppSpacing.radiusMd)
                    .stroke(hasBorder ? AppColors.borderLight : .clear, lineWidth: 1)
            )
            .shadow(color: AppColors.parchmentDark.opacity(0.2), radius: 2, y: 1)
    }
}

struct ScreenPadding: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, AppSpacing.screenPadding)
    }
}

extension View {
    func cardStyle(hasBorder: Bool = true) -> some View {
        modifier(CardStyle(hasBorder: hasBorder))
    }

    func screenPadding() -> some View {
        modifier(ScreenPadding())
    }
}
