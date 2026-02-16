// OnboardingFlow.swift
// Ippo MVP - First Launch Experience
// Adapted from GitHub version with MVP-specific messaging
//
// Flow: IppoWelcomeView -> IppoOnboardingCarousel -> SignIn -> AboutYou -> WatchPairingView -> PermissionFlowView -> IppoReadyView

import SwiftUI
import HealthKit
import UserNotifications
import AuthenticationServices

// MARK: - Onboarding Page Model

struct OnboardingPage: Identifiable {
    let id = UUID()
    let image: OnboardingImage
    let title: String
    let subtitle: String
    let accentColor: Color
    
    enum OnboardingImage {
        case systemName(String)
        case assetName(String)
        case custom(AnyView)
    }
}

// MARK: - Page Carousel Onboarding

struct IppoOnboardingCarousel: View {
    let pages: [OnboardingPage]
    var onComplete: () -> Void
    
    @State private var currentPage = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                        IppoOnboardingPageView(page: page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                VStack(spacing: AppSpacing.xl) {
                    // Page indicators
                    HStack(spacing: AppSpacing.sm) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            Capsule()
                                .fill(index == currentPage ? pages[currentPage].accentColor : AppColors.textTertiary.opacity(0.3))
                                .frame(width: index == currentPage ? 24 : 8, height: 8)
                                .animation(reduceMotion ? .none : .spring(response: 0.3), value: currentPage)
                        }
                    }
                    .accessibilityHidden(true)
                    
                    // Buttons
                    HStack(spacing: AppSpacing.lg) {
                        if currentPage < pages.count - 1 {
                            Button("Skip") {
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                                onComplete()
                            }
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.textSecondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .accessibilityLabel("Skip onboarding")
                        }
                        
                        Button(action: {
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                            
                            if currentPage < pages.count - 1 {
                                if reduceMotion {
                                    currentPage += 1
                                } else {
                                    withAnimation(.spring(response: 0.4)) {
                                        currentPage += 1
                                    }
                                }
                            } else {
                                onComplete()
                            }
                        }) {
                            Text(currentPage == pages.count - 1 ? "Get Started" : "Continue")
                                .font(AppTypography.headline)
                                .foregroundColor(AppColors.background)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(pages[currentPage].accentColor)
                                .cornerRadius(25)
                        }
                        .accessibilityLabel(currentPage == pages.count - 1 ? "Get Started" : "Continue to next page")
                    }
                    .padding(.horizontal, AppSpacing.xl)
                }
                .padding(.bottom, AppSpacing.xxxl)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Onboarding, page \(currentPage + 1) of \(pages.count)")
    }
}

// MARK: - Single Onboarding Page

struct IppoOnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: AppSpacing.xxl) {
            Spacer()
            
            Group {
                switch page.image {
                case .systemName(let name):
                    ZStack {
                        Circle()
                            .fill(page.accentColor.opacity(0.15))
                            .frame(width: 180, height: 180)
                        
                        Circle()
                            .fill(page.accentColor.opacity(0.3))
                            .frame(width: 140, height: 140)
                        
                        Image(systemName: name)
                            .font(.system(size: 70, weight: .medium))
                            .foregroundColor(page.accentColor)
                    }
                    .frame(height: 200)
                    
                case .assetName(let name):
                    Image(name)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                    
                case .custom(let view):
                    view
                        .frame(height: 200)
                }
            }
            .padding(.bottom, AppSpacing.xl)
            .accessibilityHidden(true)
            
            VStack(spacing: AppSpacing.lg) {
                Text(page.title)
                    .font(AppTypography.title1)
                    .foregroundColor(AppColors.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text(page.subtitle)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, AppSpacing.xxl)
            }
            
            Spacer()
            Spacer()
        }
        .padding()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(page.title). \(page.subtitle)")
    }
}

// MARK: - Permission Types

enum IppoPermissionType {
    case health
    case notifications
    
    var icon: String {
        switch self {
        case .health: return "heart.fill"
        case .notifications: return "bell.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .health: return AppColors.danger
        case .notifications: return AppColors.warning
        }
    }
    
