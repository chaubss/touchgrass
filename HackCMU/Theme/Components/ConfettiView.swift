import SwiftUI

/// Canvas + TimelineView burst. Fires once, on a confirmed action.
struct ConfettiView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let isActive: Bool

    private struct Particle {
        let x: CGFloat
        let drift: Double
        let speed: CGFloat
        let spin: Double
        let size: CGFloat
        let tone: Int
    }

    private static let particles: [Particle] = (0..<60).map { i in
        Particle(
            x: CGFloat.random(in: 0.10...0.90),
            drift: Double.random(in: -0.8...0.8),
            speed: CGFloat.random(in: 0.7...1.5),
            spin: Double.random(in: -6...6),
            size: CGFloat.random(in: 4...9),
            tone: i % 3
        )
    }

    var body: some View {
        if isActive && !reduceMotion {
            TimelineView(.animation) { timeline in
                Canvas { context, size in
                    let seconds = timeline.date.timeIntervalSinceReferenceDate
                    let progress = seconds.truncatingRemainder(dividingBy: 1.6) / 1.6

                    for p in Self.particles {
                        let y = -20 + CGFloat(progress) * size.height * p.speed * 1.3
                        guard y < size.height else { continue }
                        let x = p.x * size.width + CGFloat(sin(progress * 6 + p.drift)) * 26

                        let color: Color
                        switch p.tone {
                        case 0:  color = Palette.tartan
                        case 1:  color = Palette.tartanDeep
                        default: color = Palette.ink
                        }

                        var layer = context
                        layer.opacity = 1 - progress * 0.75
                        layer.translateBy(x: x, y: y)
                        layer.rotate(by: .radians(p.spin * progress * 3))
                        layer.fill(
                            Path(CGRect(x: -p.size / 2, y: -p.size / 4,
                                        width: p.size, height: p.size / 2)),
                            with: .color(color)
                        )
                    }
                }
            }
            .allowsHitTesting(false)
            .transition(.opacity)
        }
    }
}
