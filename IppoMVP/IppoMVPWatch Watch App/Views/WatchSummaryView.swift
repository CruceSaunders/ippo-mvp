import SwiftUI

struct WatchSummaryView: View {
    @EnvironmentObject var runManager: WatchRunManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                // Header
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.green)
                    Text("RUN COMPLETE")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
                
                // Duration
                Text(runManager.formattedDuration)
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                
                // Key Metrics Grid
                if let summary = runManager.runSummary {
                    VStack(spacing: 6) {
                        // Distance + Pace
                        HStack {
                            metricItem(
                                icon: "figure.run",
                                iconColor: .cyan,
                                value: formatDistance(summary.distanceMeters),
                                label: "Distance"
                            )
                            Spacer()
                            metricItem(
                                icon: "gauge.medium",
                                iconColor: .green,
                                value: formatPace(duration: summary.durationSeconds, distance: summary.distanceMeters),
                                label: "Pace"
                            )
                        }
                        
                        // HR + Calories
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
                                iconColor: .orange,
                                value: summary.totalCalories > 0 ? String(format: "%.0f", summary.totalCalories) : "--",
                                label: "Calories"
                            )
                        }
                        
                        Divider()
                            .background(Color.gray.opacity(0.3))
                        
                        // Sprints + RP Boxes
                        HStack {
                            metricItem(
                                icon: "bolt.fill",
                                iconColor: .yellow,
                                value: "\(summary.sprintsCompleted)/\(summary.sprintsTotal)",
                                label: "Sprints"
                            )
                            Spacer()
                            metricItem(
                                icon: "gift.fill",
                                iconColor: .purple,
                                value: "\(summary.rpBoxesEarned)",
                                label: "RP Boxes"
                            )
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                // RP Box notification
                if let summary = runManager.runSummary, summary.rpBoxesEarned > 0 {
                    Text("Open RP Boxes on your phone!")
                        .font(.system(size: 10))
                        .foregroundColor(.cyan)
                        .padding(.vertical, 2)
                }
                
                // Done button
                Button {
                    runManager.resetToIdle()
                } label: {
                    Text("Done")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.cyan)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
    }
    
    private func metricItem(icon: String, iconColor: Color, value: String, label: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(iconColor)
            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                Text(label)
                    .font(.system(size: 9))
                    .foregroundColor(.gray)
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
        let minutesPerKm = (Double(duration) / 60.0) / miles
        guard minutesPerKm.isFinite && minutesPerKm > 0 && minutesPerKm < 60 else { return "--:--" }
        let m = Int(minutesPerKm)
        let s = Int((minutesPerKm - Double(m)) * 60)
        return String(format: "%d:%02d/mi", m, s)
    }
}

#Preview {
    WatchSummaryView()
        .environmentObject(WatchRunManager.shared)
}