    var title: String {
        switch self {
        case .health: return "Health Access"
        case .notifications: return "Notifications"
        }
    }
    
    var description: String {
        switch self {
        case .health: return "Track your heart rate during sprints to validate your effort and earn rewards."
        case .notifications: return "Get reminded to run, celebrate achievements, and keep your streak alive."
        }
    }
    
    var benefits: [String] {
        switch self {
        case .health:
            return [
                "Validate sprints with heart rate data",
                "Track cadence for sprint detection",
                "Sync Apple Watch workouts"
            ]
        case .notifications:
            return [
                "Daily run reminders",
                "Achievement celebrations",
                "Streak warnings before you lose them"
            ]
        }
    }
}

enum IppoPermissionStatus {
    case notDetermined
    case granted
    case denied
}

// MARK: - Permission Request View

struct IppoPermissionRequestView: View {
    let permission: IppoPermissionType
    let status: IppoPermissionStatus
    var onRequest: () -> Void
    var onSkip: (() -> Void)? = nil
    
    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()
            
            VStack(spacing: AppSpacing.xxl) {
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(permission.color.opacity(0.15))
                        .frame(width: 140, height: 140)
                    
                    Circle()
                        .fill(permission.color.opacity(0.3))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: permission.icon)
                        .font(.system(size: 44, weight: .medium))
                        .foregroundColor(permission.color)
                }
                .accessibilityHidden(true)
                
                VStack(spacing: AppSpacing.md) {
                    Text(permission.title)
                        .font(AppTypography.title1)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text(permission.description)
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppSpacing.xl)
                }
                
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    ForEach(permission.benefits, id: \.self) { benefit in
                        HStack(spacing: AppSpacing.md) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(permission.color)
                                .accessibilityHidden(true)
                            
                            Text(benefit)
                                .font(AppTypography.subheadline)
                                .foregroundColor(AppColors.textPrimary)
                            
                            Spacer()
                        }
                    }
                }
                .padding(AppSpacing.xl)
                .background(AppColors.surface)
                .cornerRadius(AppSpacing.radiusLg)
                .padding(.horizontal, AppSpacing.xl)
                
                Spacer()
                
                VStack(spacing: AppSpacing.md) {
                    switch status {
                    case .notDetermined:
                        Button(action: {
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                            onRequest()
                        }) {
                            Text("Allow \(permission.title)")
                                .font(AppTypography.headline)
                                .foregroundColor(AppColors.background)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(permission.color)
                                .cornerRadius(25)
                        }
                        
                        if let onSkip = onSkip {
                            Button("Maybe Later") {
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                                onSkip()
                            }
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.textSecondary)
                        }
                        
                    case .granted:
                        HStack(spacing: AppSpacing.sm) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Permission Granted")
                                .font(AppTypography.headline)
                        }
                        .foregroundColor(AppColors.success)
                        .frame(height: 50)
                        
                    case .denied:
                        VStack(spacing: AppSpacing.sm) {
                            Text("Permission Denied")
                                .font(AppTypography.body)
                                .foregroundColor(AppColors.danger)
                            
                            Button("Open Settings") {
                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(url)
                                }
                            }
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.brandPrimary)
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.xl)
                .padding(.bottom, AppSpacing.xxxl)
            }
        }
    }
}

// MARK: - Multi-Permission Flow

struct IppoPermissionFlowView: View {
    let permissions: [IppoPermissionType]
    @State private var permissionStatuses: [IppoPermissionType: IppoPermissionStatus]
    @State private var currentIndex = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var onComplete: () -> Void
    
