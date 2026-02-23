import SwiftUI

struct VoiceChatOverlay: View {
    @ObservedObject var speechService: SpeechService
    let onSend: (String) -> Void
    let onCancel: () -> Void

    @State private var waveformLevels: [CGFloat] = Array(repeating: 0.15, count: 10)
    @State private var waveformTimer: Timer?
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.92)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Live transcription
                Group {
                    if speechService.transcribedText.isEmpty {
                        listeningDots
                    } else {
                        Text(speechService.transcribedText)
                            .font(RawDog.Typography.title2)
                            .foregroundStyle(RawDog.Colors.textPrimary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                }
                .frame(minHeight: 60)

                // Waveform
                waveformView
                    .frame(height: 60)
                    .padding(.horizontal, 40)

                // Pulsing mic
                pulsingMic

                Spacer()

                // Bottom controls
                HStack(spacing: 60) {
                    // Cancel
                    Button {
                        onCancel()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(RawDog.Colors.textSecondary)
                            .frame(width: 56, height: 56)
                            .background(RawDog.Colors.surfaceElevated, in: Circle())
                    }

                    // Send
                    Button {
                        let text = speechService.transcribedText
                        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                        onSend(text)
                    } label: {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(RawDog.Colors.background)
                            .frame(width: 56, height: 56)
                            .background(
                                speechService.transcribedText.isEmpty
                                    ? RawDog.Colors.surfaceElevated
                                    : RawDog.Colors.accent,
                                in: Circle()
                            )
                    }
                    .disabled(speechService.transcribedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear { startWaveform() }
        .onDisappear { stopWaveform() }
    }

    // MARK: - Listening Dots

    private var listeningDots: some View {
        HStack(spacing: 4) {
            Text("Listening")
                .font(RawDog.Typography.title2)
                .foregroundStyle(RawDog.Colors.textSecondary)
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(RawDog.Colors.textSecondary)
                    .frame(width: 5, height: 5)
                    .opacity(pulseScale > 1.1 ? 1 : 0.4)
                    .animation(
                        .easeInOut(duration: 0.6)
                        .repeatForever()
                        .delay(Double(i) * 0.2),
                        value: pulseScale
                    )
            }
        }
    }

    // MARK: - Waveform

    private var waveformView: some View {
        HStack(spacing: 4) {
            ForEach(0..<10, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(RawDog.Colors.accent)
                    .frame(width: 4, height: max(4, waveformLevels[i] * 60))
                    .animation(.easeInOut(duration: 0.1), value: waveformLevels[i])
            }
        }
    }

    // MARK: - Pulsing Mic

    private var pulsingMic: some View {
        ZStack {
            // Concentric pulse rings
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .stroke(RawDog.Colors.accent.opacity(0.15), lineWidth: 1.5)
                    .frame(
                        width: 80 + CGFloat(i) * 30,
                        height: 80 + CGFloat(i) * 30
                    )
                    .scaleEffect(pulseScale)
                    .opacity(2.0 - Double(pulseScale) - Double(i) * 0.3)
            }

            // Mic icon
            Image(systemName: "mic.fill")
                .font(.system(size: 28))
                .foregroundStyle(RawDog.Colors.accent)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulseScale = 1.3
            }
        }
    }

    // MARK: - Waveform Timer

    private func startWaveform() {
        waveformTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            Task { @MainActor in
                if speechService.isListening {
                    waveformLevels = (0..<10).map { _ in CGFloat.random(in: 0.15...1.0) }
                } else {
                    // Decay
                    waveformLevels = waveformLevels.map { max(0.15, $0 * 0.85) }
                }
            }
        }
    }

    private func stopWaveform() {
        waveformTimer?.invalidate()
        waveformTimer = nil
    }
}
