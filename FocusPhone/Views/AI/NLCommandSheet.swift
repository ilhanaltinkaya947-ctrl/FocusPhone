import SwiftUI

struct NLCommandSheet: View {
    @StateObject private var viewModel = NLCommandViewModel()
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isTextFieldFocused: Bool

    private let exampleCommands = [
        "Add deep work tomorrow 9-12",
        "Move exercise to Friday",
        "Remove breaks on Monday",
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if viewModel.showingConfirmation {
                    confirmationView
                } else if viewModel.resultSuccess == true {
                    successView
                } else {
                    inputView
                }
            }
            .navigationTitle("AI Schedule Editor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    // MARK: - Input View

    private var inputView: some View {
        VStack(spacing: 16) {
            // Text field
            HStack {
                TextField("What would you like to change?", text: $viewModel.commandText)
                    .textFieldStyle(.plain)
                    .focused($isTextFieldFocused)
                    .submitLabel(.send)
                    .onSubmit { viewModel.processCommand() }

                if viewModel.isProcessing {
                    ProgressView()
                        .controlSize(.small)
                } else if !viewModel.commandText.isEmpty {
                    Button {
                        viewModel.processCommand()
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.blue)
                    }
                }
            }
            .padding(12)
            .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 16)
            .padding(.top, 16)

            // Error message with specific type
            if let message = viewModel.resultMessage, viewModel.resultSuccess == false {
                HStack(spacing: 8) {
                    Image(systemName: errorIcon(for: message))
                        .foregroundStyle(.orange)
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
            }

            // Example chips
            if viewModel.commandText.isEmpty && viewModel.resultMessage == nil {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Try something like:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 16)

                    ForEach(exampleCommands, id: \.self) { command in
                        Button {
                            viewModel.commandText = command
                        } label: {
                            Text(command)
                                .font(.subheadline)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Color(.systemGray5), in: Capsule())
                                .foregroundStyle(.primary)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 16)
                    }
                }
            }

            Spacer()
        }
        .onAppear {
            isTextFieldFocused = true
        }
    }

    // MARK: - Confirmation View

    private var confirmationView: some View {
        VStack(spacing: 16) {
            Text("Proposed Changes")
                .font(.headline)
                .padding(.top, 20)

            VStack(spacing: 8) {
                ForEach(Array(viewModel.pendingChanges.enumerated()), id: \.offset) { _, change in
                    HStack(spacing: 10) {
                        Image(systemName: changeIcon(change.type))
                            .foregroundStyle(changeColor(change.type))
                            .frame(width: 24)

                        Text(viewModel.changeDescription(change))
                            .font(.subheadline)

                        Spacer()
                    }
                    .padding(12)
                    .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding(.horizontal, 16)

            if let message = viewModel.resultMessage {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 16)
            }

            Spacer()

            HStack(spacing: 12) {
                Button {
                    viewModel.showingConfirmation = false
                    viewModel.pendingChanges = []
                } label: {
                    Text("Cancel")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .foregroundStyle(.blue)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue, lineWidth: 2)
                        )
                }

                Button {
                    viewModel.applyChanges()
                } label: {
                    Text("Apply")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
    }

    // MARK: - Success View

    private var successView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.green)

            Text(viewModel.resultMessage ?? "Done!")
                .font(.headline)

            Spacer()
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                dismiss()
            }
        }
    }

    // MARK: - Helpers

    private func changeIcon(_ type: String) -> String {
        switch type {
        case "add": return "plus.circle.fill"
        case "remove": return "minus.circle.fill"
        case "move": return "arrow.right.circle.fill"
        case "resize": return "arrow.left.and.right.circle.fill"
        default: return "circle.fill"
        }
    }

    private func changeColor(_ type: String) -> Color {
        switch type {
        case "add": return .green
        case "remove": return .red
        case "move": return .blue
        case "resize": return .orange
        default: return .gray
        }
    }

    private func errorIcon(for message: String) -> String {
        if message.contains("Network") || message.contains("network") || message.contains("connection") {
            return "wifi.slash"
        } else if message.contains("Rate") || message.contains("rate") {
            return "clock.badge.exclamationmark"
        } else if message.contains("block") && message.contains("exist") {
            return "questionmark.circle"
        } else {
            return "exclamationmark.triangle.fill"
        }
    }
}
