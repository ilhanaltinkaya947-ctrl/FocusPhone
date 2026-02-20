import SwiftUI

struct AIGeneratingView: View {
    @ObservedObject var viewModel: AIOnboardingViewModel
    var onComplete: () -> Void

    @State private var sparkleRotation: Double = 0
    @State private var statusIndex: Int = 0
    @State private var hasTimedOut = false

    private let statusMessages = [
        "Analyzing your schedule...",
        "Placing focus blocks...",
        "Balancing your week...",
        "Adding recovery time...",
        "Almost there...",
    ]

    private let timer = Timer.publish(every: 2.0, on: .main, in: .common).autoconnect()

    private var showRetry: Bool {
        hasTimedOut || (!viewModel.isGenerating && viewModel.generatedBlocks.isEmpty)
    }

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

            if viewModel.isGenerating && !hasTimedOut {
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
                // Orange banner for fallback notice
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(.orange)
                    Text("AI unavailable — built from your answers")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal, 32)
                .padding(.top, 16)
            }

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.top, 8)
            }

            if showRetry {
                VStack(spacing: 12) {
                    Button {
                        hasTimedOut = false
                        viewModel.generateSchedule()
                    } label: {
                        Text("Try Again")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.blue)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    Button {
                        useBasicSchedule()
                    } label: {
                        Text("Use Basic Schedule")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .foregroundStyle(.blue)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.blue, lineWidth: 2)
                            )
                    }
                }
                .padding(.horizontal, 32)
                .padding(.top, 24)
            }

            Spacer()
        }
        .onAppear {
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                sparkleRotation = 360
            }
            viewModel.generateSchedule()
            startTimeout()
        }
        .onReceive(timer) { _ in
            guard viewModel.isGenerating, !hasTimedOut else { return }
            withAnimation {
                statusIndex = (statusIndex + 1) % statusMessages.count
            }
        }
        .onChange(of: viewModel.generatedBlocks) {
            if !viewModel.generatedBlocks.isEmpty {
                hasTimedOut = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    onComplete()
                }
            }
        }
    }

    private func startTimeout() {
        Task {
            try? await Task.sleep(nanoseconds: 30_000_000_000) // 30 seconds
            if viewModel.isGenerating || viewModel.generatedBlocks.isEmpty {
                hasTimedOut = true
                viewModel.isGenerating = false
            }
        }
    }

    private func useBasicSchedule() {
        let blocks = ScheduleTemplateService.generateSchedule(
            from: viewModel.profile,
            modes: AppState.shared.modes
        )
        viewModel.generatedBlocks = blocks
        viewModel.usedFallback = true
    }
}
