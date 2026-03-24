import SwiftUI

struct VineBorderOverlay: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                cornerVine(at: .topLeading, width: w, height: h)
                cornerVine(at: .topTrailing, width: w, height: h)
                cornerVine(at: .bottomLeading, width: w, height: h)
                cornerVine(at: .bottomTrailing, width: w, height: h)
            }
        }
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private func cornerVine(at alignment: Alignment, width: CGFloat, height: CGFloat) -> some View {
        let leafSize: CGFloat = 14
        let vineColor = AppColors.vineDark.opacity(0.3)
        let leafColor = AppColors.vineLight.opacity(0.25)

        Canvas { ctx, size in
            let isTop = alignment == .topLeading || alignment == .topTrailing
            let isLeft = alignment == .topLeading || alignment == .bottomLeading
            let cx: CGFloat = isLeft ? 0 : size.width
            let cy: CGFloat = isTop ? 0 : size.height
            let xDir: CGFloat = isLeft ? 1 : -1
            let yDir: CGFloat = isTop ? 1 : -1

            var vinePath = Path()
            vinePath.move(to: CGPoint(x: cx, y: cy + yDir * 20))

            vinePath.addQuadCurve(
                to: CGPoint(x: cx + xDir * 50, y: cy + yDir * 8),
                control: CGPoint(x: cx + xDir * 20, y: cy + yDir * 16)
            )
            vinePath.addQuadCurve(
                to: CGPoint(x: cx + xDir * 80, y: cy),
                control: CGPoint(x: cx + xDir * 65, y: cy + yDir * 4)
            )

            ctx.stroke(vinePath, with: .color(vineColor), lineWidth: 2)

            var verticalVine = Path()
            verticalVine.move(to: CGPoint(x: cx + xDir * 8, y: cy))
            verticalVine.addQuadCurve(
                to: CGPoint(x: cx + xDir * 12, y: cy + yDir * 70),
                control: CGPoint(x: cx + xDir * 18, y: cy + yDir * 35)
            )
            ctx.stroke(verticalVine, with: .color(vineColor), lineWidth: 1.5)

            let leafPositions: [(CGFloat, CGFloat, Angle)] = [
                (xDir * 30, yDir * 12, .degrees(isLeft ? -30 : 210)),
                (xDir * 60, yDir * 5, .degrees(isLeft ? -15 : 195)),
                (xDir * 14, yDir * 30, .degrees(isLeft ? 60 : 120)),
                (xDir * 10, yDir * 55, .degrees(isLeft ? 45 : 135)),
            ]

            for (lx, ly, angle) in leafPositions {
                let leafRect = CGRect(
                    x: cx + lx - leafSize / 2,
                    y: cy + ly - leafSize / 2,
                    width: leafSize,
                    height: leafSize
                )
                var leafPath = Path()
                let center = CGPoint(x: leafRect.midX, y: leafRect.midY)
                leafPath.move(to: CGPoint(x: center.x - 5, y: center.y))
                leafPath.addQuadCurve(
                    to: CGPoint(x: center.x + 5, y: center.y),
                    control: CGPoint(x: center.x, y: center.y - 7)
                )
                leafPath.addQuadCurve(
                    to: CGPoint(x: center.x - 5, y: center.y),
                    control: CGPoint(x: center.x, y: center.y + 7)
                )

                var transform = CGAffineTransform.identity
                transform = transform.translatedBy(x: center.x, y: center.y)
                transform = transform.rotated(by: angle.radians)
                transform = transform.translatedBy(x: -center.x, y: -center.y)
                let rotated = leafPath.applying(transform)

                ctx.fill(rotated, with: .color(leafColor))
            }
        }
        .frame(width: width, height: height)
    }
}
