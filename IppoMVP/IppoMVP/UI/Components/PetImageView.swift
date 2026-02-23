import SwiftUI

struct PetImageView: View {
    let imageName: String
    var size: CGFloat = 100

    var body: some View {
        if UIImage(named: imageName) != nil {
            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
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
