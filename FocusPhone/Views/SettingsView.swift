import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @State private var showingResetAlert = false
    @State private var showingEmergencyAlert = false
    @State private var showingReOnboardAlert = false
    @State private var enabledPresets = AppState.shared.enabledContentFilterPresets
    @State private var isReloadingPresets = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            Form {
                // Safari Content Blocker
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

                // Restriction Profile Summary
                if let profile = AppState.shared.restrictionProfile {
                    Section {
                        HStack(spacing: 12) {
                            settingsIcon("shield.fill", color: .blue)
                            Text("Restriction Status")
                            Spacer()
                            Text(AppState.shared.isRestrictionActive ? "Active" : "Inactive")
                                .foregroundStyle(AppState.shared.isRestrictionActive ? .green : .red)
                        }
                        HStack(spacing: 12) {
                            settingsIcon("timer", color: .orange)
                            Text("Timed Window Apps")
                            Spacer()
                            Text("\(profile.timedWindowApps.count)")
                                .foregroundStyle(.secondary)
                        }
                        HStack(spacing: 12) {
                            settingsIcon("globe", color: .red)
                            Text("Blocked Websites")
                            Spacer()
                            Text("\(profile.blockedWebsites.count)")
                                .foregroundStyle(.secondary)
                        }
                        HStack(spacing: 12) {
                            settingsIcon("clock.badge.checkmark", color: .green)
                            Text("Daily Extension Cap")
                            Spacer()
                            Text("\(profile.dailyExtensionCapMinutes) min")
                                .foregroundStyle(.secondary)
                        }
                    } header: {
                        Text("Restriction Profile")
                    }
                }

                // Actions
                Section {
                    Button {
                        showingReOnboardAlert = true
                    } label: {
                        HStack(spacing: 12) {
                            settingsIcon("arrow.counterclockwise", color: .blue)
                            Text("Re-run Onboarding")
                        }
                    }
                    .alert("Re-run Onboarding?", isPresented: $showingReOnboardAlert) {
                        Button("Cancel", role: .cancel) { }
                        Button("Re-run") { viewModel.rerunOnboarding() }
                    } message: {
                        Text("This will disable all restrictions and take you through onboarding again.")
                    }

                    Button(role: .destructive) {
                        showingEmergencyAlert = true
                    } label: {
                        HStack(spacing: 12) {
                            settingsIcon("exclamationmark.triangle.fill", color: .orange)
                            Text("Emergency Disable")
                                .foregroundStyle(.orange)
                        }
                    }
                    .alert("Emergency Disable?", isPresented: $showingEmergencyAlert) {
                        Button("Cancel", role: .cancel) { }
                        Button("Disable All", role: .destructive) { viewModel.emergencyDisable() }
                    } message: {
                        Text("This will immediately remove ALL restrictions. You can re-enable by re-running onboarding.")
                    }
                }

                // Data
                Section {
                    Button(role: .destructive) {
                        showingResetAlert = true
                    } label: {
                        HStack(spacing: 12) {
                            settingsIcon("trash.fill", color: .red)
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
                        Text("This will delete your restriction profile, extension history, and all settings.")
                    }
                } header: {
                    Text("Data")
                }

                // About
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
                    Text("FocusPhone — Make your phone dumb in the right ways")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 12)
                }
            }
            .navigationTitle("Settings")
            .onAppear { viewModel.checkContentBlockerState() }
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

        let domains = AppState.shared.restrictionProfile?.blockedWebsites ?? []
        do {
            try ContentBlockerService.applyAllRules(
                domainBlocks: domains,
                enabledPresets: enabledPresets
            )
        } catch {
            print("Settings: Content blocker error: \(error.localizedDescription)")
        }

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
