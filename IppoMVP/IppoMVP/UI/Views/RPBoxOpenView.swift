import SwiftUI

/// Full-screen RP Box opening experience with interactive tap-to-open mechanic
struct RPBoxOpenView: View {
    @EnvironmentObject var userData: UserData
    @Environment(\.dismiss) var dismiss
    
    @State private var phase: OpenPhase = .idle
    @State private var contents: RPBoxContents?
    
    // Tap mechanic
    @State private var tapsRequired: Int = 5
    @State private var tapCount: Int = 0
    @State private var showHint: Bool = false
    
    // Animation states
    @State private var boxScale: CGFloat = 0.6
    @State private var boxRotation: Double = 0
    @State private var boxGlow: Double = 0.3
    @State private var boxShakeOffset: CGFloat = 0
    @State private var boxOpacity: Double = 1
    @State private var flashOpacity: Double = 0
    @State private var revealScale: CGFloat = 0.3
    @State private var revealOpacity: Double = 0
    @State private var glowPulse: Bool = false
    @State private var lidOffset: CGFloat = 0
    @State private var lightRays: Bool = false
    @State private var borderGlow: Double = 0.6
    @State private var tapWiggle: Double = 0
    
    // Tap sparkles
    @State private var tapSparkles: [TapSparkle] = []
    
    enum OpenPhase {
        case idle
        case tapping   // User taps the box
        case shaking   // Short auto-shake before burst
        case burst
        case reveal
    }
    
    private var tapProgress: Double {
        guard tapsRequired > 0 else { return 0 }
        return Double(tapCount) / Double(tapsRequired)
    }
    
    var tierColor: Color {
        guard let tier = contents?.tier else { return AppColors.brandPrimary }
        return AppColors.forTier(tier)
    }
    
    // Soft haptic generator for taps
    private let softHaptic = UIImpactFeedbackGenerator(style: .soft)
    
    var body: some View {
        ZStack {
            // Background
            AppColors.background
                .ignoresSafeArea()
            
            // Light rays behind box
            if lightRays {
                LightRaysView(color: tierColor)
                    .opacity(phase == .reveal ? 0.4 : 0.1 + tapProgress * 0.2)
                    .animation(.easeInOut(duration: 0.3), value: tapProgress)
            }
            
            // Flash overlay
            Color.white
                .ignoresSafeArea()
                .opacity(flashOpacity)
            
            // Confetti
            if phase == .burst || phase == .reveal {
                BoxConfettiView(tier: contents?.tier ?? .common)
            }
            
            // Tap sparkles layer
            ForEach(tapSparkles) { sparkle in
                Image(systemName: "sparkle")
                    .font(.system(size: sparkle.size))
                    .foregroundColor(sparkle.color)
                    .position(sparkle.position)
                    .opacity(sparkle.opacity)
                    .scaleEffect(sparkle.scale)
            }
            .allowsHitTesting(false)
            
            // Main content
            VStack(spacing: 30) {
                Spacer()
                
                // Box count (idle only)
                if phase == .idle {
                    Text("\(userData.totalRPBoxes) RP Boxes")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppColors.textSecondary)
                        .transition(.opacity)
                }
                
                // Hint text (tapping phase)
                if phase == .tapping && showHint {
                    Text("Tap to open!")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(AppColors.textSecondary)
                        .transition(.opacity)
                }
                
                // The Box or the Reveal
                if phase != .reveal {
                    boxView
                        .offset(x: boxShakeOffset)
                        .scaleEffect(boxScale)
                        .opacity(boxOpacity)
                        .rotation3DEffect(.degrees(boxRotation), axis: (x: 0, y: 1, z: 0))
                        .rotationEffect(.degrees(tapWiggle))
                        .onTapGesture {
                            if phase == .tapping {
                                handleBoxTap()
                            }
                        }
                } else {
                    revealView
                        .scaleEffect(revealScale)
                        .opacity(revealOpacity)
                }
                
                Spacer()
                
                // Bottom buttons (idle only)
                if phase == .idle {
                    VStack(spacing: 12) {
                        Button {
                            beginTapping()
                        } label: {
                            Text("Open Box")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        colors: [AppColors.brandPrimary, AppColors.brandSecondary],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(14)
                        }
                        .disabled(userData.totalRPBoxes == 0)
                        
                        Button("Close") { dismiss() }
                            .font(.system(size: 15))
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .padding(.horizontal, 30)
                    .transition(.opacity)
                }
                
                // Reveal buttons
                if phase == .reveal {
                    VStack(spacing: 12) {
                        if userData.totalRPBoxes > 0 {
                            Button {
                                resetForNextBox()
                            } label: {
                                Text("Open Another (\(userData.totalRPBoxes) left)")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(tierColor)
                                    .cornerRadius(12)
                            }
                        }
                        
                        Button("Done") { dismiss() }
                            .font(.system(size: 15))
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .padding(.horizontal, 30)
                    .transition(.opacity)
                }
            }
            .padding(.bottom, 40)
        }
        .onAppear {
            softHaptic.prepare()
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                boxScale = 1.0
            }
        }
    }
    
