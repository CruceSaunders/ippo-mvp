import SwiftUI

struct MoodIndicator: View {
    let mood: Int
    @State private var showTip = false

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

    private var tipText: String {
        switch mood {
        case 3: return "Your pet is happy! Keep running and caring for them."
        case 2: return "Feed, water, and pet them daily to boost their mood."
        default: return "Run together and care for your pet to cheer them up!"
        }
    }

    var body: some View {
        Button { showTip = true } label: {
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
        .alert(label, isPresented: $showTip) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(tipText)
        }
    }
}
