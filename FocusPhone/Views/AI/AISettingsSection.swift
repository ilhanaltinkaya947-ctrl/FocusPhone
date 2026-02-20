import SwiftUI

struct AISettingsSection: View {
    @Binding var aiEnabled: Bool
    @Binding var weeklyReviewDay: Int
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
                // Test connection
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
                Text("AI features power schedule suggestions, natural language editing, and weekly reviews.")
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
