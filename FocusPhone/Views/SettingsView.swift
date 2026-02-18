import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @State private var showingResetAlert = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            Form {
                Section("Safari Content Blocker") {
                    HStack {
                        Image(systemName: viewModel.contentBlockerEnabled ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .foregroundStyle(viewModel.contentBlockerEnabled ? .green : .orange)
                        Text(viewModel.contentBlockerEnabled ? "Enabled" : "Not Enabled")
                        Spacer()
                        if !viewModel.contentBlockerEnabled {
                            Button("Open Settings") {
                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(url)
                                }
                            }
                            .font(.caption)
                        }
                    }
                    if !viewModel.contentBlockerEnabled {
                        Text("Enable in Settings > Safari > Extensions to block websites during focus modes.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Schedule") {
                    HStack {
                        Text("Modes")
                        Spacer()
                        Text("\(viewModel.totalModes)")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Time Blocks")
                        Spacer()
                        Text("\(viewModel.totalTimeBlocks)")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Data") {
                    Button(role: .destructive) {
                        showingResetAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Reset All Data")
                        }
                    }
                    .alert("Reset All Data?", isPresented: $showingResetAlert) {
                        Button("Cancel", role: .cancel) { }
                        Button("Reset", role: .destructive) {
                            viewModel.resetAllData()
                        }
                    } message: {
                        Text("This will delete all custom modes, time blocks, and schedules. Default modes will be restored.")
                    }
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("\(viewModel.appVersion) (\(viewModel.buildNumber))")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("FocusPhone")
                        Spacer()
                        Text("The calendar that controls your phone")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .onAppear { viewModel.loadData() }
            .onChange(of: scenePhase) {
                if scenePhase == .active {
                    viewModel.checkContentBlockerState()
                }
            }
        }
    }
}
