import SwiftUI

/// Full-screen RP Box opening experience with multi-phase animation
struct RPBoxOpenView: View {
    @EnvironmentObject var userData: UserData
    @Environment(\.dismiss) var dismiss
    
    @State private var phase: OpenPhase = .idle
    @State private var contents: RPBoxContents?
    
    // Animation states
    @State private var boxScale: CGFloat = 0.6
    @State private var boxRotation: Double = 0
    @State private var boxGlow: Double = 0.3
    @State private var boxShakeOffset: CGFloat = 0
    @State private var boxOpacity: Double = 1
    @State private var flashOpacity: Double = 0
    @State private var revealScale: CGFloat = 0.3
    @State private var revealOpacity: Double = 0
    @State private var particlePhase: Bool = false
    @State private var glowPulse: Bool = false
    @State private var lidOffset: CGFloat = 0
    @State private var lightRays: Bool = false
    
    enum OpenPhase {
        case idle
        case shaking
        case burst
        case reveal
    }
    
    var tierColor: Color {
        guard let tier = contents?.tier else { return AppColors.brandPrimary }
        return AppColors.forTier(tier)
    }
    
    var body: some View {
        ZStack {
            // Background
            AppColors.background
                .ignoresSafeArea()
            
            // Light rays behind box
            if lightRays {
                LightRaysView(color: tierColor)
                    .opacity(phase == .reveal ? 0.4 : 0.15)
                    .animation(.easeInOut(duration: 0.5), value: phase)
            }
            
            // Flash overlay
            Color.white
                .ignoresSafeArea()
                .opacity(flashOpacity)
            
            // Confetti
            if phase == .burst || phase == .reveal {
                BoxConfettiView(tier: contents?.tier ?? .common)
            }
            
            // Main content
            VStack(spacing: 30) {
                Spacer()
                
                // Box count
                if phase == .idle {
                    Text("\(userData.totalRPBoxes) RP Boxes")
                        .font(.system(size: 14, weight: .medium))
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
                } else {
                    revealView
                        .scaleEffect(revealScale)
                        .opacity(revealOpacity)
                }
                
                Spacer()
                
                // Bottom buttons
                if phase == .idle {
                    VStack(spacing: 12) {
                        Button {
                            startOpening()
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
            // Start idle glow pulse
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
            // Glow behind box
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    RadialGradient(
                        colors: [AppColors.brandPrimary.opacity(glowPulse ? 0.5 : 0.2), .clear],
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
                                        AppColors.brandPrimary.opacity(0.6),
                                        AppColors.brandSecondary.opacity(0.3),
                                        AppColors.brandPrimary.opacity(0.6)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .shadow(color: AppColors.brandPrimary.opacity(boxGlow), radius: 20)
                
                // "?" or gift icon
                Image(systemName: "gift.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [AppColors.brandPrimary, AppColors.brandSecondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Lid (moves up on burst)
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
                            .stroke(AppColors.brandPrimary.opacity(0.4), lineWidth: 1)
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
            // Tier badge
            Text(contents?.tier.displayName.uppercased() ?? "")
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .tracking(3)
                .foregroundColor(tierColor)
            
            // RP Amount
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
    
    // MARK: - Animation Sequence
    private func startOpening() {
        // Open the box data immediately
        contents = userData.openRPBox()
        guard contents != nil else { return }
        
        HapticsManager.shared.playMedium()
        
        // Phase 1: Shaking (0.8s)
        phase = .shaking
        lightRays = true
        
        // Intense shake animation
        withAnimation(.linear(duration: 0.05).repeatCount(16, autoreverses: true)) {
            boxShakeOffset = 8
        }
        
        // Glow intensifies
        withAnimation(.easeIn(duration: 0.8)) {
            boxGlow = 0.8
        }
        
        // Lid starts lifting
        withAnimation(.easeIn(duration: 0.8)) {
            lidOffset = -15
        }
        
        // Phase 2: Burst (after 0.8s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            HapticsManager.shared.playHeavy()
            phase = .burst
            boxShakeOffset = 0
            
            // Box explodes up and fades
            withAnimation(.easeOut(duration: 0.3)) {
                boxScale = 1.5
                boxOpacity = 0
            }
            
            // Flash
            withAnimation(.easeOut(duration: 0.15)) {
                flashOpacity = 0.8
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.easeOut(duration: 0.4)) {
                    flashOpacity = 0
                }
            }
            
            // Phase 3: Reveal (after 0.4s)
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
    
    private func resetForNextBox() {
        // Reset all states
        phase = .idle
        contents = nil
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
        
        // Animate box back in
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            boxScale = 1.0
        }
    }
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
