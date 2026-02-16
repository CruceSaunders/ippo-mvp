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
    
    private func requestHealthPermissionsIfNeeded() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        let healthStore = HKHealthStore()
        let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let status = healthStore.authorizationStatus(for: hrType)
        if status == .notDetermined {
            let shareTypes: Set<HKSampleType> = [
                HKWorkoutType.workoutType(),
                HKQuantityType.quantityType(forIdentifier: .heartRate)!,
                HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
                HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
            ]
            let readTypes: Set<HKObjectType> = [
                hrType,
                HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
                HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
                HKObjectType.workoutType()
            ]
            healthStore.requestAuthorization(toShare: shareTypes, read: readTypes) { _, _ in }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if !hasCompletedOnboarding {
                    // First launch: onboarding includes sign-in step
                    IppoCompleteOnboardingFlow {
                        hasCompletedOnboarding = true
                    }
                    .environmentObject(userData)
                    .environmentObject(watchConnectivity)
                    .environmentObject(authService)
                } else if !authService.isAuthenticated {
                    // Returning user who signed out: show login
                    LoginView()
                        .environmentObject(authService)
                } else if needsProfileSetup {
                    // Authenticated but no profile -- force onboarding
                    IppoCompleteOnboardingFlow {
                        needsProfileSetup = false
                        hasCompletedOnboarding = true
                    }
                    .environmentObject(userData)
                    .environmentObject(watchConnectivity)
                    .environmentObject(authService)
                } else {
                    // Signed in: check profile then show main app
                    ContentView()
                        .environmentObject(userData)
                        .environmentObject(watchConnectivity)
                        .environmentObject(authService)
                        .task {
                            await userData.syncFromCloud()
                            if userData.profile.username.isEmpty {
                                needsProfileSetup = true
                            }
                        }
                        .onAppear {
                            requestHealthPermissionsIfNeeded()
                        }
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}
