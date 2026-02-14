import SwiftUI

struct WatchSprintView: View {
    @EnvironmentObject var runManager: WatchRunManager
    
    var body: some View {
        VStack(spacing: 6) {
            // Sprint indicator
            Text("SPRINT!")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.cyan)
            
            // Progress ring
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 6)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: runManager.sprintProgress)
                    .stroke(Color.cyan, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.1), value: runManager.sprintProgress)
                
                VStack(spacing: 0) {
                    Text("\(Int(runManager.sprintTimeRemaining))")
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    Text("sec")
                        .font(.system(size: 9))
                        .foregroundColor(.gray)
                }
            }
            
            // Current stats
            HStack(spacing: 14) {
                HStack(spacing: 3) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.red)
                    Text("\(runManager.currentHR)")
                        .font(.system(size: 14, weight: .semibold))
                }
                
                HStack(spacing: 3) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.yellow)
                    Text("\(runManager.currentCadence)")
                        .font(.system(size: 14, weight: .semibold))
                }
            }
            .foregroundColor(.white)
            
            // Encouragement text
            Text(runManager.sprintTimeRemaining <= 5 ? "Almost there!" : "Push harder!")
                .font(.system(size: 11))
                .foregroundColor(runManager.sprintTimeRemaining <= 5 ? .green : .cyan)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color.black)
    }
}

#Preview {
    WatchSprintView()
        .environmentObject(WatchRunManager.shared)
}
