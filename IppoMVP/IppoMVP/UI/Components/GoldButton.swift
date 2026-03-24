import SwiftUI

struct GoldButton: View {
    let title: String
    var icon: String? = nil
    var coinAmount: Int? = nil
    var isDisabled: Bool = false
    var isFullWidth: Bool = false
    var size: ButtonSize = .standard
    let action: () -> Void

    enum ButtonSize {
        case compact, standard, large
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: iconSize, weight: .semibold))
                }

                Text(title)
                    .font(.system(size: fontSize, weight: .bold, design: .rounded))

                if let amount = coinAmount {
                    HStack(spacing: 3) {
                        Text("\(amount)")
                            .font(.system(size: fontSize, weight: .bold, design: .rounded))
                        Image(systemName: "circle.fill")
                            .font(.system(size: 6))
                            .foregroundColor(AppColors.coins)
                    }
                }
            }
            .foregroundColor(isDisabled ? AppColors.textTertiary : AppColors.textPrimary)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .padding(.horizontal, horizontalPad)
            .padding(.vertical, verticalPad)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        isDisabled
                            ? LinearGradient(colors: [AppColors.surfaceDark, AppColors.surfaceDark], startPoint: .top, endPoint: .bottom)
                            : LinearGradient(colors: [AppColors.goldLight, AppColors.goldMid], startPoint: .top, endPoint: .bottom)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        isDisabled ? AppColors.borderLight : AppColors.goldDark,
                        lineWidth: 1
                    )
            )
            .shadow(color: isDisabled ? .clear : AppColors.goldDark.opacity(0.3), radius: 2, y: 1)
        }
        .disabled(isDisabled)
    }

    private var fontSize: CGFloat {
        switch size {
        case .compact: return 13
        case .standard: return 15
        case .large: return 17
        }
    }

    private var iconSize: CGFloat {
        switch size {
        case .compact: return 12
        case .standard: return 14
        case .large: return 16
        }
    }

    private var horizontalPad: CGFloat {
        switch size {
        case .compact: return 12
        case .standard: return 18
        case .large: return 24
        }
    }

    private var verticalPad: CGFloat {
        switch size {
        case .compact: return 7
        case .standard: return 10
        case .large: return 14
        }
    }

    private var cornerRadius: CGFloat {
        switch size {
        case .compact: return 8
        case .standard: return 10
        case .large: return 12
        }
    }
}
