import SwiftUI

struct AIGeneratingView: View {
    @ObservedObject var viewModel: AIOnboardingViewModel
    var onComplete: () -> Void

    @State private var sparkleRotation: Double = 0
    @State private var statusIndex: Int = 0

    private let statusMessages = [
        "Analyzing your schedule...",
        "Placing focus blocks...",
        "Balancing your week...",
        "Adding recovery time...",
        "Almost there...",
    ]

    private let timer = Timer.publish(every: 2.0, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.08))
                    .frame(width: 180, height: 180)

                Image(systemName: "sparkles")
                    .font(.system(size: 60, weight: .light))
                    .foregroundStyle(.blue)
                    .rotationEffect(.degrees(sparkleRotation))
            }

            Text("Designing your\nideal week...")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .padding(.top, 24)

            if viewModel.isGenerating {
                VStack(spacing: 12) {
                    ProgressView()

                    Text(statusMessages[statusIndex])
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .animation(.easeInOut(duration: 0.3), value: statusIndex)
                        .id(statusIndex)
                        .transition(.opacity)
                }
                .padding(.top, 16)
            }

            if viewModel.usedFallback {
                Text("Built from your answers (AI unavailable)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 12)
            }

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.top, 8)
            }

            Spacer()
        }
        .onAppear {
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                sparkleRotation = 360
            }
            viewModel.generateSchedule()
        }
        .onReceive(timer) { _ in
            guard viewModel.isGenerating else { return }
            withAnimation {
                statusIndex = (statusIndex + 1) % statusMessages.count
            }
        }
        .onChange(of: viewModel.generatedBlocks) {
            if !viewModel.generatedBlocks.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    onComplete()
                }
            }
        }
    }
}
