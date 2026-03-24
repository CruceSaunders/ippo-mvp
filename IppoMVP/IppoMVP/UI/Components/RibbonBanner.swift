import SwiftUI

struct RibbonBanner: View {
    let title: String
    var style: RibbonStyle = .standard

    enum RibbonStyle {
        case standard
        case small
        case accent
    }

    var body: some View {
        HStack {
            Spacer()
            Text(title)
                .font(style == .small ? AppTypography.sectionLabel : AppTypography.ribbonTitle)
                .foregroundColor(ribbonTextColor)
                .tracking(0.5)
            Spacer()
        }
        .padding(.vertical, style == .small ? 6 : 9)
        .padding(.horizontal, 24)
        .background(
            RibbonShape()
                .fill(ribbonFillColor)
                .shadow(color: AppColors.ribbonEdge.opacity(0.3), radius: 2, y: 1)
        )
        .overlay(
            RibbonShape()
                .stroke(ribbonBorderColor, lineWidth: 1)
        )
    }

    private var ribbonFillColor: Color {
        switch style {
        case .standard: return AppColors.ribbonBrown
        case .small: return AppColors.borderBrown.opacity(0.8)
        case .accent: return AppColors.accent
        }
    }

    private var ribbonTextColor: Color {
        switch style {
        case .standard, .small: return AppColors.goldShine
        case .accent: return .white
        }
    }

    private var ribbonBorderColor: Color {
        switch style {
        case .standard: return AppColors.ribbonEdge
        case .small: return AppColors.borderBrown
        case .accent: return AppColors.accent.opacity(0.8)
        }
    }
}

struct RibbonShape: Shape {
    func path(in rect: CGRect) -> Path {
        let notchDepth: CGFloat = 8
        var path = Path()

        path.move(to: CGPoint(x: notchDepth, y: 0))
        path.addLine(to: CGPoint(x: rect.width - notchDepth, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: rect.height / 2))
        path.addLine(to: CGPoint(x: rect.width - notchDepth, y: rect.height))
        path.addLine(to: CGPoint(x: notchDepth, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height / 2))
        path.closeSubpath()

        return path
    }
}
