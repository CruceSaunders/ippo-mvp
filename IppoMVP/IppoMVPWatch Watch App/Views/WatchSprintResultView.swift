import SwiftUI

struct WatchSprintResultView: View {
    @EnvironmentObject var runManager: WatchRunManager
    
    var body: some View {
        VStack(spacing: 8) {
            Spacer()
            
            if runManager.lastSprintSuccess {
                // Success: RP Box earned
                Image(systemName: "gift.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("RP Box Earned!")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.green)
                
                Text("+1 RP Box")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            } else {
                // Fail: Sprint not validated
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.red.opacity(0.8))
                
                Text("Sprint Failed")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.red)
                
                Text("Push harder next time!")
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Stats still visible
            HStack(spacing: 10) {
                HStack(spacing: 3) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 9))
                        .foregroundColor(.red)
                    Text("\(runManager.currentHR)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                Text(runManager.formattedDuration)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
}

#Preview {
    WatchSprintResultView()
        .environmentObject(WatchRunManager.shared)
}
