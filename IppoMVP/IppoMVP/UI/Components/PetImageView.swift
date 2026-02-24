import SwiftUI

struct PetImageView: View {
    let imageName: String
    var size: CGFloat = 100
    var isDropTarget: Bool = false

    var body: some View {
        if UIImage(named: imageName) != nil {
            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(AppColors.accent.opacity(isDropTarget ? 0.6 : 0), lineWidth: 3)
                        .animation(.easeInOut(duration: 0.2), value: isDropTarget)
                )
                .shadow(
                    color: isDropTarget ? AppColors.accent.opacity(0.35) : .clear,
                    radius: isDropTarget ? 16 : 0
                )
                .animation(.easeInOut(duration: 0.2), value: isDropTarget)
        } else {
            ZStack {
                Circle()
                    .fill(AppColors.accentSoft.opacity(0.3))
                Image(systemName: "pawprint.fill")
                    .font(.system(size: size * 0.3))
                    .foregroundColor(AppColors.accent.opacity(0.5))
            }
        }
    }
}
