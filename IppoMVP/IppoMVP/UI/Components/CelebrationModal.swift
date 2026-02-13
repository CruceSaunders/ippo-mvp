// CelebrationModal.swift
// Ippo MVP - Celebration animations for rank ups, level ups, RP box opens, etc.

import SwiftUI

// MARK: - Confetti Particle

struct ConfettiParticle: View {
    let color: Color
    let size: CGFloat
    let reduceMotion: Bool
    
    @State private var position: CGPoint = .zero
    @State private var rotation: Double = 0
    @State private var opacity: Double = 1
    
    var body: some View {
        Rectangle()
            .fill(color)
            .frame(width: size, height: size * 2.5)
            .rotationEffect(.degrees(rotation))
            .position(position)
            .opacity(opacity)
            .onAppear {
                startAnimation()
            }
            .accessibilityHidden(true)
    }
    
    private func startAnimation() {
        let screenWidth = UIScreen.main.bounds.width
        position = CGPoint(
            x: CGFloat.random(in: 0...screenWidth),
            y: -20
        )
        rotation = Double.random(in: 0...360)
        
        if reduceMotion {
            position.y = CGFloat.random(in: 100...400)
            withAnimation(.easeOut(duration: 0.5)) {
                opacity = 0
            }
        } else {
            withAnimation(.easeIn(duration: Double.random(in: 2.5...4.0))) {
                position.y = UIScreen.main.bounds.height + 50
                position.x += CGFloat.random(in: -100...100)
                rotation += Double.random(in: 180...720)
            }
            
            withAnimation(.easeIn(duration: 3.0).delay(1.5)) {
                opacity = 0
            }
        }
    }
}

// MARK: - Confetti View

struct ConfettiView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    let colors: [Color] = [
        AppColors.brandPrimary,
        AppColors.brandSecondary,
        AppColors.success,
        AppColors.gold,
        AppColors.warning,
        AppColors.danger
    ]
    
    let particleCount: Int
    
    init(particleCount: Int = 50) {
        self.particleCount = particleCount
    }
    
    var body: some View {
        ZStack {
            ForEach(0..<particleCount, id: \.self) { index in
                ConfettiParticle(
                    color: colors[index % colors.count],
                    size: CGFloat.random(in: 6...12),
                    reduceMotion: reduceMotion
                )
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

// MARK: - Celebration Modal

struct CelebrationModal: View {
    @Binding var isPresented: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    let title: String
    let subtitle: String?
    let primaryStat: String
    let secondaryStat: String?
    let icon: String
    let iconColor: Color
    let accentColor: Color
    let onDismiss: () -> Void
    
    @State private var showContent = false
    @State private var showConfetti = false
    @State private var bounceScale: CGFloat = 0.5
    
    private var accessibilityDescription: String {
        var description = title
        if let subtitle = subtitle {
            description += ", \(subtitle)"
        }
        description += ". \(primaryStat)"
        if let secondaryStat = secondaryStat {
            description += ", \(secondaryStat)"
        }
        return description
    }
    
    init(
        isPresented: Binding<Bool>,
        title: String,
        subtitle: String? = nil,
        primaryStat: String,
        secondaryStat: String? = nil,
        icon: String = "trophy.fill",
        iconColor: Color = AppColors.gold,
        accentColor: Color = AppColors.brandPrimary,
        onDismiss: @escaping () -> Void = {}
    ) {
        self._isPresented = isPresented
        self.title = title
        self.subtitle = subtitle
        self.primaryStat = primaryStat
        self.secondaryStat = secondaryStat
        self.icon = icon
        self.iconColor = iconColor
        self.accentColor = accentColor
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        ZStack {
            AppColors.background.opacity(0.95)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }
            
            if showConfetti {
                ConfettiView(particleCount: 60)
                    .ignoresSafeArea()
            }
            
            VStack(spacing: AppSpacing.xl) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.3))
                        .frame(width: 120, height: 120)
                        .blur(radius: 20)
                    
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [iconColor, iconColor.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: icon)
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                }
                .scaleEffect(bounceScale)
                .accessibilityHidden(true)
                
                Text(title)
                    .font(AppTypography.largeTitle)
                    .foregroundColor(AppColors.textPrimary)
                    .multilineTextAlignment(.center)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                VStack(spacing: AppSpacing.sm) {
                    Text(primaryStat)
                        .font(AppTypography.timer)
                        .foregroundColor(accentColor)
                    
                    if let secondaryStat = secondaryStat {
                        Text(secondaryStat)
                            .font(AppTypography.subheadline)
                            .foregroundColor(AppColors.success)
                    }
                }
                .padding(.vertical, AppSpacing.lg)
                .padding(.horizontal, AppSpacing.xxl)
                .background(
                    RoundedRectangle(cornerRadius: AppSpacing.radiusMd)
                        .fill(AppColors.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppSpacing.radiusMd)
                                .stroke(AppColors.surfaceElevated, lineWidth: 1)
                        )
                )
                
                Button(action: dismiss) {
                    Text("CONTINUE")
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.lg)
                        .background(
                            RoundedRectangle(cornerRadius: AppSpacing.radiusMd)
                                .fill(accentColor)
                        )
                }
                .accessibilityLabel("Continue")
                .padding(.horizontal, AppSpacing.xxxl)
                .padding(.top, AppSpacing.sm)
            }
            .padding(AppSpacing.xxl)
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 50)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Celebration")
            .accessibilityValue(accessibilityDescription)
            .accessibilityAddTraits(.isModal)
        }
        .onAppear {
            triggerCelebration()
        }
    }
    
    private func triggerCelebration() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        if reduceMotion {
            showContent = true
            bounceScale = 1.0
            showConfetti = true
        } else {
            showConfetti = true
            
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showContent = true
            }
            
            withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
                bounceScale = 1.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.4)) {
                    bounceScale = 1.1
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                        bounceScale = 1.0
                    }
                }
            }
        }
    }
    
    private func dismiss() {
        if reduceMotion {
            showContent = false
            showConfetti = false
            isPresented = false
            onDismiss()
        } else {
            withAnimation(.easeOut(duration: 0.2)) {
                showContent = false
                showConfetti = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                isPresented = false
                onDismiss()
            }
        }
    }
}