    init(permissions: [IppoPermissionType], onComplete: @escaping () -> Void) {
        self.permissions = permissions
        self.onComplete = onComplete
        
        var statuses: [IppoPermissionType: IppoPermissionStatus] = [:]
        for permission in permissions {
            statuses[permission] = .notDetermined
        }
        self._permissionStatuses = State(initialValue: statuses)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(AppColors.surface)
                    
                    Rectangle()
                        .fill(permissions[currentIndex].color)
                        .frame(width: geo.size.width * (Double(currentIndex + 1) / Double(permissions.count)))
                        .animation(reduceMotion ? .none : .spring(response: 0.4), value: currentIndex)
                }
            }
            .frame(height: 4)
            .accessibilityHidden(true)
            
            IppoPermissionRequestView(
                permission: permissions[currentIndex],
                status: permissionStatuses[permissions[currentIndex]] ?? .notDetermined,
                onRequest: {
                    requestPermission(permissions[currentIndex])
                },
                onSkip: {
                    moveToNext()
                }
            )
        }
    }
    
    private func requestPermission(_ permission: IppoPermissionType) {
        switch permission {
        case .health:
            let healthStore = HKHealthStore()
            let readTypes: Set<HKObjectType> = [
                HKObjectType.quantityType(forIdentifier: .heartRate)!,
                HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
                HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
                HKObjectType.workoutType()
            ]
            healthStore.requestAuthorization(toShare: [], read: readTypes) { success, error in
                DispatchQueue.main.async {
                    if success {
                        permissionStatuses[permission] = .granted
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                    } else {
                        permissionStatuses[permission] = .denied
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        moveToNext()
                    }
                }
            }
            
        case .notifications:
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
                DispatchQueue.main.async {
                    permissionStatuses[permission] = granted ? .granted : .denied
                    if granted {
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        moveToNext()
                    }
                }
            }
        }
    }
    
    private func moveToNext() {
        if currentIndex < permissions.count - 1 {
            if reduceMotion {
                currentIndex += 1
            } else {
                withAnimation(.spring(response: 0.4)) {
                    currentIndex += 1
                }
            }
        } else {
            onComplete()
        }
    }
}

// MARK: - Watch Pairing View

struct IppoWatchPairingView: View {
    @State private var isPairing = false
    @State private var isPaired = false
    @State private var showError = false
    @State private var pulseScale: CGFloat = 1.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var onComplete: () -> Void
    var onSkip: () -> Void
    
    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()
            
