import SwiftUI
import FirebaseCore
import HealthKit
import GoogleSignIn
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNPresentationOptions) -> Void) {
        completionHandler([.banner, .badge, .sound])
    }
}

@main
struct IppoMVPApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var authService = AuthService.shared
    @StateObject private var userData = UserData.shared
    @StateObject private var watchConnectivity = WatchConnectivityService.shared
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    init() {
        FirebaseApp.configure()

        // v2→v3 migration & data integrity: if onboarding was marked complete
        // but no valid user data exists (different persistence key between versions,
        // or data was lost), force the user through onboarding again so they get
        // proper account setup, permissions, and a starter pet.
        if UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") {
            let savedData = DataPersistence.shared.loadUserData()
            if savedData == nil || savedData!.ownedPets.isEmpty {
                UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
            }
        }
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
                            userData.checkWelcomeBackBonus()
                            userData.claimDailyRewards()
                            WatchConnectivityService.shared.pushProfileToWatch()
                            SoundManager.shared.play(.appOpen)
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
