import SwiftUI

struct AISettingsSection: View {
    @Binding var aiEnabled: Bool
    @Binding var weeklyReviewDay: Int
    @State private var apiKeyText = ""
    @State private var hasStoredKey = KeychainService.hasKey
    @State private var connectionStatus: ConnectionStatus = .idle

    private enum ConnectionStatus {
        case idle, testing, success, failure
    }

    private let dayNames = [
        (1, "Sunday"), (2, "Monday"), (3, "Tuesday"),
        (4, "Wednesday"), (5, "Thursday"), (6, "Friday"), (7, "Saturday"),
    ]

    var body: some View {
        Section {
            Toggle("Enable AI Features", isOn: $aiEnabled)
                .onChange(of: aiEnabled) {
                    AppState.shared.aiEnabled = aiEnabled
                }

            if aiEnabled {
                // API Key entry
                if hasStoredKey {
                    HStack(spacing: 8) {
                        Image(systemName: "key.fill")
                            .foregroundStyle(.green)
                            .font(.caption)
                        Text("API key stored securely")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("Remove") {
                            KeychainService.deleteAPIKey()
                            hasStoredKey = false
                            apiKeyText = ""
                            connectionStatus = .idle
                        }
                        .font(.caption)
                        .foregroundStyle(.red)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        SecureField("Groq API Key", text: $apiKeyText)
                            .textContentType(.password)
                            .autocorrectionDisabled()

                        if !apiKeyText.isEmpty {
                            Button("Save Key") {
                                KeychainService.saveAPIKey(apiKeyText)
                                hasStoredKey = true
                                apiKeyText = ""
                            }
                            .font(.caption.weight(.medium))
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }

                    Text("Get a free key at console.groq.com")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // Test connection
                if hasStoredKey {
                    HStack {
                        Button {
                            testConnection()
                        } label: {
                            HStack(spacing: 6) {
                                switch connectionStatus {
                                case .idle:
                                    Image(systemName: "antenna.radiowaves.left.and.right")
                                    Text("Test Connection")
                                case .testing:
                                    ProgressView()
                                        .controlSize(.small)
                                    Text("Testing...")
                                case .success:
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                    Text("Connected")
                                case .failure:
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.red)
                                    Text("Failed")
                                }
                            }
                            .font(.subheadline)
                        }
                        .disabled(connectionStatus == .testing)
                    }
                }

                // Weekly review day picker
                Picker("Weekly Review Day", selection: $weeklyReviewDay) {
                    ForEach(dayNames, id: \.0) { day in
                        Text(day.1).tag(day.0)
                    }
                }
                .onChange(of: weeklyReviewDay) {
                    AppState.shared.weeklyReviewDay = weeklyReviewDay
                }
            }
        } header: {
            Text("AI Features")
        } footer: {
            if aiEnabled {
                Text("AI features use Groq's free API for schedule suggestions and natural language editing.")
            }
        }
    }

    private func testConnection() {
        connectionStatus = .testing
        Task {
            let success = await GroqService.shared.testConnection()
            await MainActor.run {
                connectionStatus = success ? .success : .failure
            }
        }
    }
}
