import SwiftUI

struct HomeView: View {
    @EnvironmentObject var userData: UserData
    @State private var showSettings = false
    @State private var showFeedConfirm = false
    @State private var showWaterConfirm = false
    @State private var petAnimating = false
    @State private var showHearts = false
    @State private var showRunSummary = false
    @State private var showEvolution = false
    @State private var happyBounce = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        topBar
                        if let pet = userData.equippedPet, let def = pet.definition {
                            petSection(pet: pet, def: def)
                            xpSection(pet: pet)
                            careButtons(pet: pet)
                            boostBanner
                        } else {
                            noPetView
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
            }
            .sheet(isPresented: $showSettings) {
                ProfileView()
                    .environmentObject(userData)
            }
            .fullScreenCover(isPresented: $showRunSummary) {
                if let run = userData.pendingRunSummary {
                    PostRunSummaryView(run: run) {
                        userData.pendingRunSummary = nil
                        showRunSummary = false
                    }
                    .environmentObject(userData)
                }
            }
            .fullScreenCover(isPresented: $showEvolution) {
                if let evo = userData.pendingEvolution {
                    CelebrationModal.evolution(
                        isPresented: $showEvolution,
                        petName: evo.petName,
                        newStage: evo.newStage,
                        stageName: evo.stageName
                    ) {
                        userData.pendingEvolution = nil
                        showEvolution = false
                    }
                }
            }
            .onAppear {
                if userData.pendingRunSummary != nil {
                    showRunSummary = true
                }
                NotificationSystem.shared.rescheduleNotifications()
                userData.inventory.cleanExpiredBoosts()
            }
            .onChange(of: userData.pendingEvolution != nil) { hasEvolution in
                if hasEvolution {
                    showEvolution = true
                }
            }
        }
    }

    // MARK: - Top Bar
    private var topBar: some View {
        HStack {
            HStack(spacing: 4) {
                Image(systemName: "circle.fill")
                    .font(.system(size: 10))
                    .foregroundColor(AppColors.coins)
                Text("\(userData.profile.coins)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)
            }

            Spacer()

            if userData.profile.currentStreak > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.accent)
                    Text("\(userData.profile.currentStreak)")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.textPrimary)
                }
            }

            Spacer()

            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 18))
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Pet Section
    private func petSection(pet: OwnedPet, def: GamePetDefinition) -> some View {
        VStack(spacing: 8) {
            Text(def.name)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.textPrimary)

            HStack(spacing: 8) {
                Text("Stage \(pet.evolutionStage) · \(pet.stageName)")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
                MoodIndicator(mood: pet.mood)
            }

            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(AppColors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(
                                userData.inventory.activeXPBoost != nil
                                    ? AppColors.xp.opacity(0.5)
                                    : Color.clear,
                                lineWidth: 3
                            )
                    )

                PetImageView(imageName: pet.currentImageName)
                    .padding(32)
                    .offset(y: petAnimating ? -6 : 0)
                    .scaleEffect(happyBounce ? 1.12 : 1.0)
                    .animation(
                        .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                        value: petAnimating
                    )
                    .animation(
                        happyBounce
                            ? .spring(response: 0.3, dampingFraction: 0.4)
                            : .spring(response: 0.3, dampingFraction: 0.7),
                        value: happyBounce
                    )

                if showHearts {
                    heartsOverlay
                }
            }
            .frame(height: UIScreen.main.bounds.height * 0.38)
            .onAppear { petAnimating = true }
        }
    }

    // MARK: - XP Section
    private func xpSection(pet: OwnedPet) -> some View {
        XPProgressBar(
            progress: pet.xpProgress,
            currentXP: pet.experience - pet.xpForCurrentStage,
            targetXP: pet.xpForNextStage - pet.xpForCurrentStage,
            label: pet.isMaxEvolution ? "Max Level" : "to \(PetConfig.shared.stageName(for: pet.evolutionStage + 1))"
        )
    }

    // MARK: - Care Buttons
    private func careButtons(pet: OwnedPet) -> some View {
        HStack(spacing: 12) {
            careButton(
                icon: "leaf.fill",
                label: "Feed",
                count: userData.inventory.food,
                enabled: pet.canBeFed && userData.inventory.food > 0
            ) {
                if userData.feedPet() {
                    triggerHappyAnimation()
                }
            }

            careButton(
                icon: "drop.fill",
                label: "Water",
                count: userData.inventory.water,
                enabled: pet.canBeWatered && userData.inventory.water > 0
            ) {
                if userData.waterPet() {
                    triggerHappyAnimation()
                }
            }

            careButton(
                icon: "hand.raised.fill",
                label: "Pet",
                count: nil,
                enabled: pet.canBePetted
            ) {
                if userData.petPet() {
                    triggerHappyAnimation()
                }
            }
        }
    }

    private func careButton(icon: String, label: String, count: Int?, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(enabled ? AppColors.accent : AppColors.textTertiary)
                Text(label)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(enabled ? AppColors.textPrimary : AppColors.textTertiary)
                if let count {
                    Text("x\(count)")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(AppColors.surface)
            .cornerRadius(12)
        }
        .disabled(!enabled)
    }

    // MARK: - Boost Banner
    @ViewBuilder
    private var boostBanner: some View {
        if let boost = userData.inventory.activeXPBoost {
            HStack {
                Image(systemName: "arrow.up.circle.fill")
                    .foregroundColor(AppColors.xp)
                Text("XP Boost Active")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                Text(formatTimeRemaining(boost.remainingSeconds))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
            }
            .padding(12)
            .background(AppColors.xp.opacity(0.1))
            .cornerRadius(12)
        }

        if userData.inventory.isHibernating {
            HStack {
                Image(systemName: "moon.zzz.fill")
                    .foregroundColor(AppColors.accentSoft)
                Text("Hibernation Active")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                Text("Pets protected")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
            }
            .padding(12)
            .background(AppColors.accentSoft.opacity(0.15))
            .cornerRadius(12)
        }
    }

    // MARK: - No Pet View
    private var noPetView: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 60)
            Image(systemName: "pawprint.fill")
                .font(.system(size: 48))
                .foregroundColor(AppColors.textTertiary)
            Text("No pet equipped")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
            Text("Go to your collection and equip a pet!")
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(AppColors.textTertiary)
        }
    }

    // MARK: - Hearts Overlay
    private var heartsOverlay: some View {
        ForEach(0..<6, id: \.self) { i in
            Image(systemName: "heart.fill")
                .font(.system(size: CGFloat.random(in: 14...24)))
                .foregroundColor(i % 2 == 0 ? AppColors.petHappy : AppColors.accent.opacity(0.7))
                .offset(
                    x: CGFloat([-50, -20, 10, 35, -35, 25][i]),
                    y: showHearts ? CGFloat.random(in: -100 ... -60) : 0
                )
                .opacity(showHearts ? 0 : 1)
                .scaleEffect(showHearts ? 1.3 : 0.5)
                .animation(
                    .easeOut(duration: 1.2).delay(Double(i) * 0.08),
                    value: showHearts
                )
        }
    }

    // MARK: - Helpers
    private func triggerHappyAnimation() {
        showHearts = true
        happyBounce = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            happyBounce = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            showHearts = false
        }
        userData.recordInteraction()
    }

    private func formatTimeRemaining(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}
