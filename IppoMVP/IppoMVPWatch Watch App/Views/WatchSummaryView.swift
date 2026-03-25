import SwiftUI

struct WatchSummaryView: View {
    @EnvironmentObject var runManager: WatchRunManager
    @EnvironmentObject var connectivity: WatchConnectivityServiceWatch

    var body: some View {
        ZStack {
            WatchColors.backgroundLight.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 8) {
                    if let summary = runManager.runSummary, !summary.petEncounters.isEmpty {
                        catchCelebration(hasNewPet: summary.petEncounters.contains(where: \.isNew))
                    }

                    // Header
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(WatchColors.success)
                        Text("RUN COMPLETE")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(WatchColors.textPrimaryLight)
                    }

                    // Duration
                    Text(runManager.formattedDuration)
                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                        .foregroundColor(WatchColors.textPrimaryLight)

                    // Key Metrics
                    if let summary = runManager.runSummary {
                        runMetrics(summary)
                    }

                    // Pet outcomes section
                    if let summary = runManager.runSummary {
                        petOutcomeSection(summary)
                    }

                    // Done button
                    Button {
                        runManager.resetToIdle()
                    } label: {
                        Text("Done")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(WatchColors.textPrimaryLight)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(WatchColors.accent)
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }
        }
    }

    // MARK: - Catch Celebration

    private func catchCelebration(hasNewPet: Bool) -> some View {
        VStack(spacing: 4) {
            Image(systemName: hasNewPet ? "sparkles" : "arrow.up.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(hasNewPet ? WatchColors.accent : WatchColors.xp)

            Text(hasNewPet ? "You caught a new friend!" : "You spotted a familiar face!")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(hasNewPet ? WatchColors.accent : WatchColors.xp)
                .multilineTextAlignment(.center)

            Text(hasNewPet ? "Check your phone to meet them!" : "Bonus XP earned!")
                .font(.system(size: 10, design: .rounded))
                .foregroundColor(WatchColors.textSecondary)
        }
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity)
        .background((hasNewPet ? WatchColors.accentSoft : WatchColors.xp).opacity(0.3))
        .cornerRadius(10)
    }

    // MARK: - Run Metrics Grid

    private func runMetrics(_ summary: WatchRunSummary) -> some View {
        VStack(spacing: 6) {
            HStack {
                metricItem(
                    icon: "figure.run",
                    iconColor: WatchColors.accent,
                    value: formatDistance(summary.distanceMeters),
                    label: "Distance"
                )
                Spacer()
                metricItem(
                    icon: "gauge.medium",
                    iconColor: WatchColors.success,
                    value: formatPace(duration: summary.durationSeconds, distance: summary.distanceMeters),
                    label: "Pace"
                )
            }

            HStack {
                metricItem(
                    icon: "heart.fill",
                    iconColor: .red,
                    value: summary.averageHR > 0 ? "\(summary.averageHR)" : "--",
                    label: "Avg HR"
                )
                Spacer()
                metricItem(
                    icon: "flame.fill",
                    iconColor: WatchColors.accent,
                    value: summary.totalCalories > 0 ? String(format: "%.0f", summary.totalCalories) : "--",
                    label: "Calories"
                )
            }

            Divider()
                .background(WatchColors.textSecondary.opacity(0.3))

            HStack {
                metricItem(
                    icon: "bolt.fill",
                    iconColor: WatchColors.warning,
                    value: "\(summary.sprintsCompleted)/\(summary.sprintsTotal)",
                    label: "Sprints"
                )
                Spacer()
                metricItem(
                    icon: "circle.fill",
                    iconColor: WatchColors.coins,
                    value: "+\(summary.coinsEarned)",
                    label: "Coins"
                )
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Pet Outcome Section

    private func petOutcomeSection(_ summary: WatchRunSummary) -> some View {
        VStack(spacing: 4) {
            Divider()
                .background(WatchColors.textSecondary.opacity(0.3))

            HStack(spacing: 6) {
                if let petImage = connectivity.equippedPetImageName {
                    Image(petImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }

                VStack(alignment: .leading, spacing: 2) {
                    if let petName = connectivity.equippedPetName {
                        Text(petName)
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(WatchColors.textPrimaryLight)
                    }

                    HStack(spacing: 6) {
                        if summary.xpEarned > 0 {
                            Text("+\(summary.xpEarned) XP")
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundColor(WatchColors.xp)
                        }
                        if summary.coinsEarned > 0 {
                            Text("+\(summary.coinsEarned)")
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundColor(WatchColors.coins)
                        }
                    }
                }

                Spacer()

                // Mood indicator
                HStack(spacing: 2) {
                    Image(systemName: WatchColors.moodIcon(connectivity.equippedPetMood))
                        .font(.system(size: 9))
                        .foregroundColor(WatchColors.forMood(connectivity.equippedPetMood))
                    Text(WatchColors.moodLabel(connectivity.equippedPetMood))
                        .font(.system(size: 9, design: .rounded))
                        .foregroundColor(WatchColors.textSecondary)
                }
            }
        }
    }

    // MARK: - Helpers

    private func metricItem(icon: String, iconColor: Color, value: String, label: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(iconColor)
            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(WatchColors.textPrimaryLight)
                Text(label)
                    .font(.system(size: 9, design: .rounded))
                    .foregroundColor(WatchColors.textSecondary)
            }
        }
    }

    private func formatDistance(_ meters: Double) -> String {
        let miles = meters / 1609.34
        if miles < 0.01 { return "0.00 mi" }
        return String(format: "%.2f mi", miles)
    }

    private func formatPace(duration: Int, distance: Double) -> String {
        guard distance > 80 else { return "--:--" }
        let miles = distance / 1609.34
        let minutesPerMile = (Double(duration) / 60.0) / miles
        guard minutesPerMile.isFinite && minutesPerMile > 0 && minutesPerMile < 60 else { return "--:--" }
        let m = Int(minutesPerMile)
        let s = Int((minutesPerMile - Double(m)) * 60)
        return String(format: "%d:%02d/mi", m, s)
    }
}

#Preview {
    WatchSummaryView()
        .environmentObject(WatchRunManager.shared)
        .environmentObject(WatchConnectivityServiceWatch.shared)
}
