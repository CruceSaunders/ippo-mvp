import SwiftUI

struct TutorialOverlayView: View {
    let petImageName: String
    let onComplete: () -> Void

    @State private var tutorialStep: Int = 0
    @State private var petBounce: CGFloat = 0
    @State private var showMiniHearts = false
    @State private var showSuccess = false

    // Hint animation state
    @State private var hintFingerOffset: CGSize = .zero
    @State private var hintFoodOffset: CGSize = .zero
    @State private var hintFingerOpacity: Double = 0
    @State private var hintFingerScale: CGFloat = 1.0
    @State private var hintAnimationCycle = 0

    // User drag state
    @State private var userDragOffset: CGSize = .zero
    @State private var userDragStart: CGPoint = .zero
    @State private var isUserDragging = false
    @State private var isOverPet = false

    // Rub gesture state
    @State private var rubStrokeDistance: CGFloat = 0
    @State private var lastRubLocation: CGPoint?

    // Pet area tracking
    @State private var petFrame: CGRect = .zero

    private let petCenter = CGPoint(x: 0, y: -10)
    private let foodOrigin = CGPoint(x: -50, y: 100)
    private let waterOrigin = CGPoint(x: 50, y: 100)

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Text(instructionText)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.textPrimary)
                .multilineTextAlignment(.center)
                .animation(.easeInOut(duration: 0.3), value: tutorialStep)
                .animation(.easeInOut(duration: 0.3), value: showSuccess)

            Text(subtitleText)
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .animation(.easeInOut(duration: 0.3), value: tutorialStep)
                .animation(.easeInOut(duration: 0.3), value: showSuccess)

            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(AppColors.surface.opacity(0.5))
                    .frame(height: 300)

                VStack(spacing: 0) {
                    ZStack {
                        PetImageView(imageName: petImageName, isDropTarget: isOverPet)
                            .frame(width: 140, height: 140)
                            .offset(y: petBounce)
                            .background(
                                GeometryReader { geo in
                                    Color.clear
                                        .preference(key: TutorialPetFrameKey.self, value: geo.frame(in: .global))
                                }
                            )

                        if showMiniHearts {
                            tutorialHearts
                        }
                    }
                    .offset(y: -10)
                    .highPriorityGesture(
                        tutorialStep == 2 && !showSuccess
                        ? DragGesture(minimumDistance: 5, coordinateSpace: .local)
                            .onChanged { value in
                                let current = value.location
                                if let last = lastRubLocation {
                                    let dx = current.x - last.x
                                    let dy = current.y - last.y
                                    rubStrokeDistance += sqrt(dx * dx + dy * dy)
                                }
                                lastRubLocation = current

                                if rubStrokeDistance >= 80 {
                                    rubStrokeDistance = 0
                                    lastRubLocation = nil
                                    completeStep()
                                }
                            }
                            .onEnded { _ in
                                rubStrokeDistance = 0
                                lastRubLocation = nil
                            }
                        : nil
                    )

                    trayView
                        .offset(y: 10)
                }

                if isUserDragging {
                    Image(systemName: tutorialStep == 0 ? "leaf.fill" : "drop.fill")
                        .font(.system(size: 28))
                        .foregroundColor(AppColors.accent)
                        .shadow(color: AppColors.accent.opacity(0.5), radius: 8)
                        .position(
                            x: userDragStart.x + userDragOffset.width,
                            y: userDragStart.y + userDragOffset.height
                        )
                        .allowsHitTesting(false)
                }

                if !isUserDragging && !showSuccess {
                    hintFingerView
                }
            }
            .frame(height: 300)
            .padding(.horizontal, 20)
            .onPreferenceChange(TutorialPetFrameKey.self) { frame in
                petFrame = frame
            }

            Spacer()
        }
        .onAppear { startHintLoop() }
        .onChange(of: tutorialStep) { _, _ in
            resetHintState()
            startHintLoop()
        }
    }

    // MARK: - Text

    private var instructionText: String {
        if showSuccess && tutorialStep >= 3 {
            return "You're all set!"
        }
        switch tutorialStep {
        case 0: return "Drag food to feed your pet"
        case 1: return "Now give your pet water"
        case 2: return "Rub your pet to show love"
        default: return "You're all set!"
        }
    }

    private var subtitleText: String {
        if showSuccess && tutorialStep >= 3 {
            return "Feed, water, and pet your companion daily"
        }
        switch tutorialStep {
        case 0: return "Drag the food icon onto your pet"
        case 1: return "Drag the water icon onto your pet"
        case 2: return "Rub back and forth on your pet"
        default: return "Feed, water, and pet your companion daily"
        }
    }

    // MARK: - Tray

    private var trayView: some View {
        HStack(spacing: 24) {
            draggableTrayItem(
                icon: "leaf.fill",
                label: "Food",
                active: tutorialStep == 0,
                completed: tutorialStep > 0
            )

            draggableTrayItem(
                icon: "drop.fill",
                label: "Water",
                active: tutorialStep == 1,
                completed: tutorialStep > 1
            )

            VStack(spacing: 4) {
                Image(systemName: "hand.draw.fill")
                    .font(.system(size: 18))
                    .foregroundColor(tutorialStep == 2 ? AppColors.accent : AppColors.textTertiary)
                Text("Rub")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(tutorialStep == 2 ? AppColors.textPrimary : AppColors.textTertiary)
                if tutorialStep > 2 {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(AppColors.success)
                }
            }
            .frame(width: 60, height: 50)
            .background(tutorialStep == 2 ? AppColors.accentSoft.opacity(0.3) : AppColors.surface)
            .cornerRadius(10)
        }
    }

    private func draggableTrayItem(icon: String, label: String, active: Bool, completed: Bool) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(active ? AppColors.accent : AppColors.textTertiary)
            Text(label)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(active ? AppColors.textPrimary : AppColors.textTertiary)
            if completed {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 10))
                    .foregroundColor(AppColors.success)
            }
        }
        .frame(width: 60, height: 50)
        .background(active ? AppColors.accentSoft.opacity(0.3) : AppColors.surface)
        .cornerRadius(10)
        .opacity(isUserDragging && active ? 0.3 : 1.0)
        .gesture(
            active && !showSuccess
            ? DragGesture(coordinateSpace: .global)
                .onChanged { value in
                    userDragStart = value.startLocation
                    userDragOffset = value.translation
                    isUserDragging = true
                    isOverPet = petFrame.contains(value.location)
                }
                .onEnded { value in
                    isUserDragging = false
                    isOverPet = false

                    if petFrame.contains(value.location) {
                        completeStep()
                    }

                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        userDragOffset = .zero
                    }
                }
            : nil
        )
    }

    // MARK: - Hint Finger Animation

    private var hintFingerView: some View {
        Group {
            if tutorialStep <= 2 {
                ZStack {
                    if (tutorialStep == 0 || tutorialStep == 1) && hintFingerOpacity > 0 {
                        Image(systemName: tutorialStep == 0 ? "leaf.fill" : "drop.fill")
                            .font(.system(size: 22))
                            .foregroundColor(AppColors.accent.opacity(0.6))
                            .shadow(color: AppColors.accent.opacity(0.3), radius: 4)
                            .offset(x: hintFoodOffset.width, y: hintFoodOffset.height)
                            .opacity(hintFingerOpacity * 0.7)
                    }

                    Image(systemName: "hand.point.up.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.white.opacity(0.85))
                        .shadow(color: .black.opacity(0.25), radius: 4, y: 2)
                        .scaleEffect(hintFingerScale)
                        .offset(x: hintFingerOffset.width, y: hintFingerOffset.height)
                        .opacity(hintFingerOpacity)
                }
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Step Completion

    private func completeStep() {
        triggerBounce()
        showSuccess = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            showSuccess = false
            let nextStep = tutorialStep + 1
            if nextStep >= 3 {
                tutorialStep = nextStep
                showSuccess = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    onComplete()
                }
            } else {
                tutorialStep = nextStep
            }
        }
    }

    // MARK: - Hint Animation Loop

    private func resetHintState() {
        hintFingerOpacity = 0
        hintFingerScale = 1.0
        hintFingerOffset = .zero
        hintFoodOffset = .zero
    }

    private func startHintLoop() {
        guard tutorialStep < 3, !showSuccess else { return }
        let savedCycle = hintAnimationCycle

        if tutorialStep == 0 || tutorialStep == 1 {
            animateDragHint(savedCycle: savedCycle)
        } else if tutorialStep == 2 {
            animateRubHint(savedCycle: savedCycle)
        }
    }

    private func animateDragHint(savedCycle: Int) {
        let origin = tutorialStep == 0 ? foodOrigin : waterOrigin
        hintFingerOffset = CGSize(width: origin.x, height: origin.y + 20)
        hintFoodOffset = CGSize(width: origin.x, height: origin.y)
        hintFingerOpacity = 0

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            guard hintAnimationCycle == savedCycle, !showSuccess else { return }
            withAnimation(.easeIn(duration: 0.4)) {
                hintFingerOpacity = 1.0
                hintFingerOffset = CGSize(width: origin.x, height: origin.y + 10)
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            guard hintAnimationCycle == savedCycle, !showSuccess else { return }
            withAnimation(.easeInOut(duration: 1.2)) {
                hintFingerOffset = CGSize(width: petCenter.x, height: petCenter.y + 10)
                hintFoodOffset = CGSize(width: petCenter.x, height: petCenter.y)
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
            guard hintAnimationCycle == savedCycle, !showSuccess else { return }
            withAnimation(.easeOut(duration: 0.3)) {
                hintFingerOpacity = 0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            guard hintAnimationCycle == savedCycle, !showSuccess else { return }
            hintAnimationCycle += 1
            startHintLoop()
        }
    }

    private func animateRubHint(savedCycle: Int) {
        hintFingerOffset = CGSize(width: petCenter.x + 30, height: petCenter.y + 20)
        hintFingerOpacity = 0

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            guard hintAnimationCycle == savedCycle, !showSuccess else { return }
            withAnimation(.easeIn(duration: 0.3)) {
                hintFingerOpacity = 1.0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            guard hintAnimationCycle == savedCycle, !showSuccess else { return }
            withAnimation(.easeInOut(duration: 0.4)) {
                hintFingerOffset = CGSize(width: petCenter.x - 30, height: petCenter.y + 15)
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
            guard hintAnimationCycle == savedCycle, !showSuccess else { return }
            withAnimation(.easeInOut(duration: 0.4)) {
                hintFingerOffset = CGSize(width: petCenter.x + 25, height: petCenter.y + 25)
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.7) {
            guard hintAnimationCycle == savedCycle, !showSuccess else { return }
            withAnimation(.easeInOut(duration: 0.4)) {
                hintFingerOffset = CGSize(width: petCenter.x - 25, height: petCenter.y + 18)
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.3) {
            guard hintAnimationCycle == savedCycle, !showSuccess else { return }
            withAnimation(.easeOut(duration: 0.3)) {
                hintFingerOpacity = 0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.3) {
            guard hintAnimationCycle == savedCycle, !showSuccess else { return }
            hintAnimationCycle += 1
            startHintLoop()
        }
    }

    // MARK: - Bounce & Hearts

    private func triggerBounce() {
        showMiniHearts = true
        withAnimation(.easeInOut(duration: 0.12)) { petBounce = -8 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.easeInOut(duration: 0.12)) { petBounce = 4 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) {
            withAnimation(.easeInOut(duration: 0.1)) { petBounce = 0 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            showMiniHearts = false
        }
    }

    private var tutorialHearts: some View {
        let positions: [(x: CGFloat, y: CGFloat)] = [(-30, -25), (30, -25), (-18, -45), (18, -45)]
        let sizes: [CGFloat] = [16, 13, 18, 14]

        return ZStack {
            ForEach(0..<4, id: \.self) { i in
                Image(systemName: "heart.fill")
                    .font(.system(size: sizes[i]))
                    .foregroundColor(i % 2 == 0 ? AppColors.petHappy : AppColors.accent.opacity(0.8))
                    .offset(
                        x: positions[i].x,
                        y: showMiniHearts ? positions[i].y - 15 : positions[i].y + 10
                    )
                    .opacity(showMiniHearts ? 0 : 1)
                    .scaleEffect(showMiniHearts ? 1.2 : 0.4)
                    .animation(
                        .easeOut(duration: 1.0).delay(Double(i) * 0.06),
                        value: showMiniHearts
                    )
            }
        }
        .allowsHitTesting(false)
    }
}

private struct TutorialPetFrameKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}
