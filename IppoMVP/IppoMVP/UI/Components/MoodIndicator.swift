import SwiftUI

struct MoodIndicator: View {
    let mood: Int
    var careNeed: CareNeedType? = nil
    @State private var showTip = false

    private var hasCareNeed: Bool { careNeed != nil }

    private var iconName: String {
        if let need = careNeed {
            switch need {
            case .hungry: return "fork.knife"
            case .thirsty: return "drop.fill"
            case .lonely: return "heart"
            }
        }
        switch mood {
        case 3: return "leaf.fill"
        case 2: return "leaf"
        default: return "leaf.arrow.triangle.circlepath"
        }
    }

    private var color: Color {
        if hasCareNeed { return AppColors.warning }
        return AppColors.forMood(mood)
    }

    private var label: String {
        if let need = careNeed {
            switch need {
            case .hungry: return "Hungry"
            case .thirsty: return "Thirsty"
            case .lonely: return "Lonely"
            }
        }
        switch mood {
        case 3: return "Happy"
        case 2: return "Content"
        default: return "Sad"
        }
    }

    private var tipText: String {
        if let need = careNeed {
            switch need {
            case .hungry: return "Your pet is hungry! Drag food onto them to feed."
            case .thirsty: return "Your pet is thirsty! Drag water onto them."
            case .lonely: return "Your pet misses you! Give them some pets."
            }
        }
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
