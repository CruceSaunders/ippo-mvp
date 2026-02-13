import SwiftUI

@main
struct IppoMVPApp: App {
    @StateObject private var userData = UserData.shared
    @StateObject private var watchConnectivity = WatchConnectivityService.shared
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                ContentView()
                    .environmentObject(userData)
                    .environmentObject(watchConnectivity)
                    .preferredColorScheme(.dark)
            } else {
                IppoCompleteOnboardingFlow {
                    hasCompletedOnboarding = true
                }
                .environmentObject(userData)
                .environmentObject(watchConnectivity)
                .preferredColorScheme(.dark)
            }
        }
    }
}