            VStack(spacing: AppSpacing.xxl) {
                Spacer()
                
                ZStack {
                    if isPairing && !reduceMotion {
                        Circle()
                            .stroke(AppColors.brandPrimary.opacity(0.3), lineWidth: 2)
                            .frame(width: 180, height: 180)
                            .scaleEffect(pulseScale)
                            .opacity(2.0 - pulseScale)
                    }
                    
                    Circle()
                        .fill(isPaired ? AppColors.success.opacity(0.15) : AppColors.surface)
                        .frame(width: 140, height: 140)
                    
                    if isPaired {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60, weight: .medium))
                            .foregroundColor(AppColors.success)
                    } else {
                        Image(systemName: "applewatch")
                            .font(.system(size: 70, weight: .light))
                            .foregroundColor(AppColors.textTertiary)
                    }
                }
                .frame(height: 200)
                .accessibilityHidden(true)
                
                VStack(spacing: AppSpacing.md) {
                    Text(isPaired ? "Watch Connected!" : "Connect Your Apple Watch")
                        .font(AppTypography.title1)
                        .foregroundColor(AppColors.textPrimary)
                    
                    if isPairing {
                        HStack(spacing: AppSpacing.sm) {
                            ProgressView()
                                .tint(AppColors.brandPrimary)
                            Text("Searching for watch...")
                                .font(AppTypography.body)
                        }
                        .foregroundColor(AppColors.textSecondary)
                    } else if isPaired {
                        Text("Apple Watch detected! The Ippo Watch app will install automatically. Open it on your Watch to start tracking sprints.")
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, AppSpacing.xl)
                    } else {
                        Text("Track your heart rate and cadence during sprints to validate your effort and earn RP Boxes.")
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, AppSpacing.xl)
                    }
                }
                
                if !isPaired && !isPairing {
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        IppoBenefitRow(icon: "heart.fill", color: AppColors.danger, text: "Real-time heart rate monitoring")
                        IppoBenefitRow(icon: "bolt.heart.fill", color: AppColors.brandPrimary, text: "Sprint validation with HR + cadence")
                        IppoBenefitRow(icon: "waveform.path.ecg", color: AppColors.success, text: "Accurate workout data")
                        IppoBenefitRow(icon: "applewatch.radiowaves.left.and.right", color: AppColors.brandSecondary, text: "Haptic sprint signals")
                    }
                    .padding(AppSpacing.xl)
                    .background(AppColors.surface)
                    .cornerRadius(AppSpacing.radiusLg)
                    .padding(.horizontal, AppSpacing.xl)
                }
                
                if showError {
                    Text("No paired Apple Watch detected. Make sure your Watch is paired to this iPhone in the Watch app. You can skip this step and pair later.")
                        .font(AppTypography.caption1)
                        .foregroundColor(AppColors.danger)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppSpacing.xl)
                }
                
                Spacer()
                
                VStack(spacing: AppSpacing.md) {
                    if isPaired {
                        Button(action: {
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                            onComplete()
                        }) {
                            Text("Continue")
                                .font(AppTypography.headline)
                                .foregroundColor(AppColors.background)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(AppColors.success)
                                .cornerRadius(25)
                        }
                    } else if isPairing {
                        Button("Cancel") {
                            isPairing = false
                        }
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)
                    } else {
                        Button(action: startPairing) {
                            Text("Connect Watch")
                                .font(AppTypography.headline)
                                .foregroundColor(AppColors.background)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(AppColors.brandPrimary)
                                .cornerRadius(25)
                        }
                        
                        Button("Skip for Now") {
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                            onSkip()
                        }
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)
                    }
                }
                .padding(.horizontal, AppSpacing.xl)
                .padding(.bottom, AppSpacing.xxxl)
            }
        }
        .onChange(of: isPairing) { newValue in
            if newValue && !reduceMotion {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: false)) {
                    pulseScale = 1.5
                }
            } else {
                pulseScale = 1.0
            }
        }
    }
    
    private func startPairing() {
        isPairing = true
        showError = false
        
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        let connectivity = WatchConnectivityService.shared
        
        // Check isPaired (Watch is paired to this iPhone) -- not isReachable (Watch app is in foreground)
        if connectivity.isPaired {
            isPairing = false
            isPaired = true
            let successGenerator = UINotificationFeedbackGenerator()
            successGenerator.notificationOccurred(.success)
        } else {
            // Give WCSession a moment to update its state, then check again
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                isPairing = false
                if connectivity.isPaired {
                    isPaired = true
                    let successGenerator = UINotificationFeedbackGenerator()
                    successGenerator.notificationOccurred(.success)
                } else {
                    showError = true
                }
            }
        }
    }
}

private struct IppoBenefitRow: View {
    let icon: String
    let color: Color
    let text: String
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
                .accessibilityHidden(true)
            
            Text(text)
                .font(AppTypography.subheadline)
                .foregroundColor(AppColors.textPrimary)
            
            Spacer()
        }
    }
}

// MARK: - Welcome View

struct IppoWelcomeView: View {
    var onStart: () -> Void
    
