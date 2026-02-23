import SwiftUI

struct MoodIndicator: View {
    let mood: Int

    private var iconName: String {
        switch mood {
        case 3: return "leaf.fill"
        case 2: return "leaf"
        default: return "leaf.arrow.triangle.circlepath"
        }
    }

    private var color: Color {
        AppColors.forMood(mood)
    }

    private var label: String {
        switch mood {
        case 3: return "Happy"
        case 2: return "Content"
        default: return "Sad"
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: iconName)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(color)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(color.opacity(0.15))
        .clipShape(Capsule())
    }
}
