import SwiftUI

struct ParticleBackgroundView: View {
    var particleCount: Int = 18
    var opacityRange: ClosedRange<Double> = 0.15...0.25
    var speed: Double = 0.3

    @State private var particles: [Particle] = []

    struct Particle: Identifiable {
        let id = UUID()
        var x: Double
        var y: Double
        var size: Double
        var opacity: Double
        var phase: Double // for sinusoidal sway
        var speed: Double
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate

                for particle in particles {
                    let elapsed = time * particle.speed * speed
                    let yOffset = elapsed.truncatingRemainder(dividingBy: 1.0)
                    var y = particle.y - yOffset
                    if y < 0 { y += 1.0 }

                    let swayX = sin(elapsed * 2.0 + particle.phase) * 0.02
                    let x = particle.x + swayX

                    let point = CGPoint(
                        x: x * size.width,
                        y: y * size.height
                    )
                    let rect = CGRect(
                        x: point.x - particle.size / 2,
                        y: point.y - particle.size / 2,
                        width: particle.size,
                        height: particle.size
                    )

                    context.opacity = particle.opacity
                    context.fill(
                        Circle().path(in: rect),
                        with: .color(.white)
                    )
                }
            }
        }
        .onAppear { generateParticles() }
        .allowsHitTesting(false)
    }

    private func generateParticles() {
        particles = (0..<particleCount).map { _ in
            Particle(
                x: Double.random(in: 0...1),
                y: Double.random(in: 0...1),
                size: Double.random(in: 2...4),
                opacity: Double.random(in: opacityRange),
                phase: Double.random(in: 0...(2 * .pi)),
                speed: Double.random(in: 0.03...0.08)
            )
        }
    }
}