    @State private var showContent = false
    @State private var logoScale: CGFloat = 0.5
    @State private var logoRotation: Double = -20
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [AppColors.background, AppColors.surface],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: AppSpacing.xxl) {
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [AppColors.brandPrimary.opacity(0.3), Color.clear],
                                center: .center,
                                startRadius: 50,
                                endRadius: 120
                            )
                        )
                        .frame(width: 240, height: 240)
                        .scaleEffect(reduceMotion ? 1.0 : logoScale)
                    
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [AppColors.brandPrimary, AppColors.brandSecondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 140, height: 140)
                        .scaleEffect(reduceMotion ? 1.0 : logoScale)
                        .shadow(color: AppColors.brandPrimary.opacity(0.5), radius: 20)
                    
                    Image(systemName: "figure.run")
                        .font(.system(size: 60, weight: .semibold))
                        .foregroundColor(.white)
                        .scaleEffect(reduceMotion ? 1.0 : logoScale)
                        .rotationEffect(.degrees(reduceMotion ? 0 : logoRotation))
                }
                .accessibilityHidden(true)
                
                if showContent || reduceMotion {
                    VStack(spacing: AppSpacing.lg) {
                        Text("Welcome to Ippo")
                            .font(AppTypography.largeTitle)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text("Sprint. Earn. Rise. Run with random sprint encounters and climb the ranks with your friends.")
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .padding(.horizontal, AppSpacing.xxl)
                    }
                    .transition(reduceMotion ? .identity : .opacity.combined(with: .move(edge: .bottom)))
                }
                
                Spacer()
                
                if showContent || reduceMotion {
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        onStart()
                    }) {
                        Text("Let's Go")
                            .font(AppTypography.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                LinearGradient(
                                    colors: [AppColors.brandPrimary, AppColors.brandSecondary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(25)
                            .shadow(color: AppColors.brandPrimary.opacity(0.4), radius: 10, y: 5)
                    }
                    .padding(.horizontal, AppSpacing.xl)
                    .padding(.bottom, AppSpacing.xxxl)
                    .transition(reduceMotion ? .identity : .opacity.combined(with: .move(edge: .bottom)))
                }
            }
        }
        .onAppear {
            guard !reduceMotion else {
                logoScale = 1.0
                logoRotation = 0
                showContent = true
                return
            }
            
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                logoScale = 1.0
                logoRotation = 0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.easeOut(duration: 0.5)) {
                    showContent = true
                }
            }
        }
    }
}

// MARK: - Complete Onboarding Flow

struct IppoCompleteOnboardingFlow: View {
    @State private var currentStep: IppoOnboardingStep = .welcome
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var onComplete: () -> Void
    
    enum IppoOnboardingStep: CaseIterable {
        case welcome
        case features
        case signIn
        case aboutYou
        case watchPairing
        case permissions
        case ready
    }
    
    // Scoped-down MVP feature pages
    private let featurePages: [OnboardingPage] = [
        OnboardingPage(
            image: .systemName("bolt.heart.fill"),
            title: "Sprint Encounters",
            subtitle: "Random sprint challenges appear during your runs. Push hard for 30-45 seconds to prove your effort!",
            accentColor: AppColors.brandPrimary
        ),
        OnboardingPage(
            image: .systemName("gift.fill"),
            title: "Earn RP Boxes",
            subtitle: "Complete sprints to earn RP Boxes. Open them to gain 1-25 Reputation Points. Rare drops feel amazing!",
            accentColor: AppColors.brandSecondary
        ),
        OnboardingPage(
            image: .systemName("trophy.fill"),
            title: "Climb the Ranks",
            subtitle: "Earn Reputation Points from every sprint. Rise through Bronze, Silver, Gold, Platinum, and Diamond ranks.",
            accentColor: AppColors.gold
        ),
        OnboardingPage(
            image: .systemName("person.2.fill"),
            title: "Compete with Friends",
            subtitle: "Add friends, create groups, and compete on weekly leaderboards. See who earns the most RP each week!",
            accentColor: AppColors.warning
        )
    ]
    
    var body: some View {
        ZStack {
            switch currentStep {
            case .welcome:
                IppoWelcomeView {
                    transitionTo(.features)
                }
                
            case .features:
                IppoOnboardingCarousel(pages: featurePages) {
                    transitionTo(.signIn)
                }
                
            case .signIn:
                IppoOnboardingSignInView {
                    transitionTo(.aboutYou)
                }
                
            case .aboutYou:
                IppoAboutYouView {
                    transitionTo(.watchPairing)
                } onSkip: {
                    transitionTo(.watchPairing)
                }
                
            case .watchPairing:
                IppoWatchPairingView {
                    transitionTo(.permissions)
                } onSkip: {
                    transitionTo(.permissions)
                }
                
            case .permissions:
                IppoPermissionFlowView(permissions: [.health, .notifications]) {
                    transitionTo(.ready)
                }
                
            case .ready:
                IppoReadyView {
                    onComplete()
                }
            }
        }
    }
    
    private func transitionTo(_ step: IppoOnboardingStep) {
        if reduceMotion {
            currentStep = step
        } else {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = step
            }
        }
    }
}

// MARK: - Ready View

struct IppoReadyView: View {
    var onStart: () -> Void
    