    // MARK: - Box View
    private var boxView: some View {
        ZStack {
            // Glow behind box (intensifies with taps)
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    RadialGradient(
                        colors: [
                            AppColors.brandPrimary.opacity(
                                phase == .tapping ? (0.3 + tapProgress * 0.5) : (glowPulse ? 0.5 : 0.2)
                            ),
                            .clear
                        ],
                        center: .center,
                        startRadius: 40,
                        endRadius: 120
                    )
                )
                .frame(width: 200, height: 200)
                .blur(radius: 20)
            
            // Box body
            ZStack {
                // Box base
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "#2A2A3E"),
                                Color(hex: "#1A1A2E"),
                                Color(hex: "#12121F")
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 140)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        AppColors.brandPrimary.opacity(borderGlow),
                                        AppColors.brandSecondary.opacity(borderGlow * 0.5),
                                        AppColors.brandPrimary.opacity(borderGlow)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: phase == .tapping ? 2 + tapProgress * 2 : 2
                            )
                    )
                    .shadow(color: AppColors.brandPrimary.opacity(boxGlow), radius: 20)
                
                // Gift icon
                Image(systemName: "gift.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [AppColors.brandPrimary, AppColors.brandSecondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Lid
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#3A3A52"), Color(hex: "#2A2A3E")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 150, height: 30)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(AppColors.brandPrimary.opacity(borderGlow * 0.7), lineWidth: 1)
                    )
                    .offset(y: -55 + lidOffset)
                    .opacity(phase == .burst ? 0 : 1)
            }
            .rotation3DEffect(.degrees(8), axis: (x: 1, y: 0, z: 0), perspective: 0.5)
        }
    }
    
    // MARK: - Reveal View
    private var revealView: some View {
        VStack(spacing: 16) {
            Text(contents?.tier.displayName.uppercased() ?? "")
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .tracking(3)
                .foregroundColor(tierColor)
            
            Text("+\(contents?.rpAmount ?? 0)")
                .font(.system(size: 72, weight: .heavy, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [tierColor, tierColor.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: tierColor.opacity(0.5), radius: 20)
            
            Text("Reputation Points")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(AppColors.textSecondary)
        }
    }
    
    // MARK: - Begin Tapping Phase
    private func beginTapping() {
        // Open box data immediately
        contents = userData.openRPBox()
        guard contents != nil else { return }
        
        tapsRequired = Int.random(in: 3...7)
        tapCount = 0
        showHint = true
        lightRays = true
        
        withAnimation(.easeInOut(duration: 0.3)) {
            phase = .tapping
        }
        
        // Fade hint after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeOut(duration: 0.5)) {
                showHint = false
            }
        }
    }
    
    // MARK: - Handle Box Tap
    private func handleBoxTap() {
        tapCount += 1
        
        // Hide hint on first tap
        if tapCount == 1 {
            withAnimation(.easeOut(duration: 0.3)) {
                showHint = false
            }
        }
        
        // Gentle haptic (Clash Royale feel -- very soft)
        softHaptic.impactOccurred(intensity: 0.4)
        
        // Progressive glow
        withAnimation(.easeOut(duration: 0.2)) {
            boxGlow = 0.3 + tapProgress * 0.5
            borderGlow = 0.6 + tapProgress * 0.4
            lidOffset = -15.0 * CGFloat(tapProgress)
        }
        
        // Scale bump: quick pop then back
        withAnimation(.spring(response: 0.12, dampingFraction: 0.5)) {
            boxScale = 1.0 + 0.08 * CGFloat(tapProgress + 0.3)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.spring(response: 0.15, dampingFraction: 0.6)) {
                boxScale = 1.0
            }
        }
        
        // Tiny rotation wiggle
        let wiggleDirection: Double = tapCount.isMultiple(of: 2) ? 1 : -1
        withAnimation(.spring(response: 0.1, dampingFraction: 0.3)) {
            tapWiggle = wiggleDirection * (2 + tapProgress * 3)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.15, dampingFraction: 0.5)) {
                tapWiggle = 0
            }
        }
        
        // Spawn tap sparkles
        spawnTapSparkles()
        
        // Check if final tap
        if tapCount >= tapsRequired {
            // Short delay then trigger burst sequence
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                triggerBurstSequence()
            }
        }
    }
    
    // MARK: - Tap Sparkles
    private func spawnTapSparkles() {
        let centerX = UIScreen.main.bounds.width / 2
        let centerY = UIScreen.main.bounds.height / 2 - 30
        let sparkleCount = Int.random(in: 3...5)
        let colors: [Color] = [AppColors.brandPrimary, AppColors.brandSecondary, .white, Color(hex: "#FFD700")]
        
        for i in 0..<sparkleCount {
            let id = Int(Date().timeIntervalSince1970 * 1000) + i
            let angle = Double.random(in: 0...360)
            let startOffset = CGFloat.random(in: 30...60)
            let startX = centerX + cos(angle * .pi / 180) * startOffset
            let startY = centerY + sin(angle * .pi / 180) * startOffset
            
            let sparkle = TapSparkle(
                id: id,
                position: CGPoint(x: startX, y: startY),
                color: colors.randomElement()!,
                size: CGFloat.random(in: 8...16),
                opacity: 1.0,
                scale: 0.3
            )
            tapSparkles.append(sparkle)
            
            // Animate out
            let endDistance = CGFloat.random(in: 40...80)
            let endX = startX + cos(angle * .pi / 180) * endDistance
            let endY = startY + sin(angle * .pi / 180) * endDistance
            
            withAnimation(.easeOut(duration: 0.4)) {
                if let idx = tapSparkles.firstIndex(where: { $0.id == id }) {
                    tapSparkles[idx].position = CGPoint(x: endX, y: endY)
                    tapSparkles[idx].scale = 1.0
                }
            }
            
            // Fade out
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.easeOut(duration: 0.3)) {
                    if let idx = tapSparkles.firstIndex(where: { $0.id == id }) {
                        tapSparkles[idx].opacity = 0
                    }
                }
            }
            
            // Remove
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                tapSparkles.removeAll { $0.id == id }
            }
        }
    }
    
    // MARK: - Burst Sequence (shortened since box is already "charged")
    private func triggerBurstSequence() {
        HapticsManager.shared.playMedium()
        
        // Short shake (0.4s -- box is already charged from taps)
        phase = .shaking
        
        withAnimation(.linear(duration: 0.04).repeatCount(10, autoreverses: true)) {
            boxShakeOffset = 10
        }
        
        withAnimation(.easeIn(duration: 0.4)) {
            boxGlow = 1.0
            lidOffset = -25
        }
        
        // Burst after 0.4s
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            HapticsManager.shared.playHeavy()
            phase = .burst
            boxShakeOffset = 0
            
            withAnimation(.easeOut(duration: 0.3)) {
                boxScale = 1.5
                boxOpacity = 0
            }
            
            withAnimation(.easeOut(duration: 0.15)) {
                flashOpacity = 0.8
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.easeOut(duration: 0.4)) {
                    flashOpacity = 0
                }
            }
            
            // Reveal after 0.4s
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                HapticsManager.shared.playSuccess()
                phase = .reveal
                
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    revealScale = 1.0
                    revealOpacity = 1
                }
            }
        }
    }
    
    // MARK: - Reset
    private func resetForNextBox() {
        phase = .idle
        contents = nil
        tapCount = 0
        tapsRequired = 5
        showHint = false
        boxScale = 0.6
        boxRotation = 0
        boxGlow = 0.3
        boxShakeOffset = 0
        boxOpacity = 1
        flashOpacity = 0
        revealScale = 0.3
        revealOpacity = 0
        lidOffset = 0
        lightRays = false
        borderGlow = 0.6
        tapWiggle = 0
        tapSparkles = []
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            boxScale = 1.0
        }
    }
}

