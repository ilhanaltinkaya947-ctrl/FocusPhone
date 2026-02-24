import SwiftUI

struct DataShockView: View {
    let yearsToLose: Int
    let onContinue: () -> Void

    @State private var displayedYears: Int = 0
    @State private var showSubtext = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            AnimatedMascot(state: .sideeye, size: 100)
                .padding(.bottom, RawDog.Spacing.lg)

            // Giant animated counter
            Text("\(displayedYears)")
                .font(.system(size: 96, weight: .bold, design: .rounded))
                .foregroundStyle(RawDog.Colors.destructive)
                .contentTransition(.numericText())
                .monospacedDigit()

            Text("years")
                .font(RawDog.Typography.title)
                .foregroundStyle(RawDog.Colors.destructive.opacity(0.7))

            if showSubtext {
                Text("your phone will steal\nfrom your life")
                    .font(RawDog.Typography.headline)
                    .foregroundStyle(RawDog.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, RawDog.Spacing.md)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            Spacer()

            RawDog.OnboardingButton(title: "I'm ready to change", isEnabled: showSubtext) {
                onContinue()
            }
            .padding(.bottom, 40)
        }
        .onAppear { startCountAnimation() }
    }

    private func startCountAnimation() {
        // Count up from 0 to yearsToLose over ~2 seconds
        let target = max(yearsToLose, 1)
        let stepDuration = 2.0 / Double(target)

        for i in 1...target {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(i)) {
                withAnimation(.spring(response: 0.15)) {
                    displayedYears = i
                }
            }
        }

        // Show subtext after counter finishes
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.3) {
            withAnimation(.easeInOut(duration: 0.5)) {
                showSubtext = true
            }
        }
    }
}
