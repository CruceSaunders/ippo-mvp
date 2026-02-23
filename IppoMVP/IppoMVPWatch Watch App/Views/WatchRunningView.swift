import SwiftUI

struct WatchRunningView: View {
    @EnvironmentObject var runManager: WatchRunManager
    @State private var showingEndConfirm = false
    
    var body: some View {
        ZStack {
            // Main running content
            VStack(spacing: 4) {
                // Timer
                Text(runManager.formattedDuration)
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                
                // Distance + Pace row
                HStack(spacing: 12) {
                    VStack(spacing: 0) {
                        Text(runManager.formattedDistance)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                        Text("dist")
                            .font(.system(size: 9))
                            .foregroundColor(.gray)
                    }
                    
                    VStack(spacing: 0) {
                        Text(runManager.formattedPace)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                        Text("/mi")
                            .font(.system(size: 9))
                            .foregroundColor(.gray)
                    }
                }
                
                // HR + Calories row
                HStack(spacing: 14) {
                    HStack(spacing: 3) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.red)
                        Text("\(runManager.currentHR)")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    
                    HStack(spacing: 3) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.orange)
                        Text(runManager.formattedCalories)
                            .font(.system(size: 14, weight: .semibold))
                    }
                }
                .foregroundColor(.white)
                
                // Sprints counter
                HStack(spacing: 3) {
                    Text("Sprints:")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                    Text("\(runManager.sprintsCompleted)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.green)
                    Text("/\(runManager.totalSprints)")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                
                // Recovery indicator
                if runManager.isInRecovery {
                    HStack(spacing: 3) {
                        Image(systemName: "clock")
                            .font(.system(size: 9))
                        Text("Recovery \(Int(runManager.recoveryRemaining))s")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(.cyan)
                }
                
                Spacer()
                
                // Controls
                HStack(spacing: 16) {
                    Button {
                        runManager.pauseRun()
                    } label: {
                        Image(systemName: runManager.isPaused ? "play.fill" : "pause.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(Color.gray.opacity(0.3))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    
                Button {
                    showingEndConfirm = true
                } label: {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(Color.red.opacity(0.8))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .alert("End Run?", isPresented: $showingEndConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("End", role: .destructive) {
                runManager.endRun()
            }
        } message: {
            Text("Are you sure you want to end your run?")
        }
            
            // Sprint result overlay
            if runManager.showSprintResult {
                sprintResultOverlay
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.3), value: runManager.showSprintResult)
            }
        }
    }
    
    // MARK: - Sprint Result Overlay
    private var sprintResultOverlay: some View {
        ZStack {
            Color.black.opacity(0.85)
                .ignoresSafeArea()

            VStack(spacing: 8) {
                if runManager.didCatchPet {
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.orange)

                    Text("New friend caught!")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.orange)

                    Text("Check your phone!")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                } else if runManager.lastSprintSuccess {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.green)

                    Text("Sprint Complete!")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.green)

                    Text("+coins +XP")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                } else {
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
            }
        }
        .allowsHitTesting(false)
    }
}

#Preview {
    WatchRunningView()
        .environmentObject(WatchRunManager.shared)
}
