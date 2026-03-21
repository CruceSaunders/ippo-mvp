import SwiftUI
import HealthKit
import AuthenticationServices
import UserNotifications
import WatchConnectivity
import AudioToolbox

struct IppoCompleteOnboardingFlow: View {
    let onComplete: () -> Void
    @EnvironmentObject var userData: UserData
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var watchConnectivity: WatchConnectivityService
    @State private var step = 0
    @State private var selectedStarterPetId: String?
    @State private var age: Int = 25
    @State private var displayName: String = ""
    @State private var username: String = ""
    @State private var usernameError: String?
    @State private var isCheckingUsername = false
    @State private var isSigningIn = false
    @State private var signInError: String?
    @State private var isReturningUser = false
    @State private var isCheckingCloudData = false

    // Permission state
    @State private var healthPermissionGranted = false
    @State private var healthPermissionDenied = false
    @State private var isCheckingHealthPermission = false
    @State private var notificationPermissionGranted = false
    @State private var notificationPermissionDenied = false
    @State private var permissionsCheckedOnce = false

    // Sprint demo state
    @State private var sprintDemoPhase: SprintDemoPhase = .idle
    @State private var sprintDemoCountdown: Int = 5
    @State private var sprintDemoTimer: Timer?
    @State private var sprintDemoProgress: CGFloat = 0

    // Care tutorial intro
    @State private var showCareTutorialIntro = true

    private let totalSteps = 15

    enum SprintDemoPhase {
        case idle, buzzing, sprinting, complete
    }

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                progressBar