// MARK: - Tap Sparkle
private struct TapSparkle: Identifiable {
    let id: Int
    var position: CGPoint
    let color: Color
    let size: CGFloat
    var opacity: Double
    var scale: CGFloat
}

// MARK: - Light Rays Background
private struct LightRaysView: View {
    let color: Color
    @State private var rotation: Double = 0
    
    var body: some View {
        ZStack {
            ForEach(0..<12, id: \.self) { index in
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.3), color.opacity(0)],
                            startPoint: .center,
                            endPoint: .top
                        )
                    )
                    .frame(width: 4, height: UIScreen.main.bounds.height)
                    .rotationEffect(.degrees(Double(index) * 30 + rotation))
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}

// MARK: - Box Confetti
private struct BoxConfettiView: View {
    let tier: RPBoxTier
    @State private var particles: [BoxParticle] = []
    
    private var colors: [Color] {
        let tierColor = AppColors.forTier(tier)
        return [
            tierColor,
            tierColor.opacity(0.7),
            AppColors.brandPrimary,
            AppColors.brandSecondary,
            .white,
            Color(hex: "#FFD700")
        ]
    }
    
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
    }
    
    private func createParticles(in size: CGSize) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2 - 50)
        
        for i in 0..<60 {
            let particle = BoxParticle(
                id: i,
                color: colors.randomElement()!,
                width: CGFloat.random(in: 6...14),
                height: CGFloat.random(in: 4...8),
                rotation: Double.random(in: 0...360),
                position: center,
                opacity: 1.0
            )
            particles.append(particle)
            
            let delay = Double.random(in: 0...0.2)
            let angle = Double.random(in: 0...360)
            let distance = CGFloat.random(in: 150...400)
            let endX = center.x + cos(angle * .pi / 180) * distance
            let endY = center.y + sin(angle * .pi / 180) * distance + CGFloat.random(in: 100...300)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeOut(duration: Double.random(in: 1.5...2.5))) {
                    if let index = particles.firstIndex(where: { $0.id == i }) {
                        particles[index].position = CGPoint(x: endX, y: endY)
                        particles[index].rotation += Double.random(in: 360...720)
                        particles[index].opacity = 0
                    }
                }
            }
        }
    }
}

private struct BoxParticle: Identifiable {
    let id: Int
    let color: Color
    let width: CGFloat
    let height: CGFloat
    var rotation: Double
    var position: CGPoint
    var opacity: Double
}

#Preview {
    RPBoxOpenView()
        .environmentObject(UserData.shared)
}
