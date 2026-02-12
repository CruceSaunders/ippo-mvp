import SwiftUI

@main
struct IppoMVPWatchApp: App {
    @StateObject private var runManager = WatchRunManager.shared
    @StateObject private var connectivityService = WatchConnectivityServiceWatch.shared
    
    var body: some Scene {
        WindowGroup {
            WatchContentView()
                .environmentObject(runManager)
                .environmentObject(connectivityService)
        }
    }
}
