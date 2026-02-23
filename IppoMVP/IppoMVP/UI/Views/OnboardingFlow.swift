import SwiftUI
import HealthKit
import AuthenticationServices

struct IppoCompleteOnboardingFlow: View {
    let onComplete: () -> Void
    @EnvironmentObject var userData: UserData
    @EnvironmentObject var authService: AuthService
    @State private var step = 0
    @State private var selectedStarterPetId: String?
    @State private var age: Int = 25
    @State private var displayName: String = ""
    @State private var isSigningIn = false
    @State private var signInError: String?

    private let totalSteps = 8

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                progressBar

                TabView(selection: $step) {
                    welcomeScreen.tag(0)
                    howItWorksScreen.tag(1)
                    starterPetScreen.tag(2)
                    createAccountScreen.tag(3)
                    ageScreen.tag(4)
                    healthPermissionScreen.tag(5)
                    notificationScreen.tag(6)
                    readyScreen.tag(7)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: step)
            }
        }
        .preferredColorScheme(.light)
    }

    // MARK: - Progress Bar
    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(AppColors.surfaceElevated)
                    .frame(height: 4)
                RoundedRectangle(cornerRadius: 3)
                    .fill(AppColors.accent)
                    .frame(width: geo.size.width * CGFloat(step + 1) / CGFloat(totalSteps), height: 4)
            }
        }
        .frame(height: 4)
        .padding(.horizontal, 24)
        .padding(.top, 12)
    }

    // MARK: - Screen 1: Welcome
    private var welcomeScreen: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "pawprint.fill")
                .font(.system(size: 64))
                .foregroundColor(AppColors.accent)

            Text("Welcome to Ippo")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.textPrimary)

            Text("Catch pets while you run.\nWatch them grow.")
                .font(.system(size: 18, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)

            Spacer()

            onboardingButton("Get Started") { step = 1 }
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Screen 2: How It Works
    private var howItWorksScreen: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 32) {
                howItWorksItem(
                    icon: "applewatch",
                    text: "Run with your Apple Watch. Feel a vibration? Sprint!"
                )
                howItWorksItem(
                    icon: "sparkles",
                    text: "Sprint fast enough and you might catch a new friend"
                )
                howItWorksItem(
                    icon: "heart.fill",
                    text: "Take care of your pets daily. Watch them grow up."
                )
            }

            Spacer()
            onboardingButton("Next") { step = 2 }
        }
        .padding(.horizontal, 32)
    }

    private func howItWorksItem(icon: String, text: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(AppColors.accent)
                .frame(width: 44)

            Text(text)
                .font(.system(size: 16, design: .rounded))
                .foregroundColor(AppColors.textPrimary)
        }
    }

    // MARK: - Screen 3: Starter Pet
    private var starterPetScreen: some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 20)

            Text("Choose your first companion")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.textPrimary)

            Spacer()

            HStack(spacing: 12) {
                ForEach(GameData.petDefinitions.filter { $0.isStarter }) { pet in
                    starterPetCard(pet)
                }
            }

            Spacer()

            onboardingButton("Choose") { step = 3 }
                .disabled(selectedStarterPetId == nil)
                .opacity(selectedStarterPetId == nil ? 0.5 : 1)
        }
        .padding(.horizontal, 20)
    }

    private func starterPetCard(_ pet: GamePetDefinition) -> some View {
        let isSelected = selectedStarterPetId == pet.id
        return VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? AppColors.accentSoft.opacity(0.3) : AppColors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? AppColors.accent : Color.clear, lineWidth: 3)
                    )

                Image(pet.stageImageNames.first ?? "pet_placeholder")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(16)
            }
            .frame(height: 120)

            Text(pet.name)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.textPrimary)

            Text(pet.description)
                .font(.system(size: 10, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(3)
        }
        .frame(maxWidth: .infinity)
        .onTapGesture { selectedStarterPetId = pet.id }
    }

    // MARK: - Screen 4: Create Account
    private var createAccountScreen: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "person.circle.fill")
                .font(.system(size: 56))
                .foregroundColor(AppColors.accent)

            Text("Create Your Account")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.textPrimary)

            Text("Sign in to save your progress")
                .font(.system(size: 16, design: .rounded))
                .foregroundColor(AppColors.textSecondary)

            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { result in
                handleAppleSignIn(result)
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 50)
            .cornerRadius(12)

            if let error = signInError {
                Text(error)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(AppColors.danger)
            }

            if isSigningIn {
                ProgressView()
                    .tint(AppColors.accent)
            }

            Spacer()
        }
        .padding(.horizontal, 32)
    }

    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        isSigningIn = true
        signInError = nil
        Task {
            await authService.handleSignInWithApple(result)
            if authService.isAuthenticated {
                if let name = authService.displayName, !name.isEmpty {
                    displayName = name
                }
                userData.profile.displayName = displayName.isEmpty ? "Runner" : displayName
                userData.isLoggedIn = true
                isSigningIn = false
                step = 4
            } else {
                signInError = authService.errorMessage ?? "Sign in failed. Please try again."
                isSigningIn = false
            }
        }
    }

    // MARK: - Screen 5: Age
    private var ageScreen: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("How old are you?")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.textPrimary)

            Text("We use this to detect when you're sprinting")
                .font(.system(size: 15, design: .rounded))
                .foregroundColor(AppColors.textSecondary)

            Picker("Age", selection: $age) {
                ForEach(14...65, id: \.self) { a in
                    Text("\(a)").tag(a)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 150)

            let maxHR = 220 - age
            Text("Estimated max heart rate: \(maxHR) BPM")
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(AppColors.textTertiary)

            Spacer()

            onboardingButton("Continue") {
                userData.profile.age = age
                step = 5
            }
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Screen 6: Health Permission
    private var healthPermissionScreen: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 56))
                .foregroundColor(AppColors.success)

            Text("Health Access")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.textPrimary)

            Text("Ippo needs access to your heart rate and workout data to validate your sprints.")
                .font(.system(size: 15, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)

            Spacer()

            onboardingButton("Continue") {
                requestHealthPermissions()
                step = 6
            }
        }
        .padding(.horizontal, 32)
    }

    private func requestHealthPermissions() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        let healthStore = HKHealthStore()
        let shareTypes: Set<HKSampleType> = [
            HKWorkoutType.workoutType(),
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
        ]
        let readTypes: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKObjectType.workoutType()
        ]
        healthStore.requestAuthorization(toShare: shareTypes, read: readTypes) { _, _ in }
    }

    // MARK: - Screen 7: Notifications
    private var notificationScreen: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "bell.badge.fill")
                .font(.system(size: 56))
                .foregroundColor(AppColors.accent)

            Text("Stay Connected")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.textPrimary)

            Text("Your pet will let you know when they need you")
                .font(.system(size: 15, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)

            Spacer()

            onboardingButton("Allow Notifications") {
                Task {
                    _ = await NotificationSystem.shared.requestPermission()
                    step = 7
                }
            }
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Screen 8: Ready
    private var readyScreen: some View {
        VStack(spacing: 24) {
            Spacer()

            if let starterId = selectedStarterPetId, let pet = GameData.pet(byId: starterId) {
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(AppColors.accentSoft.opacity(0.2))

                    Image(pet.stageImageNames.first ?? "pet_placeholder")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(32)
                }
                .frame(height: 200)

                Text("\(pet.name) is excited to meet you!")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)
                    .multilineTextAlignment(.center)
            }

            Text("Start your first run on Apple Watch, or explore the app")
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)

            Spacer()

            onboardingButton("Let's Go!") {
                if let starterId = selectedStarterPetId {
                    userData.addPet(definitionId: starterId, equip: true)
                    userData.starterPetId = starterId
                }
                userData.save()
                onComplete()
            }
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Reusable Button
    private func onboardingButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(AppColors.accent)
                .cornerRadius(14)
        }
        .padding(.bottom, 16)
    }
}
