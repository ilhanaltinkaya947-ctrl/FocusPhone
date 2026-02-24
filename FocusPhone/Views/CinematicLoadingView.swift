import SwiftUI

struct CinematicLoadingView: View {
    let onComplete: () -> Void

    @State private var progress: CGFloat = 0
    @State private var currentTextIndex = 0
    @State private var textOpacity: Double = 0

    private let loadingTexts = [
        "Analyzing your habits...",
        "Building your plan...",
        "Personalizing restrictions...",
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Progress ring around mascot
            ZStack {
                Circle()
                    .stroke(RawDog.Colors.trackBackground, lineWidth: 6)
                    .frame(width: 160, height: 160)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        RawDog.Colors.accentIce,
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(-90))

                AnimatedMascot(state: .thinking, size: 80)
            }

            Spacer().frame(height: 40)

            // Sequential text reveals
            Text(currentTextIndex < loadingTexts.count ? loadingTexts[currentTextIndex] : "")
                .font(RawDog.Typography.headline)
                .foregroundStyle(RawDog.Colors.textPrimary)
                .opacity(textOpacity)
                .animation(.easeInOut(duration: 0.3), value: textOpacity)

            Spacer()
        }
        .onAppear { startAnimation() }
    }

    private func startAnimation() {
        // Animate progress ring over 3 seconds
        withAnimation(.linear(duration: 3.0)) {
            progress = 1.0
        }

        // Text 0: show immediately
        textOpacity = 1

        // Text 1: at 1 second
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            textOpacity = 0
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                currentTextIndex = 1
                textOpacity = 1
            }
        }

        // Text 2: at 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            textOpacity = 0
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                currentTextIndex = 2
                textOpacity = 1
            }
        }

        // Complete at 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) {
            onComplete()
        }
    }
}
