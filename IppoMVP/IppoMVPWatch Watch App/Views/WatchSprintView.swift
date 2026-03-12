import SwiftUI

struct WatchSprintView: View {
    @EnvironmentObject var runManager: WatchRunManager
    @State private var showingEndConfirm = false

    var body: some View {
        ZStack {
            WatchColors.backgroundDark.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 6) {
                    Text("ENCOUNTER!")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(WatchColors.accent)

                    // Progress ring with amber-to-gold gradient
                    ZStack {
                        Circle()
                            .stroke(WatchColors.darkSurface, lineWidth: 6)
                            .frame(width: 80, height: 80)

                        Circle()
                            .trim(from: 0, to: runManager.sprintProgress)
                            .stroke(
                                AngularGradient(
                                    gradient: Gradient(colors: [WatchColors.accent, WatchColors.gold]),
                                    center: .center,
                                    startAngle: .degrees(-90),
                                    endAngle: .degrees(270)
                                ),
                                style: StrokeStyle(lineWidth: 6, lineCap: .round)
                            )
                            .frame(width: 80, height: 80)
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 0.1), value: runManager.sprintProgress)

                        VStack(spacing: 0) {
                            Text("\(Int(runManager.sprintTimeRemaining))")
                                .font(.system(size: 28, weight: .bold, design: .monospaced))
                                .foregroundColor(WatchColors.textPrimaryDark)
                            Text("sec")
                                .font(.system(size: 9, design: .rounded))
                                .foregroundColor(WatchColors.textSecondary)
                        }
                    }

                    // HR + Calories
                    HStack(spacing: 14) {
                        HStack(spacing: 3) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.red)
                            Text("\(runManager.currentHR)")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                        }

                        HStack(spacing: 3) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 10))
                                .foregroundColor(WatchColors.accent)
                            Text(runManager.formattedCalories)
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                        }
                    }
                    .foregroundColor(WatchColors.textPrimaryDark)

                    // Encouragement
                    Text(runManager.sprintTimeRemaining <= 5 ? "Almost there!" : "Keep going!")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(runManager.sprintTimeRemaining <= 5 ? WatchColors.gold : WatchColors.accent)

                    // Stop button
                    Button {
                        showingEndConfirm = true
                    } label: {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 11))
                            .foregroundColor(WatchColors.textPrimaryDark)
                            .frame(width: 32, height: 32)
                            .background(WatchColors.danger.opacity(0.7))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
            }
            .alert("End Run?", isPresented: $showingEndConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("End", role: .destructive) {
                    runManager.endRun()
                }
            } message: {
                Text("Your current sprint will not count.")
            }
        }
    }
}

#Preview {
    WatchSprintView()
        .environmentObject(WatchRunManager.shared)
}
