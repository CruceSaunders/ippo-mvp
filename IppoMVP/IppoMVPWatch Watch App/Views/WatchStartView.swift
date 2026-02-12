import SwiftUI

struct WatchStartView: View {
    @EnvironmentObject var runManager: WatchRunManager
    @EnvironmentObject var connectivity: WatchConnectivityServiceWatch
    
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
            
            // Equipped Pet
            if let petName = connectivity.equippedPetName {
                HStack(spacing: 4) {
                    Text(connectivity.equippedPetEmoji)
                    Text(petName)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            } else {
                Text("No pet equipped")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
    }
}

#Preview {
    WatchStartView()
        .environmentObject(WatchRunManager.shared)
        .environmentObject(WatchConnectivityServiceWatch.shared)
}