                Group {
                    switch step {
                    case 0: welcomeScreen
                    case 1: authScreen
                    case 2: chooseUsernameScreen
                    case 3: ageScreen
                    case 4: starterPetScreen
                    case 5: permissionsScreen
                    case 6: watchSetupScreen
                    case 7: howRunsWorkScreen
                    case 8: vibrationsAndSprintsScreen
                    case 9: theChaseScreen
                    case 10: catchingPetsScreen
                    case 11: coinsAndXPScreen
                    case 12: careTutorialScreen
                    case 13: evolutionScreen
                    case 14: readyScreen
                    default: welcomeScreen
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
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
                    .animation(.easeInOut(duration: 0.3), value: step)
            }
        }
        .frame(height: 4)
        .padding(.horizontal, 24)
        .padding(.top, 12)
    }

    // MARK: - Step 0: Welcome

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

            onboardingButton("Get Started") {
                isReturningUser = false
                step = 1
            }

            Button {
                isReturningUser = true
                step = 1
            } label: {
                Text("I already have an account")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.accent)
            }
            .padding(.bottom, 16)
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Step 1: Sign In

    private var authScreen: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "person.circle.fill")
                .font(.system(size: 56))
                .foregroundColor(AppColors.accent)

            Text(isReturningUser ? "Welcome Back" : "Create Your Account")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.textPrimary)

            Text(isReturningUser ? "Sign in to restore your pets" : "Sign in to save your progress")
                .font(.system(size: 16, design: .rounded))
                .foregroundColor(AppColors.textSecondary)

            SignInWithAppleButton(.signIn) { request in
                let appleRequest = authService.startSignInWithApple()
                request.requestedScopes = appleRequest.requestedScopes
                request.nonce = appleRequest.nonce
            } onCompletion: { result in
                handleAppleSignIn(result)
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 50)
            .cornerRadius(12)

            Button {
                handleGoogleSignIn()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "g.circle.fill")
                        .font(.system(size: 20))
                    Text("Sign in with Google")
                        .font(.system(size: 17, weight: .medium))
                }
                .foregroundColor(AppColors.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(AppColors.surface)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppColors.textTertiary.opacity(0.3), lineWidth: 1)
                )
            }

            if let error = signInError {
                Text(error)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(AppColors.danger)
            }

            if isSigningIn || isCheckingCloudData {
                VStack(spacing: 8) {
                    ProgressView()
                        .tint(AppColors.accent)
                    if isCheckingCloudData {
                        Text("Checking for your data...")
                            .font(.system(size: 13, design: .rounded))
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal, 32)
    }

    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        if case .failure(let error) = result,
           (error as NSError).code == ASAuthorizationError.canceled.rawValue {
            return
        }

        isSigningIn = true
        signInError = nil
        Task {
            await authService.handleSignInWithApple(result)
            isSigningIn = false
            guard authService.isAuthenticated, authService.userId != nil else {
                signInError = authService.errorMessage ?? "Sign in failed. Please try again."
                return
            }
            if let name = authService.displayName, !name.isEmpty, displayName.isEmpty {
                displayName = name
            }
            userData.isLoggedIn = true
            await handlePostSignIn()
        }
    }

    private func handleGoogleSignIn() {
        isSigningIn = true
        signInError = nil
        Task {
            await authService.signInWithGoogle()
            isSigningIn = false
            guard authService.isAuthenticated, authService.userId != nil else {
                if authService.errorMessage != nil {
                    signInError = authService.errorMessage
                }
                return
            }
            if let name = authService.displayName, !name.isEmpty, displayName.isEmpty {
                displayName = name
            }
            userData.isLoggedIn = true
            await handlePostSignIn()
        }
    }

    private func handlePostSignIn() async {
        isCheckingCloudData = true
        if let cloudData = await CloudService.shared.loadUserData(),
           !cloudData.ownedPets.isEmpty {
            userData.profile = cloudData.profile
            userData.ownedPets = cloudData.ownedPets
            userData.inventory = cloudData.inventory
            userData.runHistory = cloudData.runHistory
            userData.isLoggedIn = true
            userData.save()
            isCheckingCloudData = false
            // Returning user: skip profile setup but still do permissions + tutorial
            step = 5
            return
        }
        isCheckingCloudData = false
        step = 2
    }

    // MARK: - Step 2: Choose Username

    private var chooseUsernameScreen: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "person.text.rectangle")
                .font(.system(size: 48, weight: .medium))
                .foregroundColor(AppColors.accent)

            Text("Set Up Your Profile")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.textPrimary)

            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Display Name")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)

                    TextField("Your name", text: $displayName)
                        .font(.system(size: 18, design: .rounded))
                        .padding(14)
                        .background(AppColors.surface)
                        .cornerRadius(12)
                        .onChange(of: displayName) { _, newValue in
                            if displayName.count > 30 { displayName = String(displayName.prefix(30)) }
                        }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Username")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)

                    HStack {
                        Text("@")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundColor(AppColors.textSecondary)
                        TextField("username", text: $username)
                            .font(.system(size: 18, design: .rounded))
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .onChange(of: username) { _, newValue in
                                username = newValue.lowercased().filter { $0.isLetter || $0.isNumber || $0 == "_" || $0 == "." }
                                if username.count > 20 { username = String(username.prefix(20)) }
                                usernameError = nil
                            }
                    }
                    .padding(14)
                    .background(AppColors.surface)
                    .cornerRadius(12)

                    if let error = usernameError {
                        Text(error)
                            .font(.system(size: 13, design: .rounded))
                            .foregroundColor(AppColors.danger)
                    }

                    Text("Letters, numbers, underscores, and periods only")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(AppColors.textTertiary)
                }
            }

            if isCheckingUsername {
                ProgressView()
                    .tint(AppColors.accent)
            }

            Spacer()

            onboardingButton("Continue") {
                validateAndSetUsername()
            }
            .disabled(username.count < 3 || displayName.trimmingCharacters(in: .whitespaces).isEmpty || isCheckingUsername)
            .opacity(username.count < 3 || displayName.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
        }
        .padding(.horizontal, 32)
    }

    private func validateAndSetUsername() {
        let trimmed = username.lowercased().trimmingCharacters(in: .whitespaces)
        guard trimmed.count >= 3 else {
            usernameError = "Username must be at least 3 characters"
            return
        }

        let trimmedDisplayName = displayName.trimmingCharacters(in: .whitespaces)
        guard !trimmedDisplayName.isEmpty else { return }

        isCheckingUsername = true
        usernameError = nil

        Task {
            let taken = await CloudService.shared.isUsernameTaken(trimmed)
            if taken {
                usernameError = "That username is already taken"
                isCheckingUsername = false
                return
            }

            let reserved = await CloudService.shared.reserveUsername(trimmed)
            if !reserved {
                usernameError = "Failed to reserve username. Try again."
                isCheckingUsername = false
                return
            }

            userData.profile.username = trimmed
            userData.profile.displayName = trimmedDisplayName
            userData.save()
            isCheckingUsername = false
            step = 3
        }
    }

    // MARK: - Step 3: Age

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
                step = 4
            }
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Step 4: Starter Pet

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

            onboardingButton("Choose") { step = 5 }
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

    // MARK: - Step 5: Permissions (Hardened)

    private var permissionsScreen: some View {
        let allGranted = healthPermissionGranted && notificationPermissionGranted
        let canProceed = healthPermissionGranted

        return VStack(spacing: 24) {
            Spacer()

            HStack(spacing: 16) {
                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 40))
                    .foregroundColor(AppColors.success)
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 40))
                    .foregroundColor(AppColors.accent)
            }

            Text(allGranted ? "All Set!" : (canProceed ? "Almost Done!" : "Before Your First Run"))
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.textPrimary)

            VStack(spacing: 16) {
                permissionRow(
                    icon: "heart.fill",
                    color: healthPermissionGranted ? AppColors.success : (healthPermissionDenied ? AppColors.danger : AppColors.success),
                    title: "Health Access",
                    subtitle: healthPermissionDenied
                        ? "Required — tap Open Settings below to enable"
                        : healthPermissionGranted
                            ? "Granted"
                            : "Heart rate and workout data to validate your sprints",
                    checkmark: healthPermissionGranted
                )
                permissionRow(
                    icon: "bell.fill",
                    color: notificationPermissionGranted ? AppColors.success : (notificationPermissionDenied ? AppColors.textSecondary : AppColors.accent),
                    title: "Notifications (Optional)",
                    subtitle: notificationPermissionDenied
                        ? "You can enable in Settings for pet care reminders"
                        : notificationPermissionGranted
                            ? "Granted"
                            : "Your pet will let you know when they need you",
                    checkmark: notificationPermissionGranted
                )
            }
            .padding(.horizontal, 8)

            if healthPermissionDenied {
                VStack(spacing: 12) {
                    Text("Ippo needs Health access to track your runs. Please enable it in Settings.")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(AppColors.danger)
                        .multilineTextAlignment(.center)

                    HStack(spacing: 12) {
                        Button {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            Text("Open Settings")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(AppColors.accent)
                                .cornerRadius(10)
                        }

                        Button {
                            Task { await refreshAllPermissionStatuses() }
                        } label: {
                            Text("Check Again")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundColor(AppColors.accent)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(AppColors.accentSoft.opacity(0.3))
                                .cornerRadius(10)
                        }
                    }
                }
            }

            if isCheckingHealthPermission {
                ProgressView()
                    .tint(AppColors.accent)
            }

            Spacer()

            if canProceed {
                onboardingButton("Continue") {
                    step = 6
                }
            } else if !healthPermissionDenied {
                onboardingButton("Continue") {
                    requestAllPermissions()
                }
            } else {
                onboardingButton("Continue") {
                    step = 6
                }
                .disabled(true)
                .opacity(0.5)
            }
        }
        .padding(.horizontal, 32)
        .onAppear {
            if !permissionsCheckedOnce {
                permissionsCheckedOnce = true
                Task { await refreshAllPermissionStatuses() }
            }
        }
    }

    private func permissionRow(icon: String, color: Color, title: String, subtitle: String, checkmark: Bool = false) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: checkmark ? "checkmark.circle.fill" : icon)
                    .font(.system(size: 20))
                    .foregroundColor(checkmark ? AppColors.success : color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)
                Text(subtitle)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
            }

            Spacer()
        }
    }

    private func refreshAllPermissionStatuses() async {
        checkHealthPermissionStatus()
        await checkNotificationPermissionStatus()
    }

    private func requestAllPermissions() {
        isCheckingHealthPermission = true

        guard HKHealthStore.isHealthDataAvailable() else {
            healthPermissionGranted = true
            isCheckingHealthPermission = false
            Task {
                notificationPermissionGranted = await NotificationSystem.shared.requestPermission()
                await checkNotificationPermissionStatus()
                if healthPermissionGranted { step = 6 }
            }
            return
        }

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

        healthStore.requestAuthorization(toShare: shareTypes, read: readTypes) { _, _ in
            DispatchQueue.main.async {
                checkHealthPermissionStatus()
                Task {
                    notificationPermissionGranted = await NotificationSystem.shared.requestPermission()
                    await checkNotificationPermissionStatus()
                    if healthPermissionGranted {
                        step = 6
                    }
                }
            }
        }
    }

    private func checkHealthPermissionStatus() {
        guard HKHealthStore.isHealthDataAvailable() else {
            healthPermissionGranted = true
            healthPermissionDenied = false
            isCheckingHealthPermission = false
            return
        }

        let healthStore = HKHealthStore()
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }

        let status = healthStore.authorizationStatus(for: heartRateType)
        switch status {
        case .sharingAuthorized:
            healthPermissionGranted = true
            healthPermissionDenied = false
        case .sharingDenied:
            healthPermissionGranted = false
            healthPermissionDenied = true
        case .notDetermined:
            healthPermissionGranted = false
            healthPermissionDenied = false
        @unknown default:
            break
        }
        isCheckingHealthPermission = false
    }

    private func checkNotificationPermissionStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            notificationPermissionGranted = true
            notificationPermissionDenied = false
        case .denied:
            notificationPermissionGranted = false
            notificationPermissionDenied = true
        case .notDetermined:
            notificationPermissionGranted = false
            notificationPermissionDenied = false
        @unknown default:
            break
        }
    }

    // MARK: - Step 6: Watch Setup

    @State private var watchPollTimer: Timer?

    private var watchSetupScreen: some View {
        let watchReady = watchConnectivity.isPaired && watchConnectivity.isWatchAppInstalled

        return VStack(spacing: 24) {
            Spacer()

            Image(systemName: "applewatch")
                .font(.system(size: 64))
                .foregroundColor(watchReady ? AppColors.success : AppColors.accent)

            Text(watchReady ? "Watch Connected!" : "Connect Your Watch")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.textPrimary)

            Text("Ippo runs on your Apple Watch during workouts")
                .font(.system(size: 15, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)

            VStack(spacing: 16) {
                watchStatusRow(
                    title: "Watch Paired",
                    isOK: watchConnectivity.isPaired,
                    helpText: "Pair your Apple Watch in the Watch app"
                )
                watchStatusRow(
                    title: "Ippo Installed on Watch",
                    isOK: watchConnectivity.isWatchAppInstalled,
                    helpText: "Tap the button below to install"
                )
            }
            .padding(20)
            .background(AppColors.surface)
            .cornerRadius(16)

            if !watchReady {
                Button {
                    if let url = URL(string: "itms-watchs://") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.up.forward.app")
                            .font(.system(size: 15))
                        Text("Open Watch App to Install Ippo")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(AppColors.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(AppColors.accentSoft.opacity(0.3))
                    .cornerRadius(12)
                }
            }

            if watchReady {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppColors.success)
                    Text("Your Watch is ready!")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(AppColors.success)
                }
            }

            Spacer()

            onboardingButton("Continue") {
                watchPollTimer?.invalidate()
                watchPollTimer = nil
                step = 7
            }
            .disabled(!watchReady)
            .opacity(watchReady ? 1 : 0.5)

            if !watchReady {
                Text("Apple Watch is required to use Ippo")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.warning)
                    .padding(.bottom, 8)
            }
        }
        .padding(.horizontal, 32)
        .onAppear {
            watchConnectivity.refreshStatus()
            watchPollTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
                Task { @MainActor in
                    watchConnectivity.refreshStatus()
                }
            }
        }
        .onDisappear {
            watchPollTimer?.invalidate()
            watchPollTimer = nil
        }
    }

    private func watchStatusRow(title: String, isOK: Bool, helpText: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: isOK ? "checkmark.circle.fill" : "xmark.circle")
                .font(.system(size: 22))
                .foregroundColor(isOK ? AppColors.success : AppColors.textTertiary)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)
                if !isOK {
                    Text(helpText)
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            Spacer()
        }
    }

    // MARK: - Step 7: How Runs Work

    private var howRunsWorkScreen: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("How a Run Works")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.textPrimary)

            watchMockup {
                VStack(spacing: 4) {
                    Text("IPPO")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.accent)

                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 22))
                        .foregroundColor(AppColors.accentSoft)
                        .padding(.vertical, 4)

                    Circle()
                        .fill(AppColors.accent)
                        .frame(width: 50, height: 50)
                        .overlay(
                            VStack(spacing: 1) {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 12))
                                Text("START RUN")
                                    .font(.system(size: 6, weight: .semibold, design: .rounded))
                            }
                            .foregroundColor(.white)
                        )

                    Text("Run. Catch. Grow.")
                        .font(.system(size: 7, design: .rounded))
                        .foregroundColor(.gray)
                }
            }

            VStack(spacing: 16) {
                stepBullet(number: 1, text: "Open Ippo on your Apple Watch")
                stepBullet(number: 2, text: "Tap Start Run and begin running")
                stepBullet(number: 3, text: "Ippo handles everything else automatically")
            }

            Spacer()

            onboardingButton("Next") { step = 8 }
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Step 8: Vibrations & Sprints (Interactive)

    private var vibrationsAndSprintsScreen: some View {
        VStack(spacing: 20) {
            Spacer()

            Text("Feel the Buzz? Sprint!")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.textPrimary)

            Text("During your run, your Watch vibrates 3 times.\nThat's your signal to sprint!")
                .font(.system(size: 15, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)

            // Interactive sprint demo
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(AppColors.surface)
                    .frame(height: 200)

                switch sprintDemoPhase {
                case .idle:
                    VStack(spacing: 16) {
                        Image(systemName: "hand.tap.fill")
                            .font(.system(size: 40))
                            .foregroundColor(AppColors.accent)
                        Text("Tap to feel what it's like")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundColor(AppColors.textSecondary)
                    }

                case .buzzing:
                    VStack(spacing: 12) {
                        Image(systemName: "iphone.radiowaves.left.and.right")
                            .font(.system(size: 44))
                            .foregroundColor(AppColors.accent)
                            .symbolEffect(.pulse, options: .repeating)
                        Text("Buzz! Buzz! Buzz!")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(AppColors.accent)
                    }

                case .sprinting:
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .stroke(AppColors.surfaceElevated, lineWidth: 6)
                                .frame(width: 80, height: 80)
                            Circle()
                                .trim(from: 0, to: sprintDemoProgress)
                                .stroke(AppColors.accent, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                                .frame(width: 80, height: 80)
                                .rotationEffect(.degrees(-90))
                            Text("\(sprintDemoCountdown)s")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(AppColors.textPrimary)
                        }
                        Text("SPRINT!")
                            .font(.system(size: 18, weight: .heavy, design: .rounded))
                            .foregroundColor(AppColors.accent)
                    }

                case .complete:
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 44))
                            .foregroundColor(AppColors.success)
                        Text("Sprint Complete!")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(AppColors.success)
                        HStack(spacing: 16) {
                            HStack(spacing: 3) {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 8))
                                Text("+10")
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                            }
                            .foregroundColor(AppColors.coins)
                            HStack(spacing: 3) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 10))
                                Text("+20 XP")
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                            }
                            .foregroundColor(AppColors.xp)
                        }
                    }
                }
            }
            .onTapGesture {
                if sprintDemoPhase == .idle || sprintDemoPhase == .complete {
                    startSprintDemo()
                }
            }

            Text("~30 seconds per sprint. Your heart rate proves you're pushing it.")
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(AppColors.textTertiary)
                .multilineTextAlignment(.center)

            Spacer()

            onboardingButton("Next") { step = 9 }
        }
        .padding(.horizontal, 32)
        .onDisappear {
            sprintDemoTimer?.invalidate()
            sprintDemoTimer = nil
        }
    }

    private func vibratePhone() {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }

    private func startSprintDemo() {
        sprintDemoPhase = .buzzing
        sprintDemoCountdown = 5
        sprintDemoProgress = 0

        // AudioToolbox vibration is the most reliable on-device buzz
        vibratePhone()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { self.vibratePhone() }

        // Also buzz the watch if reachable
        WatchConnectivityService.shared.sendHapticBuzz()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            self.sprintDemoPhase = .sprinting
            self.sprintDemoCountdown = 5

            self.sprintDemoTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
                if self.sprintDemoCountdown > 1 {
                    self.sprintDemoCountdown -= 1
                    withAnimation(.linear(duration: 0.9)) {
                        self.sprintDemoProgress = CGFloat(5 - self.sprintDemoCountdown + 1) / 5.0
                    }
                } else {
                    timer.invalidate()
                    self.sprintDemoTimer = nil
                    withAnimation(.easeOut(duration: 0.3)) {
                        self.sprintDemoProgress = 1.0
                    }
                    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
                    self.sprintDemoPhase = .complete
                }
            }
            withAnimation(.linear(duration: 0.9)) {
                self.sprintDemoProgress = 1.0 / 5.0
            }
        }
    }

    // MARK: - Step 9: The Chase

    private var theChaseScreen: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("Sprint Encounters")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.textPrimary)

            // Timeline visualization
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    timelineNode(icon: "figure.run", label: "Run", color: AppColors.accent)
                    timelineLine()
                    timelineNode(icon: "iphone.radiowaves.left.and.right", label: "Vibrate", color: AppColors.warning)
                    timelineLine()
                    timelineNode(icon: "bolt.fill", label: "Sprint!", color: AppColors.danger)
                    timelineLine()
                    timelineNode(icon: "gift.fill", label: "Reward", color: AppColors.success)
                }
            }
            .padding(.vertical, 20)

            VStack(spacing: 16) {
                infoBubble(
                    icon: "timer",
                    text: "Encounters happen every 1\u{2013}3 minutes during your run"
                )
                infoBubble(
                    icon: "bolt.heart.fill",
                    text: "Sprint hard for ~30 seconds. Your heart rate proves the effort."
                )
                infoBubble(
                    icon: "sparkles",
                    text: "Every successful sprint earns coins and XP. But sometimes..."
                )
            }

            Spacer()

            onboardingButton("What happens next?") { step = 10 }
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Step 10: Catching Pets

    private var catchingPetsScreen: some View {
        VStack(spacing: 20) {
            Spacer()

            Text("Catch New Friends!")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.textPrimary)

            // Mock Watch catch screen
            watchMockup {
                VStack(spacing: 6) {
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.orange)
                    Text("New friend\ncaught!")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    Text("Check your phone!")
                        .font(.system(size: 7, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                }
            }

            VStack(spacing: 12) {
                infoBubble(
                    icon: "waveform",
                    text: "5 quick vibrations = you caught a pet!"
                )
                infoBubble(
                    icon: "questionmark.circle",
                    text: "Each sprint has a chance to catch a rare pet"
                )
            }

            // Pet silhouette grid
            VStack(spacing: 8) {
                let totalPets = GameData.petDefinitions.count
                Text("\(totalPets) pets to discover")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)

                let starters = GameData.petDefinitions.filter { $0.isStarter }
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: min(totalPets, 5)), spacing: 8) {
                    ForEach(Array(GameData.petDefinitions.enumerated()), id: \.offset) { i, def in
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(AppColors.surfaceElevated)
                                .frame(height: 48)
                            if starters.contains(where: { $0.id == def.id }) {
                                Image(def.stageImageNames.first ?? "")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .padding(6)
                                    .opacity(0.4)
                            } else {
                                Image(systemName: "questionmark")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(AppColors.textTertiary)
                            }
                        }
                    }
                }
            }
            .padding(16)
            .background(AppColors.surface)
            .cornerRadius(16)

            Spacer()

            onboardingButton("Next") { step = 11 }
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Step 11: Coins, XP & Shop

    private var coinsAndXPScreen: some View {
        VStack(spacing: 20) {
            Spacer()

            Text("Earn & Spend")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.textPrimary)

            // Earn section
            VStack(spacing: 12) {
                Text("EARN")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundColor(AppColors.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 16) {
                    earnCard(icon: "bolt.fill", label: "Sprint", coinAmount: "8\u{2013}12", xpAmount: "15\u{2013}25")
                    earnCard(icon: "pawprint.fill", label: "Catch", coinAmount: "+25", xpAmount: nil)
                    earnCard(icon: "figure.run", label: "Per Min", coinAmount: "+1", xpAmount: "+5")
                }
            }
            .padding(16)
            .background(AppColors.surface)
            .cornerRadius(16)

            // Spend section
            VStack(spacing: 12) {
                Text("SPEND")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundColor(AppColors.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 12) {
                    shopPreviewItem(icon: "leaf.fill", name: "Food", price: 3)
                    shopPreviewItem(icon: "drop.fill", name: "Water", price: 2)
                    shopPreviewItem(icon: "bolt.circle.fill", name: "XP Boost", price: 40)
                }
            }
            .padding(16)
            .background(AppColors.surface)
            .cornerRadius(16)

            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "gift.fill")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.accent)
                    Text("You start with 20 coins, 3 food, and 3 water")
                        .font(.system(size: 13, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)
                }
            }

            Spacer()

            onboardingButton("Next") { step = 12 }
        }
        .padding(.horizontal, 32)
    }

    private func earnCard(icon: String, label: String, coinAmount: String, xpAmount: String?) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(AppColors.accent)
            Text(label)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
            HStack(spacing: 2) {
                Image(systemName: "circle.fill")
                    .font(.system(size: 7))
                    .foregroundColor(AppColors.coins)
                Text(coinAmount)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.coins)
            }
            if let xp = xpAmount {
                HStack(spacing: 2) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundColor(AppColors.xp)
                    Text(xp)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(AppColors.xp)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(AppColors.surfaceElevated)
        .cornerRadius(12)
    }

    private func shopPreviewItem(icon: String, name: String, price: Int) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(AppColors.accent)
            Text(name)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.textPrimary)
            HStack(spacing: 2) {
                Image(systemName: "circle.fill")
                    .font(.system(size: 7))
                    .foregroundColor(AppColors.coins)
                Text("\(price)")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.coins)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(AppColors.surfaceElevated)
        .cornerRadius(12)
    }

    // MARK: - Step 12: Care Tutorial

    private var careTutorialScreen: some View {
        Group {
            if showCareTutorialIntro {
                careTutorialIntroView
            } else {
                TutorialOverlayView(
                    petImageName: currentStarterPetImageName,
                    onComplete: { step = 13 }
                )
            }
        }
    }

    private var careTutorialIntroView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "heart.fill")
                .font(.system(size: 48))
                .foregroundColor(AppColors.petHappy)

            Text("Take Care of Your Pet")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.textPrimary)

            VStack(spacing: 16) {
                careTip(
                    icon: "leaf.fill",
                    color: AppColors.success,
                    title: "Feed daily",
                    subtitle: "Drag food onto your pet"
                )
                careTip(
                    icon: "drop.fill",
                    color: AppColors.xp,
                    title: "Water daily",
                    subtitle: "Drag water onto your pet"
                )
                careTip(
                    icon: "hand.draw.fill",
                    color: AppColors.accent,
                    title: "Pet daily",
                    subtitle: "Rub your pet to show love"
                )
            }

            VStack(spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.warning)
                    Text("Neglected pets get sad and eventually run away!")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)
                }

                HStack(spacing: 24) {
                    moodPreview(icon: "leaf.fill", label: "Happy", color: AppColors.petHappy, multiplier: "1.0x XP")
                    moodPreview(icon: "leaf", label: "Content", color: AppColors.petNeutral, multiplier: "0.85x")
                    moodPreview(icon: "leaf.arrow.triangle.circlepath", label: "Sad", color: AppColors.petSad, multiplier: "0.6x")
                }
                .padding(.top, 8)
            }

            Spacer()

            onboardingButton("Try It Now") {
                showCareTutorialIntro = false
            }
        }
        .padding(.horizontal, 32)
    }

    private func careTip(icon: String, color: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)
                Text(subtitle)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
            }
            Spacer()
        }
    }

    private func moodPreview(icon: String, label: String, color: Color, multiplier: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(color)
            Text(multiplier)
                .font(.system(size: 10, design: .rounded))
                .foregroundColor(AppColors.textTertiary)
        }
    }

    // MARK: - Step 13: Evolution & Growth

    private var evolutionScreen: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("Watch Them Grow")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.textPrimary)

            if let starterId = selectedStarterPetId ?? userData.ownedPets.first?.petDefinitionId,
               let pet = GameData.pet(byId: starterId) {
                // Evolution stages display
                HStack(spacing: 4) {
                    ForEach(Array(pet.stageImageNames.enumerated()), id: \.offset) { index, imageName in
                        VStack(spacing: 8) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(AppColors.surface)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(AppColors.accentSoft.opacity(0.5), lineWidth: 1)
                                    )

                                Image(imageName)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .padding(12)
                            }
                            .frame(height: 110)

                            Text(PetConfig.shared.stageNames[safe: index] ?? "")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(AppColors.textPrimary)

                            Text("Stage \(index + 1)")
                                .font(.system(size: 11, design: .rounded))
                                .foregroundColor(AppColors.textTertiary)
                        }
                        .frame(maxWidth: .infinity)

                        if index < pet.stageImageNames.count - 1 {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppColors.accentSoft)
                                .padding(.bottom, 30)
                        }
                    }
                }
            }

            VStack(spacing: 12) {
                infoBubble(
                    icon: "star.fill",
                    text: "Earn XP from running, sprinting, and caring for your pet"
                )
                infoBubble(
                    icon: "heart.fill",
                    text: "Happy pets earn XP faster. Keep them fed and loved!"
                )
            }

            Spacer()

            onboardingButton("Next") { step = 14 }
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Step 14: Ready

    private var readyScreen: some View {
        VStack(spacing: 24) {
            Spacer()

            if let starterId = selectedStarterPetId ?? userData.ownedPets.first?.petDefinitionId,
               let pet = GameData.pet(byId: starterId) {
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

            // Loop recap
            HStack(spacing: 0) {
                loopStep(icon: "figure.run", label: "Run")
                loopArrow
                loopStep(icon: "bolt.fill", label: "Sprint")
                loopArrow
                loopStep(icon: "pawprint.fill", label: "Catch")
                loopArrow
                loopStep(icon: "heart.fill", label: "Care")
                loopArrow
                loopStep(icon: "sparkles", label: "Grow")
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 8)
            .background(AppColors.surface)
            .cornerRadius(16)

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

    // MARK: - Reusable Components

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

    private func watchMockup<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28)
                .fill(AppColors.textPrimary)
                .frame(width: 160, height: 190)
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(Color.gray.opacity(0.4), lineWidth: 3)
                )

            RoundedRectangle(cornerRadius: 22)
                .fill(AppColors.background)
                .frame(width: 140, height: 170)

            content()
        }
    }

    private func stepBullet(number: Int, text: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppColors.accent)
                    .frame(width: 28, height: 28)
                Text("\(number)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            Text(text)
                .font(.system(size: 15, design: .rounded))
                .foregroundColor(AppColors.textPrimary)
            Spacer()
        }
    }

    private func infoBubble(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(AppColors.accent)
                .frame(width: 24)
            Text(text)
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(AppColors.textPrimary)
            Spacer()
        }
        .padding(14)
        .background(AppColors.surface)
        .cornerRadius(12)
    }

    private func timelineNode(icon: String, label: String, color: Color) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
            }
            Text(label)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func timelineLine() -> some View {
        Rectangle()
            .fill(AppColors.surfaceElevated)
            .frame(height: 2)
            .frame(maxWidth: 20)
            .offset(y: -10)
    }

    private func loopStep(icon: String, label: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(AppColors.accent)
            Text(label)
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var loopArrow: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 8, weight: .bold))
            .foregroundColor(AppColors.textTertiary)
    }

    private var currentStarterPetImageName: String {
        if let starterId = selectedStarterPetId,
           let pet = GameData.pet(byId: starterId),
           let first = pet.stageImageNames.first {
            return first
        }
        if let firstOwned = userData.ownedPets.first,
           let def = firstOwned.definition,
           let first = def.stageImageNames.first {
            return first
        }
        return "lumira_01"
    }
}
