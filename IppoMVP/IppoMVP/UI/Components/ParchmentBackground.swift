import SwiftUI

struct ParchmentBackground: View {
    var showVineBorder: Bool = true

    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()

            RadialGradient(
                colors: [
                    AppColors.surfaceElevated.opacity(0.4),
                    Color.clear
                ],
                center: .center,
                startRadius: 50,
                endRadius: 500
            )
            .ignoresSafeArea()

            edgeVignette
                .ignoresSafeArea()

            if showVineBorder {
                VineBorderOverlay()
                    .ignoresSafeArea()
            }
        }
    }

    private var edgeVignette: some View {
        Rectangle()
            .fill(
                RadialGradient(
                    colors: [
                        Color.clear,
                        AppColors.parchmentEdge.opacity(0.15)
                    ],
                    center: .center,
                    startRadius: 200,
                    endRadius: 600
                )
            )
    }
}
