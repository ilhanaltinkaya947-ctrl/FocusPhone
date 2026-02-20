import SwiftUI

struct OnboardingAPIKeyView: View {
    var onContinue: () -> Void

    @State private var apiKey: String = ""
    @State private var isTesting = false
    @State private var testResult: TestResult?

    private enum TestResult {
        case success
        case failure
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.08))
                    .frame(width: 120, height: 120)
                Image(systemName: "sparkles")
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(.purple)
            }

            Text("Smart Schedule Builder")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .padding(.top, 20)

            Text("Connect Groq AI to generate\na personalized schedule")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 4)

            // Instructions
            VStack(alignment: .leading, spacing: 12) {
                instructionRow(number: "1", text: "Visit console.groq.com")
                instructionRow(number: "2", text: "Create a free account & API key")
                instructionRow(number: "3", text: "Paste the key below")
            }
            .padding(16)
            .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 32)
            .padding(.top, 24)

            // Link
            Button {
                if let url = URL(string: "https://console.groq.com/keys") {
                    UIApplication.shared.open(url)
                }
            } label: {
                Label("Open Groq Console", systemImage: "arrow.up.right.square")
                    .font(.subheadline.weight(.medium))
            }
            .padding(.top, 12)

            // API Key input
            HStack(spacing: 8) {
                SecureField("gsk_...", text: $apiKey)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                Button {
                    saveAndTest()
                } label: {
                    if isTesting {
                        ProgressView()
                            .frame(width: 60)
                    } else {
                        Text("Save")
                            .font(.subheadline.weight(.semibold))
                            .frame(width: 60)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple)
                .disabled(apiKey.trimmingCharacters(in: .whitespaces).isEmpty || isTesting)
            }
            .padding(.horizontal, 32)
            .padding(.top, 16)

            // Test result
            if let result = testResult {
                HStack(spacing: 6) {
                    Image(systemName: result == .success ? "checkmark.circle.fill" : "xmark.circle.fill")
                    Text(result == .success ? "Connected successfully!" : "Connection failed. Check your key.")
                }
                .font(.caption.weight(.medium))
                .foregroundStyle(result == .success ? .green : .red)
                .padding(.top, 8)
            }

            Spacer()

            // Buttons
            VStack(spacing: 12) {
                if testResult == .success {
                    continueButton("Continue", color: .purple)
                }

                continueButton(
                    testResult == .success ? "Continue without AI" : "Skip for now",
                    style: testResult == .success ? .secondary : .primary,
                    color: testResult == .success ? .purple : .gray
                )
            }
        }
    }

    private func instructionRow(number: String, text: String) -> some View {
        HStack(spacing: 12) {
            Text(number)
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(Color.purple, in: Circle())
            Text(text)
                .font(.subheadline)
        }
    }

    private enum ButtonStyle {
        case primary, secondary
    }

    private func continueButton(_ title: String, style: ButtonStyle = .primary, color: Color = .blue) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            onContinue()
        } label: {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(style == .primary ? color : Color.clear)
                .foregroundStyle(style == .primary ? .white : color)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(style == .secondary ? color : Color.clear, lineWidth: 2)
                )
        }
        .padding(.horizontal, 32)
    }

    private func saveAndTest() {
        let trimmed = apiKey.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        KeychainService.saveAPIKey(trimmed)
        AppState.shared.aiEnabled = true
        isTesting = true
        testResult = nil

        Task {
            let success = await GroqService.shared.testConnection()
            isTesting = false
            testResult = success ? .success : .failure
            if !success {
                KeychainService.deleteAPIKey()
                AppState.shared.aiEnabled = false
            }
        }
    }
}
