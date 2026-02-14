import SwiftUI
import FirebaseCore

@main
struct IppoMVPApp: App {
    @StateObject private var authService = AuthService.shared
    @StateObject private var userData = UserData.shared
    @StateObject private var watchConnectivity = WatchConnectivityService.shared
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if !hasCompletedOnboarding {
                    // First launch: show onboarding
                    IppoCompleteOnboardingFlow {
                        hasCompletedOnboarding = true
                    }
                    .environmentObject(userData)
                    .environmentObject(watchConnectivity)
                } else if !authService.isAuthenticated {
                    // Not signed in: show login
                    LoginView()
                        .environmentObject(authService)
                } else {
                    // Signed in: show main app
                    ContentView()
                        .environmentObject(userData)
                        .environmentObject(watchConnectivity)
                        .environmentObject(authService)
                        .task {
                            // Sync from cloud after sign-in
                            await userData.syncFromCloud()
                        }
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}