    @State private var showContent = false
    @State private var showConfetti = false
    @State private var checkmarkScale: CGFloat = 0.5
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()
            
            VStack(spacing: AppSpacing.xxl) {
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(AppColors.success.opacity(0.15))
                        .frame(width: 160, height: 160)
                    
                    Circle()
                        .fill(AppColors.success.opacity(0.3))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(AppColors.success)
                        .scaleEffect(reduceMotion ? 1.0 : checkmarkScale)
                }
                .accessibilityHidden(true)
                
                if showContent || reduceMotion {
                    VStack(spacing: AppSpacing.lg) {
                        Text("You're All Set!")
                            .font(AppTypography.largeTitle)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text("Time to start running. Sprint encounters will find you -- go for a run, push hard when prompted, and earn RP Boxes!")
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .padding(.horizontal, AppSpacing.xxl)
                    }
                    .transition(reduceMotion ? .identity : .opacity.combined(with: .move(edge: .bottom)))
                }
                
                Spacer()
                
                if showContent || reduceMotion {
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        onStart()
                    }) {
                        HStack(spacing: AppSpacing.sm) {
                            Image(systemName: "figure.run")
                            Text("Start Running")
                        }
                        .font(AppTypography.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(AppColors.success)
                        .cornerRadius(25)
                        .shadow(color: AppColors.success.opacity(0.4), radius: 10, y: 5)
                    }
                    .padding(.horizontal, AppSpacing.xl)
                    .padding(.bottom, AppSpacing.xxxl)
                    .transition(reduceMotion ? .identity : .opacity)
                }
            }
            
            if showConfetti && !reduceMotion {
                OnboardingConfettiOverlay()
            }
        }
        .onAppear {
            guard !reduceMotion else {
                checkmarkScale = 1.0
                showContent = true
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                return
            }
            
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                checkmarkScale = 1.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showConfetti = true
                
                withAnimation(.easeOut(duration: 0.5)) {
                    showContent = true
                }
                
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            }
        }
    }
}

// MARK: - Confetti Overlay (Onboarding-specific)

private struct OnboardingConfettiOverlay: View {
    @State private var particles: [OnboardingConfettiParticle] = []
    
    private let confettiColors: [Color] = [
        AppColors.brandPrimary,
        AppColors.brandSecondary,
        AppColors.success,
        AppColors.gold,
        AppColors.gems,
        AppColors.warning,
        AppColors.danger
    ]
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { particle in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(particle.color)
                        .frame(width: particle.width, height: particle.height)
                        .rotationEffect(.degrees(particle.rotation))
                        .position(particle.position)
                        .opacity(particle.opacity)
                }
            }
            .onAppear {
                createParticles(in: geo.size)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
    
    private func createParticles(in size: CGSize) {
        for i in 0..<80 {
            let particle = OnboardingConfettiParticle(
                id: i,
                color: confettiColors.randomElement()!,
                width: CGFloat.random(in: 8...14),
                height: CGFloat.random(in: 4...8),
                rotation: Double.random(in: 0...360),
                position: CGPoint(x: CGFloat.random(in: 0...size.width), y: -20),
                opacity: 1.0
            )
            particles.append(particle)
            
            let delay = Double(i) * 0.012
            let endX = particle.position.x + CGFloat.random(in: -80...80)
            let endY = size.height + 50
            let endRotation = particle.rotation + Double.random(in: 360...720)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeOut(duration: Double.random(in: 2.0...3.2))) {
                    if let index = particles.firstIndex(where: { $0.id == i }) {
                        particles[index].position = CGPoint(x: endX, y: endY)
                        particles[index].rotation = endRotation
                        particles[index].opacity = 0
                    }
                }
            }
        }
    }
}

private struct OnboardingConfettiParticle: Identifiable {
    let id: Int
    let color: Color
    let width: CGFloat
    let height: CGFloat
    var rotation: Double
    var position: CGPoint
    var opacity: Double
}

// MARK: - Onboarding Sign-In View