// MARK: - Preset Variants

extension CelebrationModal {
    /// RP Box opened celebration
    static func rpBoxOpened(
        isPresented: Binding<Bool>,
        rpAmount: Int,
        tier: RPBoxTier,
        onDismiss: @escaping () -> Void = {}
    ) -> CelebrationModal {
        let tierColor = AppColors.forTier(tier)
        return CelebrationModal(
            isPresented: isPresented,
            title: "RP BOX OPENED!",
            subtitle: tier.displayName.uppercased(),
            primaryStat: "+\(rpAmount) RP",
            secondaryStat: nil,
            icon: "gift.fill",
            iconColor: tierColor,
            accentColor: tierColor,
            onDismiss: onDismiss
        )
    }
    
    /// Level up celebration
    static func levelUp(
        isPresented: Binding<Bool>,
        newLevel: Int,
        onDismiss: @escaping () -> Void = {}
    ) -> CelebrationModal {
        CelebrationModal(
            isPresented: isPresented,
            title: "LEVEL UP!",
            subtitle: "You reached a new level!",
            primaryStat: "LEVEL \(newLevel)",
            secondaryStat: "Keep running!",
            icon: "arrow.up.circle.fill",
            iconColor: AppColors.brandPrimary,
            accentColor: AppColors.brandPrimary,
            onDismiss: onDismiss
        )
    }
    
    /// Rank up celebration
    static func rankUp(
        isPresented: Binding<Bool>,
        newRank: String,
        onDismiss: @escaping () -> Void = {}
    ) -> CelebrationModal {
        CelebrationModal(
            isPresented: isPresented,
            title: "RANK UP!",
            subtitle: "You've been promoted!",
            primaryStat: newRank,
            secondaryStat: "Keep climbing!",
            icon: "shield.fill",
            iconColor: AppColors.gold,
            accentColor: AppColors.gold,
            onDismiss: onDismiss
        )
    }
    
    /// Streak milestone celebration
    static func streakMilestone(
        isPresented: Binding<Bool>,
        days: Int,
        onDismiss: @escaping () -> Void = {}
    ) -> CelebrationModal {
        CelebrationModal(
            isPresented: isPresented,
            title: "STREAK MILESTONE!",
            subtitle: "You're on fire!",
            primaryStat: "\(days) DAYS",
            secondaryStat: "Keep the momentum going!",
            icon: "flame.fill",
            iconColor: AppColors.warning,
            accentColor: AppColors.danger,
            onDismiss: onDismiss
        )
    }
}

// MARK: - Previews

#Preview("Level Up") {
    CelebrationModal.levelUp(
        isPresented: .constant(true),
        newLevel: 10
    )
}

#Preview("Streak") {
    CelebrationModal.streakMilestone(
        isPresented: .constant(true),
        days: 30
    )
}
