import SwiftUI
import FirebaseCore
import HealthKit
import GoogleSignIn

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
                    IppoCompleteOnboardingFlow {
                        hasCompletedOnboarding = true
                    }
                    .environmentObject(userData)
                    .environmentObject(watchConnectivity)
                    .environmentObject(authService)
                } else if !authService.isAuthenticated {
                    LoginView()
                        .environmentObject(authService)
                        .environmentObject(userData)
                } else {
                    ContentView()
                        .environmentObject(userData)
                        .environmentObject(watchConnectivity)
                        .environmentObject(authService)
                        .task {
                            await userData.syncFromCloud()
                        }
                }
            }
            .preferredColorScheme(.light)
            .onOpenURL { url in
                GIDSignIn.sharedInstance.handle(url)
            }
        }
    }
}
