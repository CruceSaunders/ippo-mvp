import SwiftUI

struct WatchRunningView: View {
    @EnvironmentObject var runManager: WatchRunManager
    @EnvironmentObject var connectivity: WatchConnectivityServiceWatch
    @State private var showingEndConfirm = false

    var body: some View {
        ZStack {
            WatchColors.backgroundDark.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 4) {
                    // Pet avatar + timer row
                    HStack {
                        Spacer()
                        Text(runManager.formattedDuration)
                            .font(.system(size: 26, weight: .bold, design: .monospaced))
                            .foregroundColor(WatchColors.textPrimaryDark)
                        Spacer()
                        petCornerAvatar
                    }

                    // Distance + Pace
                    HStack(spacing: 12) {
                        VStack(spacing: 0) {
                            Text(runManager.formattedDistance)
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundColor(WatchColors.textPrimaryDark)
                            Text("dist")
                                .font(.system(size: 9, design: .rounded))
                                .foregroundColor(WatchColors.textSecondary)
                        }

                        VStack(spacing: 0) {
                            Text(runManager.formattedPace)
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundColor(WatchColors.textPrimaryDark)
                            Text("/mi")
                                .font(.system(size: 9, design: .rounded))
                                .foregroundColor(WatchColors.textSecondary)
                        }
                    }

                    // HR + Calories
                    HStack(spacing: 14) {
                        HStack(spacing: 3) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.red)
                            Text("\(runManager.currentHR)")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                        }

                        HStack(spacing: 3) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 10))
                                .foregroundColor(WatchColors.accent)
                            Text(runManager.formattedCalories)
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                        }
                    }
                    .foregroundColor(WatchColors.textPrimaryDark)

                    // Sprints counter
                    HStack(spacing: 3) {
                        Text("Sprints:")
                            .font(.system(size: 10, design: .rounded))
                            .foregroundColor(WatchColors.textSecondary)
                        Text("\(runManager.sprintsCompleted)")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(WatchColors.success)
                        Text("/\(runManager.totalSprints)")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundColor(WatchColors.textSecondary)
                    }

                    // Recovery indicator
                    if runManager.isInRecovery {
                        HStack(spacing: 3) {
                            Image(systemName: "clock")
                                .font(.system(size: 9))
                            Text("Recovery \(Int(runManager.recoveryRemaining))s")
                                .font(.system(size: 10, design: .rounded))
                        }
                        .foregroundColor(WatchColors.xp)
                    }

                    // Controls
                    HStack(spacing: 16) {
                        Button {
                            runManager.pauseRun()
                        } label: {
                            Image(systemName: runManager.isPaused ? "play.fill" : "pause.fill")
                                .font(.system(size: 14))
                                .foregroundColor(WatchColors.textPrimaryDark)
                                .frame(width: 40, height: 40)
                                .background(WatchColors.darkSurface)
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)

                        Button {
                            showingEndConfirm = true
                        } label: {
                            Image(systemName: "stop.fill")
                                .font(.system(size: 14))
                                .foregroundColor(WatchColors.textPrimaryDark)
                                .frame(width: 40, height: 40)
                                .background(WatchColors.danger.opacity(0.8))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
            }
            .alert("End Run?", isPresented: $showingEndConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("End", role: .destructive) {
                    runManager.endRun()
                }
            } message: {
                Text("Are you sure you want to end your run?")
            }

            // Sprint result overlay
            if runManager.showSprintResult {
                sprintResultOverlay
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.3), value: runManager.showSprintResult)
            }
        }
    }

    // MARK: - Pet Corner Avatar

    private var petCornerAvatar: some View {
        Group {
            if let petImage = connectivity.equippedPetImageName {
                ZStack(alignment: .bottomTrailing) {
                    Image(petImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .clipShape(RoundedRectangle(cornerRadius: 6))

                    Circle()
                        .fill(WatchColors.forMood(connectivity.equippedPetMood))
                        .frame(width: 6, height: 6)
                        .offset(x: 1, y: 1)
                }
            } else {
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 12))
                    .foregroundColor(WatchColors.accentSoft)
            }
        }
    }

    // MARK: - Sprint Result Overlay

    private var sprintResultOverlay: some View {
        ZStack {
            WatchColors.backgroundDark.opacity(0.90)
                .ignoresSafeArea()

            VStack(spacing: 8) {
                if runManager.didCatchPet {
                    Image(systemName: runManager.lastEncounterWasDuplicate ? "arrow.up.circle.fill" : "pawprint.fill")
                        .font(.system(size: 36))
                        .foregroundColor(runManager.lastEncounterWasDuplicate ? WatchColors.xp : WatchColors.accent)

                    Text(runManager.lastEncounterWasDuplicate ? "Familiar friend spotted!" : "New friend caught!")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(runManager.lastEncounterWasDuplicate ? WatchColors.xp : WatchColors.accent)

                    Text(runManager.lastEncounterWasDuplicate ? "+30 Bonus XP!" : "Check your phone!")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundColor(WatchColors.textSecondary)
                } else if runManager.lastSprintSuccess {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 36))
                        .foregroundColor(WatchColors.success)

                    Text("Sprint Complete!")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(WatchColors.success)

                    HStack(spacing: 6) {
                        Text("+coins")
                            .foregroundColor(WatchColors.coins)
                        Text("+XP")
                            .foregroundColor(WatchColors.xp)
                    }
                    .font(.system(size: 12, design: .rounded))
                } else {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 36))
                        .foregroundColor(WatchColors.danger.opacity(0.8))

                    Text("Sprint Failed")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(WatchColors.danger)

                    Text("Keep pushing!")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundColor(WatchColors.textSecondary)
                }
            }
        }
        .allowsHitTesting(false)
    }
}

#Preview {
    WatchRunningView()
        .environmentObject(WatchRunManager.shared)
        .environmentObject(WatchConnectivityServiceWatch.shared)
}
