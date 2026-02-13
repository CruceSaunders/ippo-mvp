import SwiftUI

struct WatchStartView: View {
    @EnvironmentObject var runManager: WatchRunManager
    
    var body: some View {
        VStack(spacing: 16) {
            // Logo/Title
            Text("IPPO")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.cyan)
            
            Spacer()
            
            // Start Button
            Button {
                runManager.startRun()
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "play.fill")
                        .font(.title2)
                    Text("START")
                        .font(.system(size: 14, weight: .semibold))
                    Text("RUN")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.black)
                .frame(width: 100, height: 100)
                .background(Color.cyan)
                .clipShape(Circle())
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            // Simple tagline instead of pet display
            Text("Sprint. Earn. Rise.")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
    }
}

#Preview {
    WatchStartView()
        .environmentObject(WatchRunManager.shared)
}
