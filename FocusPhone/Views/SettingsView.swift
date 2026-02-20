import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @State private var showingResetAlert = false
    @State private var aiEnabled = AppState.shared.aiEnabled
    @State private var weeklyReviewDay = AppState.shared.weeklyReviewDay
    @State private var enabledPresets = AppState.shared.enabledContentFilterPresets
    @State private var isReloadingPresets = false
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

                // Content Filters
                Section {
                    ForEach(ContentFilterPresetStore.allPresets) { preset in
                        HStack(spacing: 12) {
                            Image(systemName: preset.icon)
                                .font(.system(size: 14))
                                .foregroundStyle(.white)
                                .frame(width: 28, height: 28)
                                .background(Color.blue, in: RoundedRectangle(cornerRadius: 6))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(preset.displayName)
                                    .font(.subheadline.weight(.medium))
                                Text(preset.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            if isReloadingPresets {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Toggle("", isOn: Binding(
                                    get: { enabledPresets.contains(preset.id) },
                                    set: { enabled in
                                        if enabled {
                                            enabledPresets.insert(preset.id)
                                        } else {
                                            enabledPresets.remove(preset.id)
                                        }
                                        applyPresetChange()
                                    }
                                ))
                                .labelsHidden()
                            }
                        }
                    }
                } header: {
                    Text("Content Filters")
                } footer: {
                    Text("Allow the site but hide addictive feeds like Shorts, Reels, and Explore.")
                }

                AISettingsSection(aiEnabled: $aiEnabled, weeklyReviewDay: $weeklyReviewDay)

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
                            enabledPresets = []
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

    private func applyPresetChange() {
        isReloadingPresets = true
        AppState.shared.enabledContentFilterPresets = enabledPresets

        // Re-apply content blocker rules with current mode's domains + new presets
        let domains = AppState.shared.activeMode?.blockedWebsites ?? []
        do {
            try ContentBlockerService.applyAllRules(
                domainBlocks: domains,
                enabledPresets: enabledPresets
            )
        } catch {
            print("Settings: Content blocker error: \(error.localizedDescription)")
        }

        // Brief spinner feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isReloadingPresets = false
        }
    }

    private func settingsIcon(_ systemName: String, color: Color) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 14))
            .foregroundStyle(.white)
            .frame(width: 28, height: 28)
            .background(color, in: RoundedRectangle(cornerRadius: 6))
            .accessibilityHidden(true)
    }
}
