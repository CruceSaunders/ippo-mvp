import SwiftUI

struct WatchStartView: View {
    @EnvironmentObject var runManager: WatchRunManager
    @EnvironmentObject var connectivity: WatchConnectivityServiceWatch

    private var isSimulator: Bool { WatchRunManager.isSimulator }

    private var canRun: Bool {
        if isSimulator { return true }
        return connectivity.isConnected && runManager.healthKitAuthorized
    }

    var body: some View {
        ZStack {
            WatchColors.backgroundLight.ignoresSafeArea()

            VStack(spacing: 6) {
                Text("IPPO")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(WatchColors.accent)

                if isSimulator {
                    simulatorBadge
                    petSection
                    startButton
                } else if !connectivity.isConnected {
                    phoneRequiredView
                } else if !runManager.healthKitAuthorized {
                    healthAccessView
                } else {
                    petSection
                    startButton
                }

                Text("Run. Catch. Grow.")
                    .font(.system(size: 10, design: .rounded))
                    .foregroundColor(WatchColors.textSecondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
        .onAppear {
            runManager.checkAndRequestHealthKit()
            connectivity.requestSync()
        }
    }

    // MARK: - Simulator Badge

    private var simulatorBadge: some View {
        Text("SIM")
            .font(.system(size: 8, weight: .bold, design: .rounded))
            .foregroundColor(WatchColors.textPrimaryDark)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(WatchColors.xp.opacity(0.7))
            .cornerRadius(4)
    }

    // MARK: - Pet Hero Section

    private var petSection: some View {
        Group {
            if let petImage = connectivity.equippedPetImageName,
               let petName = connectivity.equippedPetName {
                VStack(spacing: 4) {
                    Image(petImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 56, height: 56)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    Text(petName)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(WatchColors.textPrimaryLight)

                    HStack(spacing: 4) {
                        Image(systemName: WatchColors.moodIcon(connectivity.equippedPetMood))
                            .font(.system(size: 9))
                            .foregroundColor(WatchColors.forMood(connectivity.equippedPetMood))

                        Text("Lv.\(connectivity.equippedPetLevel)")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(WatchColors.textSecondary)
                    }
                }
            } else {
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 28))
                    .foregroundColor(WatchColors.accentSoft)
                    .padding(.vertical, 8)
            }
        }
    }

    // MARK: - Start Button

    private var startButton: some View {
        Button {
            runManager.startRun()
        } label: {
            VStack(spacing: 2) {
                Image(systemName: "play.fill")
                    .font(.system(size: 16))
                Text("START RUN")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
            }
            .foregroundColor(WatchColors.textPrimaryLight)
            .frame(width: 76, height: 76)
            .background(WatchColors.accent)
            .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Phone Required

    private var phoneRequiredView: some View {
        VStack(spacing: 6) {
            Image(systemName: "iphone.slash")
                .font(.title3)
                .foregroundColor(WatchColors.accent)

            Text("Open Ippo on iPhone")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(WatchColors.textPrimaryLight)
                .multilineTextAlignment(.center)

            Text("Your watch needs to connect to Ippo on your iPhone before you can start a run.")
                .font(.system(size: 9, design: .rounded))
                .foregroundColor(WatchColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 4)

            Button {
                connectivity.requestSync()
            } label: {
                Text("Retry")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(WatchColors.textPrimaryLight)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(WatchColors.accent)
                    .cornerRadius(14)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Health Access

    private var healthAccessView: some View {
        VStack(spacing: 6) {
            Image(systemName: "heart.slash.fill")
                .font(.title3)
                .foregroundColor(WatchColors.danger)

            Text("Health Access Required")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(WatchColors.textPrimaryLight)
                .multilineTextAlignment(.center)

            Text("Open the Health app on your iPhone and enable access for Ippo, then return here.")
                .font(.system(size: 9, design: .rounded))
                .foregroundColor(WatchColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 4)

            Button {
                runManager.requestHealthKitPermissions()
            } label: {
                Text("Check Again")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(WatchColors.textPrimaryLight)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(WatchColors.accent)
                    .cornerRadius(14)
            }
            .buttonStyle(.plain)

            if let error = runManager.healthKitError {
                Text(error)
                    .font(.system(size: 9, design: .rounded))
                    .foregroundColor(WatchColors.danger)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            }
        }
    }
}

#Preview {
    WatchStartView()
        .environmentObject(WatchRunManager.shared)
        .environmentObject(WatchConnectivityServiceWatch.shared)
}
