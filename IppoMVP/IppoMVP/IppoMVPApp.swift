import SwiftUI

@main
struct IppoMVPApp: App {
    @StateObject private var userData = UserData.shared
    @StateObject private var watchConnectivity = WatchConnectivityService.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(userData)
                .environmentObject(watchConnectivity)
                .preferredColorScheme(.dark)
        }
    }
}
