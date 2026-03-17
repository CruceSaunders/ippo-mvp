import SwiftUI

struct EvolutionAnimationView: View {
    @Binding var isPresented: Bool
    let evolution: PendingEvolution
    let onDismiss: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var phase: EvolutionPhase = .announce
    @State private var tapPromptOpacity: Double = 0

    // Phase 1: Announce
    @State private var announceTextOpacity: Double = 0
    @State private var announcePetScale: CGFloat = 0.6
    @State private var announcePetOpacity: Double = 0
    @State private var sparklePhase = false

    // Phase 2: Transform
    @State private var spinRotation: Double = 0
    @State private var spinScale: CGFloat = 1.0
    @State private var spinOpacity: Double = 1.0
    @State private var dustBurst = false
    @State private var whiteFlash: Double = 0

    // Phase 3: Reveal
    @State private var revealScale: CGFloat = 0.2
    @State private var revealOpacity: Double = 0
    @State private var glowPulse = false
    @State private var showConfetti = false

    // Phase 4: Congrats
    @State private var congratsOpacity: Double = 0
    @State private var congratsOffset: CGFloat = 30

    private enum EvolutionPhase {
        case announce, transform, reveal, congrats
    }

    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()

            switch phase {
            case .announce:
                announcePhase
            case .transform:
                transformPhase
            case .reveal:
                revealPhase
            case .congrats:
                congratsPhase
            }
        }
        .onAppear {
            if reduceMotion {
                phase = .congrats
                congratsOpacity = 1
                congratsOffset = 0
            } else {
                enterAnnounce()
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Evolution: \(evolution.petName) evolved to \(evolution.stageName)")
        .accessibilityAddTraits(.isModal)
    }

    private var backgroundColor: some View {
        ZStack {
            AppColors.background

            Color.white
                .opacity(whiteFlash)
                .animation(.easeInOut(duration: 0.3), value: whiteFlash)
        }
    }

    // MARK: - Phase 1: Announce

    private var announcePhase: some View {
        ZStack {
            sparkleField

            VStack(spacing: 32) {
                Spacer()

                Text("\(evolution.petName) is evolving!")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)
                    .opacity(announceTextOpacity)
                    .multilineTextAlignment(.center)

                ZStack {
                    Circle()
                        .fill(AppColors.accent.opacity(0.15))
                        .frame(width: 260, height: 260)
                        .blur(radius: 30)

                    Image(evolution.oldImageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 200, height: 200)
                        .scaleEffect(announcePetScale)
                        .opacity(announcePetOpacity)
                }

                Spacer()

                Text("Tap to continue")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.textTertiary)
                    .opacity(tapPromptOpacity)
                    .padding(.bottom, 60)
            }
            .padding(.horizontal, 32)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            beginTransform()
        }
    }

    // MARK: - Phase 2: Transform

    private var transformPhase: some View {
        ZStack {
            if dustBurst {
                DustParticleView()
                    .transition(.opacity)
            }

            Image(evolution.oldImageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 200, height: 200)
                .rotation3DEffect(
                    .degrees(spinRotation),
                    axis: (x: 0, y: 1, z: 0),
                    perspective: 0.5
                )
                .scaleEffect(spinScale)
                .opacity(spinOpacity)
        }
    }

    // MARK: - Phase 3: Reveal

    private var revealPhase: some View {
        ZStack {
            if showConfetti {
                ConfettiView(particleCount: 80)
                    .ignoresSafeArea()
            }

            ZStack {
                Circle()
                    .fill(AppColors.accent.opacity(glowPulse ? 0.25 : 0.08))
                    .frame(width: glowPulse ? 320 : 240, height: glowPulse ? 320 : 240)
                    .blur(radius: 40)
                    .animation(
                        .easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                        value: glowPulse
                    )

                Image(evolution.newImageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 220, height: 220)
                    .scaleEffect(revealScale)
                    .opacity(revealOpacity)
            }
        }
    }

    // MARK: - Phase 4: Congrats

    private var congratsPhase: some View {
        ZStack {
            if showConfetti {
                ConfettiView(particleCount: 40)
                    .ignoresSafeArea()
            }

            VStack(spacing: 24) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(AppColors.accent.opacity(glowPulse ? 0.2 : 0.08))
                        .frame(width: 280, height: 280)
                        .blur(radius: 30)
                        .animation(
                            .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                            value: glowPulse
                        )

                    Image(evolution.newImageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 200, height: 200)
                }

                VStack(spacing: 8) {
                    Text("\(evolution.petName)")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.textPrimary)

                    Text("is now a \(evolution.stageName)!")
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundColor(AppColors.accent)
                }

                Spacer()

                Text("Tap to continue")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.textTertiary)
                    .opacity(tapPromptOpacity)
                    .padding(.bottom, 60)
            }
            .padding(.horizontal, 32)
            .opacity(congratsOpacity)
            .offset(y: congratsOffset)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            dismiss()
        }
    }

    // MARK: - Sparkle Field

    private var sparkleField: some View {
        GeometryReader { geo in
            ForEach(0..<12, id: \.self) { i in
                SparkleParticle(
                    containerSize: geo.size,
                    index: i,
                    isAnimating: sparklePhase
                )
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Phase Transitions

    private func enterAnnounce() {
        withAnimation(.easeOut(duration: 0.6)) {
            announceTextOpacity = 1
        }
        withAnimation(.spring(response: 0.7, dampingFraction: 0.6).delay(0.3)) {
            announcePetScale = 1.0
            announcePetOpacity = 1
        }
        withAnimation(.easeInOut(duration: 0.5).delay(1.2)) {
            tapPromptOpacity = 1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            sparklePhase = true
        }
    }

    private func beginTransform() {
        tapPromptOpacity = 0
        sparklePhase = false
        phase = .transform

        HapticsManager.shared.playLight()

        withAnimation(.easeIn(duration: 2.5)) {
            spinRotation = 1080
            spinScale = 0.1
            spinOpacity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            HapticsManager.shared.playMedium()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation(.easeIn(duration: 0.3)) {
                dustBurst = true
            }
            HapticsManager.shared.playHeavy()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            whiteFlash = 1.0
            HapticsManager.shared.playSuccess()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            enterReveal()
        }
    }

    private func enterReveal() {
        phase = .reveal
        showConfetti = true
        SoundManager.shared.play(.evolution)

        withAnimation(.easeOut(duration: 0.3)) {
            whiteFlash = 0
        }

        withAnimation(.spring(response: 0.8, dampingFraction: 0.55).delay(0.2)) {
            revealScale = 1.0
            revealOpacity = 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            glowPulse = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            enterCongrats()
        }
    }

    private func enterCongrats() {
        phase = .congrats

        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            congratsOpacity = 1
            congratsOffset = 0
        }

        withAnimation(.easeInOut(duration: 0.5).delay(0.8)) {
            tapPromptOpacity = 1
        }
    }

    private func dismiss() {
        if reduceMotion {
            isPresented = false
            onDismiss()
            return
        }

        withAnimation(.easeOut(duration: 0.25)) {
            congratsOpacity = 0
            showConfetti = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            isPresented = false
            onDismiss()
        }
    }
}

// MARK: - Sparkle Particle

private struct SparkleParticle: View {
    let containerSize: CGSize
    let index: Int
    let isAnimating: Bool

    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.3

    private var position: CGPoint {
        let cx = containerSize.width / 2
        let cy = containerSize.height * 0.42
        let radius: CGFloat = 130
        let angle = Double(index) * (360.0 / 12.0) * .pi / 180.0
        return CGPoint(
            x: cx + radius * CGFloat(cos(angle)),
            y: cy + radius * CGFloat(sin(angle))
        )
    }

    var body: some View {
        Image(systemName: "sparkle")
            .font(.system(size: CGFloat.random(in: 8...16)))
            .foregroundColor(AppColors.accent.opacity(0.7))
            .position(position)
            .opacity(opacity)
            .scaleEffect(scale)
            .onChange(of: isAnimating) { _, animating in
                if animating { startPulse() } else { opacity = 0 }
            }
    }

    private func startPulse() {
        let delay = Double(index) * 0.12
        withAnimation(
            .easeInOut(duration: 1.2)
            .repeatForever(autoreverses: true)
            .delay(delay)
        ) {
            opacity = Double.random(in: 0.4...0.9)
            scale = CGFloat.random(in: 0.7...1.2)
        }
    }
}

// MARK: - Dust Particle View

private struct DustParticleView: View {
    @State private var particles: [DustParticle] = (0..<30).map { _ in
        DustParticle()
    }

    var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            ForEach(particles.indices, id: \.self) { i in
                Circle()
                    .fill(particles[i].color)
                    .frame(width: particles[i].size, height: particles[i].size)
                    .position(
                        x: center.x + particles[i].offset.width,
                        y: center.y + particles[i].offset.height
                    )
                    .opacity(particles[i].opacity)
            }
        }
        .onAppear { animateParticles() }
        .allowsHitTesting(false)
    }

    private func animateParticles() {
        for i in particles.indices {
            let angle = Double.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 80...200)
            withAnimation(
                .easeOut(duration: Double.random(in: 0.6...1.2))
                .delay(Double.random(in: 0...0.2))
            ) {
                particles[i].offset = CGSize(
                    width: distance * CGFloat(cos(angle)),
                    height: distance * CGFloat(sin(angle))
                )
                particles[i].opacity = 0
            }
        }
    }
}

private struct DustParticle {
    var offset: CGSize = .zero
    var opacity: Double = Double.random(in: 0.5...1.0)
    let size: CGFloat = CGFloat.random(in: 3...8)
    let color: Color = [AppColors.accent, AppColors.accentSoft, AppColors.gold, .white]
        .randomElement()!
}
