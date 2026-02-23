import SwiftUI

struct XPProgressBar: View {
    let progress: Double
    let currentXP: Int
    let targetXP: Int
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(AppColors.surfaceElevated)
                        .frame(height: 10)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [AppColors.xp, AppColors.xp.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * min(max(progress, 0), 1.0), height: 10)
                }
            }
            .frame(height: 10)

            HStack {
                Text("\(currentXP) / \(targetXP) XP")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
                Spacer()
                Text(label)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.textTertiary)
            }
        }
    }
}
