import SwiftUI

struct AnimatedMascot: View {
    let state: MascotState
    var size: CGFloat? = nil

    @Environment(\.responsiveMetrics) private var metrics

    @State private var breathScale: CGFloat = 1.0
    @State private var isBlinking = false
    @State private var twitchOffset: CGFloat = 0
    @State private var headTilt: Double = 0
    @State private var thinkingRotation: Double = 0
    @State private var showThinkingParticles = false
    @State private var reactionScale: CGFloat = 1.0

    @State private var blinkTimer: Timer?
    @State private var twitchTimer: Timer?

    private var resolvedSize: CGFloat {
        size ?? metrics.mascotSize
    }

    var body: some View {
        ZStack {
            // Thinking particles
            if showThinkingParticles {
                thinkingParticlesView
            }

            RawDogMascot(state: displayState, size: resolvedSize)
                .scaleEffect(breathScale * reactionScale)
                .offset(x: twitchOffset)
                .rotationEffect(.degrees(headTilt))
        }
        .onAppear { startIdleAnimations() }
        .onDisappear { stopTimers() }
        .onChange(of: state) { _, newState in
            handleStateTransition(newState)
        }
    }

    private var displayState: MascotState {
        isBlinking ? .proud : state
    }

    // MARK: - Thinking Particles

    private var thinkingParticlesView: some View {
        ForEach(0..<3, id: \.self) { i in
            Circle()
                .fill(RawDog.Colors.accentGlow.opacity(0.5))
                .frame(width: 6, height: 6)
                .offset(
                    x: cos(thinkingRotation * .pi / 180 + Double(i) * 2.094) * resolvedSize * 0.45,
                    y: sin(thinkingRotation * .pi / 180 + Double(i) * 2.094) * resolvedSize * 0.45
                )
        }
        .onAppear {
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                thinkingRotation = 360
            }
        }
    }

    // MARK: - Idle Animations

    private func startIdleAnimations() {
        // Breathing
        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
            breathScale = 1.02
        }

        // Blink every ~4s
        blinkTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { _ in
            guard state != .proud else { return } // Already has closed eyes
            Task { @MainActor in
                isBlinking = true
                try? await Task.sleep(for: .milliseconds(150))
                isBlinking = false
            }
        }

        // Head twitch every ~7s
        twitchTimer = Timer.scheduledTimer(withTimeInterval: 7.0, repeats: true) { _ in
            Task { @MainActor in
                let offset = CGFloat.random(in: -2...2)
                withAnimation(.spring(response: 0.3, dampingFraction: 0.4)) {
                    twitchOffset = offset
                }
                try? await Task.sleep(for: .milliseconds(400))
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    twitchOffset = 0
                }
            }
        }
    }

    private func stopTimers() {
        blinkTimer?.invalidate()
        blinkTimer = nil
        twitchTimer?.invalidate()
        twitchTimer = nil
    }

    // MARK: - State Transitions

    private func handleStateTransition(_ newState: MascotState) {
        switch newState {
        case .listening:
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                headTilt = -8
                reactionScale = 1.0
            }
            showThinkingParticles = false

        case .thinking:
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                headTilt = 0
            }
            showThinkingParticles = true
            thinkingRotation = 0

        case .proud, .amused, .concerned:
            showThinkingParticles = false
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                headTilt = 0
                reactionScale = 1.08
            }
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(300))
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    reactionScale = 1.0
                }
            }

        default:
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                headTilt = 0
                reactionScale = 1.0
            }
            showThinkingParticles = false
        }
    }
}

#Preview("Animated Mascot") {
    VStack(spacing: 30) {
        AnimatedMascot(state: .neutral, size: 120)
        AnimatedMascot(state: .thinking, size: 120)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.black)
}
