import SwiftUI

struct WatchRunningView: View {
    @EnvironmentObject var runManager: WatchRunManager
    
    var body: some View {
        VStack(spacing: 8) {
            // Timer
            Text(runManager.formattedDuration)
                .font(.system(size: 36, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
            
            // Stats Row
            HStack(spacing: 16) {
                // Heart Rate
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                    Text("\(runManager.currentHR)")
                        .font(.system(size: 18, weight: .semibold))
                }
                
                // Cadence
                HStack(spacing: 4) {
                    Image(systemName: "bolt.fill")
                        .foregroundColor(.yellow)
                    Text("\(runManager.currentCadence)")
                        .font(.system(size: 18, weight: .semibold))
                }
            }
            .foregroundColor(.white)
            
            Spacer()
            
            // Sprints Counter
            VStack(spacing: 2) {
                Text("Sprints")
                    .font(.caption2)
                    .foregroundColor(.gray)
                HStack(spacing: 4) {
                    Text("\(runManager.sprintsCompleted)")
                        .font(.title2)
                        .foregroundColor(.green)
                    Text("/")
                        .foregroundColor(.gray)
                    Text("\(runManager.totalSprints)")
                        .font(.title2)
                        .foregroundColor(.white)
                }
            }
            
            // Recovery indicator
            if runManager.isInRecovery {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                    Text("Recovery: \(Int(runManager.recoveryRemaining))s")
                }
                .font(.caption)
                .foregroundColor(.cyan)
            }
            
            Spacer()
            
            // Controls
            HStack(spacing: 20) {
                Button {
                    runManager.pauseRun()
                } label: {
                    Image(systemName: runManager.isPaused ? "play.fill" : "pause.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(Color.gray.opacity(0.3))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                
                Button {
                    runManager.endRun()
                } label: {
                    Image(systemName: "stop.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(Color.red.opacity(0.8))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
    }
}

#Preview {
    WatchRunningView()
        .environmentObject(WatchRunManager.shared)
}
