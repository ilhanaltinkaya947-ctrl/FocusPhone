import SwiftUI

struct ExtensionRequestView: View {
    @StateObject private var viewModel: ExtensionRequestViewModel
    @Environment(\.dismiss) private var dismiss

    init(appName: String) {
        _viewModel = StateObject(wrappedValue: ExtensionRequestViewModel(appName: appName))
    }

    var body: some View {
        NavigationStack {
            Form {
                // App name
                Section {
                    HStack {
                        Image(systemName: "app.fill")
                            .foregroundStyle(.blue)
                        Text(viewModel.appName)
                            .font(.headline)
                    }
                } header: {
                    Text("Requesting Extension For")
                }

                // Daily allowance
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Daily Extension Time")
                                .font(.subheadline)
                            Spacer()
                            Text("\(viewModel.dailyUsed)/\(viewModel.dailyCap) min")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(viewModel.isCapReached ? .red : .primary)
                        }
                        ProgressView(value: viewModel.usageProgress)
                            .tint(viewModel.isCapReached ? .red : .blue)
                    }

                    if viewModel.isCapReached {
                        Label("Daily cap reached. No more extensions today.", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                // Request form
                if !viewModel.isCapReached {
                    if viewModel.result == nil {
                        Section {
                            TextField("Why do you need this app right now?", text: $viewModel.reason, axis: .vertical)
                                .lineLimit(3...6)

                            Picker("Duration", selection: $viewModel.requestedMinutes) {
                                Text("5 min").tag(5)
                                Text("10 min").tag(10)
                                Text("15 min").tag(15)
                                Text("20 min").tag(20)
                                Text("30 min").tag(30)
                            }
                        } header: {
                            Text("Your Request")
                        } footer: {
                            Text("An AI will evaluate your reason. Be specific and honest.")
                        }
                    }
                }

                // Result
                if let result = viewModel.result {
                    Section {
                        switch result {
                        case .approved(let minutes):
                            VStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 48))
                                    .foregroundStyle(.green)
                                Text("Approved")
                                    .font(.title2.bold())
                                Text("\(minutes) minutes granted")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)

                        case .denied:
                            VStack(spacing: 12) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 48))
                                    .foregroundStyle(.red)
                                Text("Denied")
                                    .font(.title2.bold())
                                Text("Stay strong. You chose these restrictions for a reason.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                        }
                    }
                }

                // Error
                if let error = viewModel.errorMessage {
                    Section {
                        Label(error, systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Request Extension")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                if viewModel.result == nil && !viewModel.isCapReached {
                    ToolbarItem(placement: .confirmationAction) {
                        if viewModel.isLoading {
                            ProgressView()
                        } else {
                            Button("Submit") {
                                viewModel.submitRequest()
                            }
                            .disabled(viewModel.reason.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                    }
                }

                if viewModel.result != nil {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { dismiss() }
                    }
                }
            }
        }
    }
}
