import SwiftUI

struct PetEnvironmentView: View {
    let mood: Int
    let isHibernating: Bool
    var timeOverride: Int? = nil

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var particlePhase: CGFloat = 0
    @State private var twinklePhase: Bool = false

    private var currentHour: Int {
        timeOverride ?? Calendar.current.component(.hour, from: Date())
    }

    private var currentMinute: Int {
        Calendar.current.component(.minute, from: Date())
    }

    private var timeProgress: Double {
        (Double(currentHour) + Double(currentMinute) / 60.0) / 24.0
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                skyGradient
                if isNight {
                    starsLayer(size: geo.size)
                }
                celestialBody(size: geo.size)
                particleField(size: geo.size)
                groundPlane(size: geo.size)
                moodOverlay
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                particlePhase = 1
            }
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                twinklePhase.toggle()
            }
        }
    }

    // MARK: - Time Period Detection

    private var period: TimePeriod {
        let h = currentHour
        switch h {
        case 5..<7: return .dawn
        case 7..<10: return .morning
        case 10..<16: return .day
        case 16..<18: return .goldenHour
        case 18..<20: return .sunset
        default: return .night
        }
    }

    private var isNight: Bool { period == .night }

    // MARK: - Sky Gradient

    private var skyGradient: some View {
        LinearGradient(
            colors: skyColors,
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var skyColors: [Color] {
        switch period {
        case .dawn:
            return [
                Color(hex: "#FFD4A8"),
                Color(hex: "#FFBFA0"),
                Color(hex: "#FFF0E0")
            ]
        case .morning:
            return [
                Color(hex: "#FFE8C8"),
                Color(hex: "#FFF4E8"),
                Color(hex: "#E8F0FF")
            ]
        case .day:
            return [
                Color(hex: "#FFF6ED"),
                Color(hex: "#EEF4FB"),
                Color(hex: "#E0ECFA")
            ]
        case .goldenHour:
            return [
                Color(hex: "#FFD08A"),
                Color(hex: "#FFBA6A"),
                Color(hex: "#FFE0B0")
            ]
        case .sunset:
            return [
                Color(hex: "#E8887A"),
                Color(hex: "#C87AAA"),
                Color(hex: "#6A5A9A")
            ]
        case .night:
            return [
                Color(hex: "#1A1A3E"),
                Color(hex: "#2A2050"),
                Color(hex: "#3A2A5A")
            ]
        }
    }

    // MARK: - Celestial Body

    private func celestialBody(size: CGSize) -> some View {
        let bodySize: CGFloat = isNight ? 28 : 36
        let glowSize: CGFloat = bodySize * 3
        let position = celestialPosition(size: size)

        return ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: isNight
                            ? [Color.white.opacity(0.15), Color.clear]
                            : [celestialGlowColor.opacity(0.3), Color.clear],
                        center: .center,
                        startRadius: bodySize * 0.5,
                        endRadius: glowSize * 0.5
                    )
                )
                .frame(width: glowSize, height: glowSize)

            Circle()
                .fill(
                    RadialGradient(
                        colors: isNight
                            ? [Color(hex: "#F0F0FF"), Color(hex: "#D0D0E8")]
                            : [celestialBodyColor, celestialBodyColor.opacity(0.8)],
                        center: .center,
                        startRadius: 0,
                        endRadius: bodySize * 0.5
                    )
                )
                .frame(width: bodySize, height: bodySize)
        }
        .position(x: position.x, y: position.y)
    }

    private func celestialPosition(size: CGSize) -> CGPoint {
        let progress: Double
        if isNight {
            let nightStart = 20.0
            let nightEnd = 5.0
            let h = Double(currentHour)
            if h >= nightStart {
                progress = (h - nightStart) / (24.0 - nightStart + nightEnd)
            } else {
                progress = (24.0 - nightStart + h) / (24.0 - nightStart + nightEnd)
            }
        } else {
            let dayStart = 5.0
            let dayEnd = 20.0
            let h = Double(currentHour) + Double(currentMinute) / 60.0
            progress = (h - dayStart) / (dayEnd - dayStart)
        }

        let x = size.width * (0.15 + 0.7 * progress)
        let arcHeight = size.height * 0.35
        let y = size.height * 0.15 + arcHeight * (1.0 - sin(progress * .pi))
        return CGPoint(x: x, y: y)
    }

    private var celestialBodyColor: Color {
        switch period {
        case .dawn: return Color(hex: "#FFB870")
        case .morning: return Color(hex: "#FFD090")
        case .day: return Color(hex: "#FFE8B0")
        case .goldenHour: return Color(hex: "#FFA840")
        case .sunset: return Color(hex: "#FF7040")
        case .night: return Color(hex: "#E8E8FF")
        }
    }

    private var celestialGlowColor: Color {
        switch period {
        case .dawn: return Color(hex: "#FFD0A0")
        case .morning, .day: return Color(hex: "#FFE8C0")
        case .goldenHour: return Color(hex: "#FFCC80")
        case .sunset: return Color(hex: "#FF9060")
        case .night: return Color(hex: "#8888CC")
        }
    }

    // MARK: - Stars

    private func starsLayer(size: CGSize) -> some View {
        let starCount = 30
        let seed: UInt64 = 42

        return Canvas { context, canvasSize in
            var rng = SeededRNG(seed: seed)
            for _ in 0..<starCount {
                let x = CGFloat.random(in: 0..<canvasSize.width, using: &rng)
                let y = CGFloat.random(in: 0..<(canvasSize.height * 0.6), using: &rng)
                let starSize = CGFloat.random(in: 1.5...3.5, using: &rng)
                let baseOpacity = Double.random(in: 0.3...0.9, using: &rng)
                let opacity = twinklePhase ? baseOpacity : baseOpacity * 0.4

                let rect = CGRect(x: x - starSize / 2, y: y - starSize / 2, width: starSize, height: starSize)
                context.fill(
                    Circle().path(in: rect),
                    with: .color(.white.opacity(opacity))
                )
            }
        }
        .animation(.easeInOut(duration: 2), value: twinklePhase)
    }

    // MARK: - Ground Plane

    private func groundPlane(size: CGSize) -> some View {
        let groundHeight = size.height * 0.18

        return ZStack(alignment: .bottom) {
            GroundShape()
                .fill(
                    LinearGradient(
                        colors: groundColors,
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: groundHeight + 12)

            GroundShape()
                .fill(groundHighlightColor.opacity(0.3))
                .frame(height: groundHeight)
                .offset(y: -4)
        }
        .frame(maxHeight: .infinity, alignment: .bottom)
    }

    private var groundColors: [Color] {
        switch period {
        case .dawn: return [Color(hex: "#A8C898"), Color(hex: "#88B078")]
        case .morning, .day: return [Color(hex: "#90C080"), Color(hex: "#70A060")]
        case .goldenHour: return [Color(hex: "#A0B070"), Color(hex: "#809050")]
        case .sunset: return [Color(hex: "#607858"), Color(hex: "#405040")]
        case .night: return [Color(hex: "#2A3A2A"), Color(hex: "#1A2A1A")]
        }
    }

    private var groundHighlightColor: Color {
        isNight ? Color(hex: "#3A4A3A") : Color(hex: "#C8E0B0")
    }

    // MARK: - Particles

    private func particleField(size: CGSize) -> some View {
        let count = particleCount

        return TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            Canvas { context, canvasSize in
                let time = timeline.date.timeIntervalSinceReferenceDate
                var rng = SeededRNG(seed: 137)

                for i in 0..<count {
                    let baseX = CGFloat.random(in: 0..<canvasSize.width, using: &rng)
                    let speed = Double.random(in: 0.03...0.08, using: &rng)
                    let baseY = CGFloat.random(in: 0..<canvasSize.height, using: &rng)
                    let particleSize = CGFloat.random(in: 2...5, using: &rng)
                    let baseOpacity = Double.random(in: 0.2...0.6, using: &rng)

                    let yOffset = CGFloat((time * speed * 40.0 + Double(i) * 17.3).truncatingRemainder(dividingBy: Double(canvasSize.height)))
                    let y = canvasSize.height - yOffset
                    let xWobble = sin(time * 0.5 + Double(i) * 2.1) * 8.0
                    let x = baseX + CGFloat(xWobble)

                    let pulseOpacity = isNight
                        ? baseOpacity * (0.5 + 0.5 * sin(time * 2.0 + Double(i) * 1.7))
                        : baseOpacity

                    let rect = CGRect(
                        x: x - particleSize / 2,
                        y: y - particleSize / 2,
                        width: particleSize,
                        height: particleSize
                    )

                    context.fill(
                        Circle().path(in: rect),
                        with: .color(particleColor.opacity(pulseOpacity))
                    )
                }
            }
        }
        .allowsHitTesting(false)
    }

    private var particleCount: Int {
        if reduceMotion { return 0 }
        switch mood {
        case 3: return 22
        case 2: return 15
        default: return 8
        }
    }

    private var particleColor: Color {
        switch period {
        case .dawn: return Color(hex: "#FFD080")
        case .morning: return Color(hex: "#C8E0A0")
        case .day: return Color(hex: "#FFE8B0")
        case .goldenHour: return Color(hex: "#FFCC70")
        case .sunset: return Color(hex: "#FF9060")
        case .night: return Color(hex: "#FFEE88")
        }
    }

    // MARK: - Mood Overlay

    @ViewBuilder
    private var moodOverlay: some View {
        if mood == 1 && !isHibernating {
            Color.gray.opacity(0.08)
        }
        if isHibernating {
            Color(hex: "#1A1A3E").opacity(0.12)
        }
    }
}

