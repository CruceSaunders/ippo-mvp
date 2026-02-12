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
                    summaryRow("Sprints", value: "\(runManager.sprintsCompleted)/\(runManager.totalSprints) ✓")
                    summaryRow("RP Earned", value: "+\(runManager.runSummary?.rpEarned ?? 0)")
                    summaryRow("XP Earned", value: "+\(runManager.runSummary?.xpEarned ?? 0)")
                    summaryRow("Coins", value: "+\(runManager.runSummary?.coinsEarned ?? 0)")
                }
                .padding(.vertical, 8)
                
                // Pet catch notification
                if let petId = runManager.runSummary?.petCaught,
                   let pet = GameDataWatch.shared.pet(byId: petId) {
                    VStack(spacing: 4) {
                        Text("✨ NEW PET! ✨")
                            .font(.caption)
                            .foregroundColor(.cyan)
                        Text(pet.emoji)
                            .font(.title)
                        Text(pet.name)
                            .font(.caption)
                            .foregroundColor(.white)
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
