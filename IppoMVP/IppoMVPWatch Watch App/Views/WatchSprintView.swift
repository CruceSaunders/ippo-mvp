import SwiftUI

struct WatchSprintView: View {
    @EnvironmentObject var runManager: WatchRunManager
    
    var body: some View {
        VStack(spacing: 12) {
            // Sprint indicator
            Text("🏃 SPRINT!")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.cyan)
            
            Spacer()
            
            // Progress ring
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                    .frame(width: 100, height: 100)
                
                // Progress circle
                Circle()
                    .trim(from: 0, to: runManager.sprintProgress)
                    .stroke(Color.cyan, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.1), value: runManager.sprintProgress)
                
                // Time remaining
                VStack(spacing: 0) {
                    Text("\(Int(runManager.sprintTimeRemaining))")
                        .font(.system(size: 36, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    Text("sec")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            // Current stats
            HStack(spacing: 20) {
                VStack(spacing: 2) {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                    Text("\(runManager.currentHR)")
                        .font(.system(size: 18, weight: .semibold))
                }
                
                VStack(spacing: 2) {
                    Image(systemName: "bolt.fill")
                        .foregroundColor(.yellow)
                    Text("\(runManager.currentCadence)")
                        .font(.system(size: 18, weight: .semibold))
                }
            }
            .foregroundColor(.white)
            
            // Encouragement text
            if runManager.sprintTimeRemaining <= 5 {
                Text("Almost there!")
                    .font(.caption)
                    .foregroundColor(.green)
            } else {
                Text("Push harder!")
                    .font(.caption)
                    .foregroundColor(.cyan)
            }
        }
        .padding()
        .background(Color.black)
    }
}

#Preview {
    WatchSprintView()
        .environmentObject(WatchRunManager.shared)
}
