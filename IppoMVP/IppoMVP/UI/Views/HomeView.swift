import SwiftUI

struct PetFrameKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

private struct RootFrameKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

struct HomeView: View {
    @EnvironmentObject var userData: UserData
    @EnvironmentObject var authService: AuthService
    @State private var showSettings = false
    @State private var showHearts = false
    @State private var showRunSummary = false
    @State private var showEvolution = false
    @State private var bounceOffset: CGFloat = 0
    @State private var showAllRuns = false

    @State private var petFrame: CGRect = .zero
    @State private var rootFrame: CGRect = .zero
    @State private var foodDragLocation: CGPoint = .zero
    @State private var waterDragLocation: CGPoint = .zero
    @State private var isDraggingFood = false
    @State private var isDraggingWater = false
    @State private var isHoveringPet = false
    @State private var floatingXP: String?
    @State private var screenSize: CGSize = .zero

    @State private var petStrokeDistance: CGFloat = 0
    @State private var lastStrokeLocation: CGPoint?
    @State private var heartAnimationPhase = false
    @State private var isBouncing = false

    @AppStorage("hasSeenCareHint") private var hasSeenCareHint = false

    var body: some View {
        NavigationStack {
            GeometryReader { rootGeo in
                ZStack {
                    AppColors.background.ignoresSafeArea()

                    ScrollView {
                        VStack(spacing: 0) {
                            if let pet = userData.equippedPet, let def = pet.definition {
                                petDisplay(pet: pet, def: def)
                                xpBar(pet: pet)
                                    .padding(.horizontal, 20)
                                    .padding(.top, 8)
                                careTray(pet: pet)
                                    .padding(.horizontal, 20)
                                    .padding(.top, 14)
                                boostBanners
                                    .padding(.horizontal, 20)
                                    .padding(.top, 10)
                            } else {
                                noPetView
                            }

                            statsBar
                                .padding(.horizontal, 20)
                                .padding(.top, 16)

                            runHistorySection
                                .padding(.horizontal, 20)
                                .padding(.top, 14)
                                .padding(.bottom, 24)
                        }
                    }
                    .onPreferenceChange(PetFrameKey.self) { frame in
                        petFrame = frame
                    }

                    if isDraggingFood {
                        dragGhostIcon("leaf.fill", globalLocation: foodDragLocation)
                    }
                    if isDraggingWater {
                        dragGhostIcon("drop.fill", globalLocation: waterDragLocation)
                    }

                    if let xp = floatingXP {
                        floatingXPLabel(xp)
                    }

                    if !hasSeenCareHint && userData.equippedPet != nil {
                        careHintOverlay
                    }
                }
                .background(
                    GeometryReader { geo in
                        Color.clear.preference(key: RootFrameKey.self, value: geo.frame(in: .global))
                    }
                )
                .onPreferenceChange(RootFrameKey.self) { rootFrame = $0 }
                .onAppear { screenSize = rootGeo.size }
                .onChange(of: rootGeo.size) { _, newSize in screenSize = newSize }
            }
            .sheet(isPresented: $showSettings) {
                ProfileView()
                    .environmentObject(userData)
                    .environmentObject(authService)
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
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 17))
                            .foregroundColor(AppColors.textSecondary)
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
            .onChange(of: userData.pendingEvolution != nil) { _, hasEvolution in
                if hasEvolution {
                    showEvolution = true
                }
            }
        }
    }

    // MARK: - Pet Display

    private func petDisplay(pet: OwnedPet, def: GamePetDefinition) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Text(def.name)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)

                HStack {
                    Spacer()
                    MoodIndicator(mood: pet.mood)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)

            HStack(spacing: 6) {
                Text("Stage \(pet.evolutionStage) · \(pet.stageName)")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)

                if !pet.canEarnPetXP {
                    Text("· Petted today")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(AppColors.textTertiary)
                }
            }

            ZStack {
                PetImageView(imageName: pet.currentImageName, isDropTarget: isHoveringPet)
                    .padding(.horizontal, 20)
                    .offset(y: bounceOffset)

                if showHearts {
                    heartsOverlay
                }
            }
            .frame(height: screenSize.height * 0.44)
            .background(
                GeometryReader { geo in
                    Color.clear
                        .preference(key: PetFrameKey.self, value: geo.frame(in: .global))
                }
            )
            .highPriorityGesture(
                DragGesture(minimumDistance: 10, coordinateSpace: .local)
                    .onChanged { value in
                        let current = value.location
                        if let last = lastStrokeLocation {
                            let dx = current.x - last.x
                            let dy = current.y - last.y
                            petStrokeDistance += sqrt(dx * dx + dy * dy)
                        }
                        lastStrokeLocation = current

                        if petStrokeDistance >= 80 && !isBouncing {
                            petStrokeDistance = 0
                            lastStrokeLocation = nil
                            let hadXP = userData.equippedPet?.canEarnPetXP ?? false
                            if userData.petPet() {
                                triggerPetBounce()
                                triggerHeartsOnly()
                            }
                            showFloatingXP(hadXP ? "+\(PetConfig.shared.xpPerPetting) XP" : "Petted!")
                        }
                    }
                    .onEnded { _ in
                        petStrokeDistance = 0
                        lastStrokeLocation = nil
                    }
            )
        }
    }

    // MARK: - XP Bar

    private func xpBar(pet: OwnedPet) -> some View {
        XPProgressBar(
            progress: pet.xpProgress,
            currentXP: pet.experience - pet.xpForCurrentStage,
            targetXP: pet.xpForNextStage - pet.xpForCurrentStage,
            label: pet.isMaxEvolution ? "Max Level" : "to \(PetConfig.shared.stageName(for: pet.evolutionStage + 1))"
        )
    }

    // MARK: - Care Tray (draggable food + water)

    private func careTray(pet: OwnedPet) -> some View {
        HStack(spacing: 16) {
            draggableItem(
                icon: "leaf.fill",
                label: "Food",
                count: userData.inventory.food,
                xpAvailable: pet.canEarnFeedXP,
                enabled: userData.inventory.food > 0,
                dragLocation: $foodDragLocation,
                isDragging: $isDraggingFood
            ) {
                let hadXP = pet.canEarnFeedXP
                if userData.feedPet() {
                    triggerPetBounce()
                    triggerHeartsOnly()
                    showFloatingXP(hadXP ? "+\(PetConfig.shared.xpPerFeeding) XP" : "Fed!")
                }
            }

            draggableItem(
                icon: "drop.fill",
                label: "Water",
                count: userData.inventory.water,
                xpAvailable: pet.canEarnWaterXP,
                enabled: userData.inventory.water > 0,
                dragLocation: $waterDragLocation,
                isDragging: $isDraggingWater
            ) {
                let hadXP = pet.canEarnWaterXP
                if userData.waterPet() {
                    triggerPetBounce()
                    triggerHeartsOnly()
                    showFloatingXP(hadXP ? "+\(PetConfig.shared.xpPerWatering) XP" : "Watered!")
                }
            }

            VStack(spacing: 4) {
                Image(systemName: "hand.draw.fill")
                    .font(.system(size: 18))
                    .foregroundColor(AppColors.textTertiary)
                Text("Rub pet")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.textTertiary)
                Text(pet.canEarnPetXP ? "+XP" : "Done today")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(pet.canEarnPetXP ? AppColors.xp : AppColors.textTertiary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 72)
            .background(AppColors.surface)
            .cornerRadius(12)
        }
    }

    private func draggableItem(
        icon: String,
        label: String,
        count: Int,
        xpAvailable: Bool,
        enabled: Bool,
        dragLocation: Binding<CGPoint>,
        isDragging: Binding<Bool>,
        onDrop: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(enabled ? AppColors.accent : AppColors.textTertiary)
            Text("\(label) x\(count)")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(enabled ? AppColors.textPrimary : AppColors.textTertiary)
            Text(xpAvailable ? "+XP" : "Done today")
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(xpAvailable ? AppColors.xp : AppColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 72)
        .background(AppColors.surface)
        .cornerRadius(12)
        .opacity(isDragging.wrappedValue ? 0.4 : 1.0)
        .gesture(
            enabled
            ? DragGesture(coordinateSpace: .global)
                .onChanged { value in
                    dragLocation.wrappedValue = value.location
                    isDragging.wrappedValue = true
                    let dropTarget = petFrame.insetBy(dx: -20, dy: -20)
                    isHoveringPet = dropTarget.contains(value.location)
                }
                .onEnded { value in
                    isDragging.wrappedValue = false
                    isHoveringPet = false

                    let dropTarget = petFrame.insetBy(dx: -20, dy: -20)
                    if dropTarget.contains(value.location) {
                        onDrop()
                    }
                }
            : nil
        )
    }

    // MARK: - Drag Ghost Icon

    private func dragGhostIcon(_ icon: String, globalLocation: CGPoint) -> some View {
        Image(systemName: icon)
            .font(.system(size: 32))
            .foregroundColor(AppColors.accent)
            .shadow(color: AppColors.accent.opacity(0.5), radius: 8)
            .position(
                x: globalLocation.x - rootFrame.minX,
                y: globalLocation.y - rootFrame.minY
            )
            .allowsHitTesting(false)
    }

    // MARK: - Floating XP Label

    private func floatingXPLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 16, weight: .bold, design: .rounded))
            .foregroundColor(AppColors.xp)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(AppColors.surface)
            .cornerRadius(10)
            .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
            .position(x: screenSize.width / 2, y: petFrame.midY - rootFrame.minY - 20)
            .transition(.opacity.combined(with: .move(edge: .bottom)))
            .allowsHitTesting(false)
    }

    private func showFloatingXP(_ text: String) {
        withAnimation(.easeOut(duration: 0.2)) { floatingXP = text }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeIn(duration: 0.3)) { floatingXP = nil }
        }
    }

    // MARK: - Care Hint Overlay (first-time)

    private var careHintOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture { hasSeenCareHint = true }

            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: "hand.draw.fill")
                        .font(.system(size: 28))
                        .foregroundColor(AppColors.accent)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Drag food onto your pet to feed")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(AppColors.textPrimary)
                        Text("Rub your pet to show love")
                            .font(.system(size: 13, design: .rounded))
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                .padding(20)
                .background(AppColors.surface)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.2), radius: 12, y: 4)

                Text("Tap anywhere to dismiss")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(AppColors.textTertiary)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                hasSeenCareHint = true
            }
        }
    }

    // MARK: - Boost Banners

    @ViewBuilder
    private var boostBanners: some View {
        if let boost = userData.inventory.activeXPBoost {
            HStack {
                Image(systemName: "arrow.up.circle.fill")
                    .foregroundColor(AppColors.xp)
                Text("XP Boost Active")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                Text(formatTimeRemaining(boost.remainingSeconds))
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
            }
            .padding(10)
            .background(AppColors.xp.opacity(0.1))
            .cornerRadius(10)
        }

        if userData.inventory.isHibernating {
            HStack {
                Image(systemName: "moon.zzz.fill")
                    .foregroundColor(AppColors.accentSoft)
                Text("Hibernation Active")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                Text("Pets protected")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
            }
            .padding(10)
            .background(AppColors.accentSoft.opacity(0.15))
            .cornerRadius(10)
        }
    }

    // MARK: - Stats Bar

    private var statsBar: some View {
        HStack(spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "circle.fill")
                    .font(.system(size: 10))
                    .foregroundColor(AppColors.coins)
                Text("\(userData.profile.coins)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)
                Text("coins")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
            }

            Spacer()

            if userData.profile.currentStreak > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 16))
                        .foregroundColor(AppColors.accent)
                    Text("\(userData.profile.currentStreak)")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.textPrimary)
                    Text("day streak")
                        .font(.system(size: 13, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)
                }
            }

            Spacer()

            HStack(spacing: 6) {
                Image(systemName: "figure.run")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textSecondary)
                Text("\(userData.profile.totalRuns)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)
                Text("runs")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .padding(12)
        .background(AppColors.surface)
        .cornerRadius(12)
    }

    // MARK: - Run History

    @ViewBuilder
    private var runHistorySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Run History")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                if userData.runHistory.count > 1 {
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            showAllRuns.toggle()
                        }
                    } label: {
                        Text(showAllRuns ? "Show Less" : "See All (\(userData.runHistory.count))")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(AppColors.accent)
                    }
                }
            }

            if userData.runHistory.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 6) {
                        Image(systemName: "figure.run")
                            .font(.system(size: 24))
                            .foregroundColor(AppColors.textTertiary)
                        Text("No runs yet. Go for a run!")
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(AppColors.textTertiary)
                    }
                    .padding(.vertical, 20)
                    Spacer()
                }
            } else {
                let runsToShow = showAllRuns
                    ? Array(userData.runHistory.prefix(20))
                    : Array(userData.runHistory.prefix(1))

                ForEach(runsToShow) { run in
                    runRow(run)
                }
            }
        }
    }

    private func runRow(_ run: CompletedRun) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(run.date, style: .date)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)
                HStack(spacing: 8) {
                    Label(formatDuration(run.durationSeconds), systemImage: "clock")
                    Label("\(run.sprintsCompleted) sprints", systemImage: "bolt.fill")
                }
                .font(.system(size: 12, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                HStack(spacing: 3) {
                    Text("+\(run.coinsEarned)")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(AppColors.coins)
                    Image(systemName: "circle.fill")
                        .font(.system(size: 5))
                        .foregroundColor(AppColors.coins)
                }
                Text("+\(run.xpEarned) XP")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(AppColors.xp)
            }
        }
        .padding(12)
        .background(AppColors.surface)
        .cornerRadius(12)
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
        let hearts: [(x: CGFloat, startY: CGFloat, size: CGFloat, delay: Double)] = [
            (-55, 10, 20, 0.0),
            (-70, 20, 16, 0.08),
            (55, 10, 20, 0.04),
            (70, 20, 16, 0.12),
        ]

        return ZStack {
            ForEach(0..<hearts.count, id: \.self) { i in
                let h = hearts[i]
                Image(systemName: "heart.fill")
                    .font(.system(size: h.size))
                    .foregroundColor(i % 2 == 0 ? AppColors.petHappy : AppColors.accent.opacity(0.8))
                    .offset(
                        x: h.x,
                        y: heartAnimationPhase ? h.startY - 70 : h.startY
                    )
                    .opacity(heartAnimationPhase ? 0 : 1)
                    .scaleEffect(heartAnimationPhase ? 1.2 : 0.6)
                    .animation(
                        .easeOut(duration: 1.6).delay(h.delay),
                        value: heartAnimationPhase
                    )
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Animations

    private func triggerPetBounce() {
        isBouncing = true

        let hops: [(height: CGFloat, up: Double, hang: Double, down: Double)] = [
            (height: -22, up: 0.22, hang: 0.10, down: 0.18),
            (height: -16, up: 0.20, hang: 0.08, down: 0.16),
            (height: -9,  up: 0.16, hang: 0.05, down: 0.14),
        ]

        var t: Double = 0
        for hop in hops {
            let launchTime = t
            let landTime = t + hop.up + hop.hang + hop.down

            DispatchQueue.main.asyncAfter(deadline: .now() + launchTime) {
                withAnimation(.easeOut(duration: hop.up)) { bounceOffset = hop.height }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + launchTime + hop.up + hop.hang) {
                withAnimation(.easeIn(duration: hop.down)) { bounceOffset = 0 }
            }

            t = landTime + 0.06
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + t + 0.1) {
            bounceOffset = 0
            isBouncing = false
        }
        userData.recordInteraction()
    }

    private func triggerHeartsOnly() {
        showHearts = true
        heartAnimationPhase = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
            heartAnimationPhase = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            showHearts = false
            heartAnimationPhase = false
        }
    }

    // MARK: - Helpers

    private func formatDuration(_ totalSeconds: Int) -> String {
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private func formatTimeRemaining(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        if hours > 0 { return "\(hours)h \(minutes)m" }
        return "\(minutes)m"
    }
}