struct IppoOnboardingSignInView: View {
    @StateObject private var authService = AuthService.shared
    var onComplete: () -> Void
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [AppColors.background, AppColors.surface],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: AppSpacing.xxl) {
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(AppColors.brandPrimary.opacity(0.15))
                        .frame(width: 140, height: 140)
                    Circle()
                        .fill(AppColors.brandPrimary.opacity(0.3))
                        .frame(width: 100, height: 100)
                    Image(systemName: "person.badge.key.fill")
                        .font(.system(size: 44, weight: .medium))
                        .foregroundColor(AppColors.brandPrimary)
                }
                
                VStack(spacing: AppSpacing.md) {
                    Text("Create Your Account")
                        .font(AppTypography.title1)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("Sign in to save your progress, add friends, and compete on leaderboards.")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppSpacing.xl)
                }
                
                Spacer()
                
                VStack(spacing: AppSpacing.md) {
                    SignInWithAppleButton(.signIn) { request in
                        let appleRequest = authService.startSignInWithApple()
                        request.requestedScopes = appleRequest.requestedScopes
                        request.nonce = appleRequest.nonce
                    } onCompletion: { result in
                        Task {
                            await authService.handleSignInWithApple(result)
                        }
                    }
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 50)
                    .cornerRadius(25)
                    
                    if let error = authService.errorMessage {
                        Text(error)
                            .font(AppTypography.caption1)
                            .foregroundColor(AppColors.danger)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, AppSpacing.lg)
                    }
                    
                    if authService.isLoading {
                        ProgressView()
                            .tint(AppColors.brandPrimary)
                    }
                }
                .padding(.horizontal, AppSpacing.xl)
                
                Text("By signing in, you agree to our Terms of Service and Privacy Policy.")
                    .font(AppTypography.caption2)
                    .foregroundColor(AppColors.textTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.xxl)
                    .padding(.bottom, AppSpacing.xxxl)
            }
        }
        .onChange(of: authService.isAuthenticated) { isAuthenticated in
            if isAuthenticated {
                onComplete()
            }
        }
        .onAppear {
            // If already authenticated (e.g. Firebase session persisted), skip sign-in
            if authService.isAuthenticated {
                onComplete()
            }
        }
    }
}

// MARK: - About You View (Biometrics Collection)

struct IppoAboutYouView: View {
    var onComplete: () -> Void
    var onSkip: () -> Void
    
    @State private var username: String = ""
    @State private var selectedBirthYear: Int = 2000
    @State private var selectedSex: String = "male"
    @State private var usernameError: String?
    @State private var isCheckingUsername = false
    
    private let currentYear = Calendar.current.component(.year, from: Date())
    private var birthYearRange: [Int] {
        Array((currentYear - 80)...(currentYear - 10)).reversed()
    }
    
