import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @State private var showingResetAlert = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 12) {
                        settingsIcon("safari", color: .blue)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Safari Content Blocker")
                                .font(.subheadline.weight(.medium))
                            Text(viewModel.contentBlockerEnabled ? "Enabled" : "Not Enabled")
                                .font(.caption)
                                .foregroundStyle(viewModel.contentBlockerEnabled ? .green : .orange)
                        }

                        Spacer()

                        if viewModel.contentBlockerEnabled {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        } else {
                            Button("Enable") {
                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(url)
                                }
                            }
                            .font(.caption.weight(.medium))
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                    .padding(.vertical, 2)

                    if !viewModel.contentBlockerEnabled {
                        Label {
                            Text("Go to Settings > Safari > Extensions to enable website blocking during focus modes.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } icon: {
                            Image(systemName: "info.circle")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        }
                    }
                } header: {
                    Text("Extensions")
                }

                Section {
                    HStack(spacing: 12) {
                        settingsIcon("square.stack.fill", color: .purple)
                        Text("Modes")
                        Spacer()
                        Text("\(viewModel.totalModes)")
                            .foregroundStyle(.secondary)
                    }
                    HStack(spacing: 12) {
                        settingsIcon("calendar.badge.clock", color: .blue)
                        Text("Time Blocks")
                        Spacer()
                        Text("\(viewModel.totalTimeBlocks)")
                            .foregroundStyle(.secondary)
                    }
                    HStack(spacing: 12) {
                        settingsIcon("globe", color: .orange)
                        Text("Blocked Websites")
                        Spacer()
                        Text("\(viewModel.totalBlockedWebsites)")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Schedule")
                }

                Section {
                    Button(role: .destructive) {
                        showingResetAlert = true
                    } label: {
                        HStack(spacing: 12) {
                            settingsIcon("arrow.counterclockwise", color: .red)
                            Text("Reset All Data")
                                .foregroundStyle(.red)
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
                } header: {
                    Text("Data")
                }

                Section {
                    HStack(spacing: 12) {
                        settingsIcon("info.circle", color: .gray)
                        Text("Version")
                        Spacer()
                        Text("\(viewModel.appVersion) (\(viewModel.buildNumber))")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("About")
                } footer: {
                    Text("FocusPhone — The calendar that controls your phone")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 12)
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

    private func settingsIcon(_ systemName: String, color: Color) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 14))
            .foregroundStyle(.white)
            .frame(width: 28, height: 28)
            .background(color, in: RoundedRectangle(cornerRadius: 6))
    }
}
