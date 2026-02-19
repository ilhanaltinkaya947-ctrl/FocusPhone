import SwiftUI

struct AIGeneratingView: View {
    @ObservedObject var viewModel: AIOnboardingViewModel
    var onComplete: () -> Void

    @State private var sparkleRotation: Double = 0

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
                ProgressView()
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
        .onChange(of: viewModel.generatedBlocks) {
            if !viewModel.generatedBlocks.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    onComplete()
                }
            }
        }
    }
}
