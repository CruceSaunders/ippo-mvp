import SwiftUI

struct StoryBookCard<Content: View>: View {
    var isHighlighted: Bool = false
    var padding: CGFloat = 14
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .background(AppColors.surface)
            .cornerRadius(AppSpacing.radiusMd)
            .overlay(
                RoundedRectangle(cornerRadius: AppSpacing.radiusMd)
                    .stroke(
                        isHighlighted ? AppColors.goldMid : AppColors.borderLight,
                        lineWidth: isHighlighted ? 2 : 1
                    )
            )
            .shadow(color: AppColors.parchmentDark.opacity(0.15), radius: 2, y: 1)
    }
}

struct StoryBookCardCompact<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(10)
            .background(AppColors.surface)
            .cornerRadius(AppSpacing.radiusSm)
            .overlay(
                RoundedRectangle(cornerRadius: AppSpacing.radiusSm)
                    .stroke(AppColors.borderLight, lineWidth: 1)
            )
    }
}
