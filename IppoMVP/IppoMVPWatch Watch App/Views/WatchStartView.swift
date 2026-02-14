import SwiftUI

struct WatchStartView: View {
    @EnvironmentObject var runManager: WatchRunManager
    
    var body: some View {
        VStack(spacing: 10) {
            // Logo/Title
            Text("IPPO")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundColor(.cyan)
            
            Spacer()
            
            // Start Button
            Button {
                runManager.startRun()
            } label: {
                VStack(spacing: 2) {
                    Image(systemName: "play.fill")
                        .font(.title3)
                    Text("START RUN")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(.black)
                .frame(width: 80, height: 80)
                .background(Color.cyan)
                .clipShape(Circle())
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            Text("Sprint. Earn. Rise.")
                .font(.system(size: 11))
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
}

#Preview {
    WatchStartView()
        .environmentObject(WatchRunManager.shared)
}
