import SwiftUI

struct WatchSummaryView: View {
    @EnvironmentObject var runManager: WatchRunManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Header
                VStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.green)
                    Text("COMPLETE")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                
                // Duration
                Text(runManager.formattedDuration)
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                
                // Stats
                VStack(spacing: 8) {
                    summaryRow("Sprints", value: "\(runManager.sprintsCompleted)/\(runManager.totalSprints) \u{2713}")
                    summaryRow("RP Boxes", value: "\(runManager.runSummary?.rpBoxesEarned ?? 0) earned")
                    summaryRow("XP Earned", value: "+\(runManager.runSummary?.xpEarned ?? 0)")
                }
                .padding(.vertical, 8)
                
                // RP Box notification
                if let summary = runManager.runSummary, summary.rpBoxesEarned > 0 {
                    VStack(spacing: 4) {
                        Text("RP BOXES EARNED")
                            .font(.caption)
                            .foregroundColor(.cyan)
                        Text("\(summary.rpBoxesEarned)")
                            .font(.title)
                            .foregroundColor(.white)
                        Text("Open on your phone!")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    .padding(8)
                    .background(Color.cyan.opacity(0.2))
                    .cornerRadius(8)
                }
                
                // Done button
                Button {
                    runManager.resetToIdle()
                } label: {
                    Text("Done")
                        .font(.headline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.cyan)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .padding(.top, 8)
            }
            .padding()
        }
    }
    
    private func summaryRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .font(.caption)
                .foregroundColor(.white)
        }
    }
}

#Preview {
    WatchSummaryView()
        .environmentObject(WatchRunManager.shared)
}
