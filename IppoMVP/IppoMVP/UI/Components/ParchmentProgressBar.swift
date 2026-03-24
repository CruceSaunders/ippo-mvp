import SwiftUI

struct ParchmentProgressBar: View {
    let progress: Double
    let currentXP: Int
    let targetXP: Int
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(AppColors.surfaceDark)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(AppColors.borderLight, lineWidth: 1)
                        )
                        .frame(height: 14)

                    RoundedRectangle(cornerRadius: 5)
                        .fill(
                            LinearGradient(
                                colors: [AppColors.goldLight, AppColors.goldMid],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: max(0, geo.size.width * min(max(progress, 0), 1.0) - 2),
                            height: 10
                        )
                        .padding(.leading, 2)
                        .shadow(color: AppColors.goldMid.opacity(0.4), radius: 2, y: 0)
                }
            }
            .frame(height: 14)

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