// MARK: - Time Period

enum TimePeriod {
    case dawn, morning, day, goldenHour, sunset, night
}

// MARK: - Ground Shape

struct GroundShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        path.move(to: CGPoint(x: 0, y: h * 0.35))

        path.addCurve(
            to: CGPoint(x: w * 0.3, y: h * 0.2),
            control1: CGPoint(x: w * 0.1, y: h * 0.15),
            control2: CGPoint(x: w * 0.2, y: h * 0.25)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.7, y: h * 0.15),
            control1: CGPoint(x: w * 0.45, y: h * 0.12),
            control2: CGPoint(x: w * 0.55, y: h * 0.2)
        )
        path.addCurve(
            to: CGPoint(x: w, y: h * 0.3),
            control1: CGPoint(x: w * 0.85, y: h * 0.1),
            control2: CGPoint(x: w * 0.95, y: h * 0.25)
        )

        path.addLine(to: CGPoint(x: w, y: h))
        path.addLine(to: CGPoint(x: 0, y: h))
        path.closeSubpath()

        return path
    }
}

// MARK: - Seeded RNG for deterministic particle positions

struct SeededRNG: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}

// MARK: - Preview

#Preview("Dawn") {
    PetEnvironmentView(mood: 3, isHibernating: false, timeOverride: 6)
        .frame(height: 350)
        .padding()
}

#Preview("Day") {
    PetEnvironmentView(mood: 3, isHibernating: false, timeOverride: 12)
        .frame(height: 350)
        .padding()
}

#Preview("Golden Hour") {
    PetEnvironmentView(mood: 2, isHibernating: false, timeOverride: 17)
        .frame(height: 350)
        .padding()
}

#Preview("Night") {
    PetEnvironmentView(mood: 1, isHibernating: false, timeOverride: 22)
        .frame(height: 350)
        .padding()
}

#Preview("Hibernating") {
    PetEnvironmentView(mood: 2, isHibernating: true, timeOverride: 14)
        .frame(height: 350)
        .padding()
}