    private var isUsernameValid: Bool {
        let trimmed = username.trimmingCharacters(in: .whitespaces)
        guard trimmed.count >= 3, trimmed.count <= 20 else { return false }
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_"))
        return trimmed.unicodeScalars.allSatisfy { allowed.contains($0) }
    }
    
    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(AppColors.brandPrimary.opacity(0.15))
                            .frame(width: 100, height: 100)
                        Circle()
                            .fill(AppColors.brandPrimary.opacity(0.3))
                            .frame(width: 70, height: 70)
                        Image(systemName: "person.crop.circle.badge.checkmark")
                            .font(.system(size: 34, weight: .medium))
                            .foregroundColor(AppColors.brandPrimary)
                    }
                    .padding(.top, AppSpacing.xxl)
                    
                    VStack(spacing: AppSpacing.sm) {
                        Text("Set Up Your Profile")
                            .font(AppTypography.title1)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text("Choose a username so friends can find you, and set your info for accurate sprint tracking.")
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, AppSpacing.xl)
                    }
                    
                    // Username (REQUIRED)
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text("Username (required)")
                            .font(AppTypography.subheadline)
                            .foregroundColor(AppColors.textSecondary)
                        
                        TextField("e.g. crucerunner", text: $username)
                            .textFieldStyle(.roundedBorder)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .onChange(of: username) { _ in
                                usernameError = nil
                            }
                        
                        if let error = usernameError {
                            Text(error)
                                .font(AppTypography.caption2)
                                .foregroundColor(AppColors.danger)
                        } else if !username.isEmpty && !isUsernameValid {
                            Text("3-20 characters, letters, numbers, and underscores only")
                                .font(AppTypography.caption2)
                                .foregroundColor(AppColors.warning)
                        } else if isUsernameValid {
                            Text("Looks good!")
                                .font(AppTypography.caption2)
                                .foregroundColor(AppColors.success)
                        }
                    }
                    .padding(.horizontal, AppSpacing.xl)
                    
                    // Birth Year + Estimated Max HR
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text("Birth Year")
                            .font(AppTypography.subheadline)
                            .foregroundColor(AppColors.textSecondary)
                        
                        Picker("Birth Year", selection: $selectedBirthYear) {
                            ForEach(birthYearRange, id: \.self) { year in
                                Text(String(year)).tag(year)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 100)
                        .clipped()
                        
                        let age = currentYear - selectedBirthYear
                        let maxHR = Int(208.0 - (0.7 * Double(age)))
                        VStack(spacing: 2) {
                            Text("Estimated Max Heart Rate")
                                .font(AppTypography.caption1)
                                .foregroundColor(AppColors.textTertiary)
                            Text("\(maxHR) BPM")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundColor(AppColors.brandPrimary)
                            Text("Based on your age (Tanaka formula)")
                                .font(AppTypography.caption2)
                                .foregroundColor(AppColors.textTertiary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, AppSpacing.xl)
                    
                    // Biological Sex
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text("Biological Sex")
                            .font(AppTypography.subheadline)
                            .foregroundColor(AppColors.textSecondary)
                        
                        Picker("Biological Sex", selection: $selectedSex) {
                            Text("Male").tag("male")
                            Text("Female").tag("female")
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(.horizontal, AppSpacing.xl)
                    
                    // Continue button
                    VStack(spacing: AppSpacing.md) {
                        Button(action: {
                            guard isUsernameValid else {
                                usernameError = "Please enter a valid username (3-20 characters)"
                                return
                            }
                            
                            isCheckingUsername = true
                            Task {
                                let result = await FriendService.shared.checkUsernameAvailability(
                                    username.trimmingCharacters(in: .whitespaces).lowercased()
                                )
                                isCheckingUsername = false
                                switch result {
                                case .available:
                                    let userData = UserData.shared
                                    userData.profile.username = username.trimmingCharacters(in: .whitespaces).lowercased()
                                    userData.profile.displayName = username.trimmingCharacters(in: .whitespaces)
                                    userData.profile.birthYear = selectedBirthYear
                                    userData.profile.biologicalSex = selectedSex
                                    userData.save()
                                    
                                    // Push maxHR to Watch immediately so sprint validation is accurate
                                    WatchConnectivityService.shared.pushProfileToWatch()
                                    
                                    let generator = UIImpactFeedbackGenerator(style: .medium)
                                    generator.impactOccurred()
                                    onComplete()
                                case .taken:
                                    usernameError = "Username is already taken"
                                case .error(let message):
                                    usernameError = message
                                }
                            }
                        }) {
                            if isCheckingUsername {
                                ProgressView()
                                    .tint(AppColors.background)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(AppColors.textTertiary)
                                    .cornerRadius(25)
                            } else {
                                Text("Continue")
                                    .font(AppTypography.headline)
                                    .foregroundColor(AppColors.background)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(isUsernameValid ? AppColors.brandPrimary : AppColors.textTertiary)
                                    .cornerRadius(25)
                            }
                        }
                        .disabled(!isUsernameValid || isCheckingUsername)
                    }
                    .padding(.horizontal, AppSpacing.xl)
                    .padding(.bottom, AppSpacing.xxxl)
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Complete Flow") {
    IppoCompleteOnboardingFlow {
        print("Onboarding complete")
    }
}

#Preview("Welcome") {
    IppoWelcomeView {
        print("Start")
    }
}

#Preview("Ready") {
    IppoReadyView {
        print("Start Running")
    }
}
