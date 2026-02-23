import SwiftUI
import FirebaseCore
import HealthKit

@main
struct IppoMVPApp: App {
    @StateObject private var authService = AuthService.shared
    @StateObject private var userData = UserData.shared
    @StateObject private var watchConnectivity = WatchConnectivityService.shared
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var hasCheckedProfile = false
    @State private var needsProfileSetup = false

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
                } else if needsProfileSetup {
                    IppoCompleteOnboardingFlow {
                        needsProfileSetup = false
                        hasCompletedOnboarding = true
                    }
                    .environmentObject(userData)
                    .environmentObject(watchConnectivity)
                    .environmentObject(authService)
                } else {
                    ContentView()
                        .environmentObject(userData)
                        .environmentObject(watchConnectivity)
                        .environmentObject(authService)
                        .task {
                            await userData.syncFromCloud()
                            if userData.profile.username.isEmpty && userData.ownedPets.isEmpty {
                                needsProfileSetup = true
                            }
                        }
                }
            }
            .preferredColorScheme(.light)
        }
    }
}
