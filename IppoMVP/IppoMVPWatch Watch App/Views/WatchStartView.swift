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
            
            if runManager.healthKitAuthorized {
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
            } else {
                // Health Access Required
                VStack(spacing: 8) {
                    Image(systemName: "heart.slash.fill")
                        .font(.title2)
                        .foregroundColor(.red)
                    
                    Text("Health Access Required")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("Ippo needs heart rate, distance, and calorie data to track your runs.")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                    
                    Button {
                        runManager.requestHealthKitPermissions()
                    } label: {
                        Text("Grant Access")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.cyan)
                            .cornerRadius(16)
                    }
                    .buttonStyle(.plain)
                    
                    if let error = runManager.healthKitError {
                        Text(error)
                            .font(.system(size: 9))
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 8)
                    }
                }
            }
            
            Spacer()
            
            Text("Sprint. Earn. Rise.")
                .font(.system(size: 11))
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .onAppear {
            // Re-check authorization every time the start view appears
            runManager.checkAndRequestHealthKit()
        }
    }
}

#Preview {
    WatchStartView()
        .environmentObject(WatchRunManager.shared)
}
