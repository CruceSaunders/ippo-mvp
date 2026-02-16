import SwiftUI

struct WatchContentView: View {
    @EnvironmentObject var runManager: WatchRunManager
    
    var body: some View {
        Group {
            switch runManager.runState {
            case .idle:
                WatchStartView()
            case .running:
                WatchRunningView()
            case .sprinting:
                WatchSprintView()
            case .sprintResult:
                WatchSprintResultView()
            case .summary:
                WatchSummaryView()
            }
        }
    }
}

#Preview {
    WatchContentView()
        .environmentObject(WatchRunManager.shared)
}
