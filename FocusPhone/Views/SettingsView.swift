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
            ZStack {
                RawDog.Colors.background.ignoresSafeArea()

                List {
                    // Safari Content Blocker
                    Section {
                        HStack(spacing: 12) {
                            settingsIcon("safari")

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Safari Content Blocker")
                                    .font(RawDog.Typography.subheadline.weight(.medium))
                                    .foregroundStyle(RawDog.Colors.textPrimary)
                                Text(viewModel.contentBlockerEnabled ? "Enabled" : "Not Enabled")
                                    .font(RawDog.Typography.caption)
                                    .foregroundStyle(viewModel.contentBlockerEnabled ? RawDog.Colors.approved : RawDog.Colors.windowClosed)
                            }

                            Spacer()

                            if viewModel.contentBlockerEnabled {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(RawDog.Colors.approved)
                            } else {
                                Button("Enable") {
                                    if let url = URL(string: UIApplication.openSettingsURLString) {
                                        UIApplication.shared.open(url)
                                    }
                                }
                                .font(RawDog.Typography.caption.weight(.medium))
                                .buttonStyle(.bordered)
                                .tint(RawDog.Colors.accent)
                                .controlSize(.small)
                            }
                        }
                        .padding(.vertical, 2)
                        .listRowBackground(RawDog.Colors.surface)
                    } header: {
                        Text("Extensions")
                            .foregroundStyle(RawDog.Colors.textSecondary)
                    }

                    // Content Filters
                    Section {
                        ForEach(ContentFilterPresetStore.allPresets) { preset in
                            HStack(spacing: 12) {
                                Image(systemName: preset.icon)
                                    .font(.system(size: 14))
                                    .foregroundStyle(RawDog.Colors.background)
                                    .frame(width: 28, height: 28)
                                    .background(RawDog.Colors.accent, in: RoundedRectangle(cornerRadius: 6))

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(preset.displayName)
                                        .font(RawDog.Typography.subheadline.weight(.medium))
                                        .foregroundStyle(RawDog.Colors.textPrimary)
                                    Text(preset.description)
                                        .font(RawDog.Typography.caption)
                                        .foregroundStyle(RawDog.Colors.textSecondary)
                                }

                                Spacer()

                                if isReloadingPresets {
                                    ProgressView()
                                        .controlSize(.small)
                                        .tint(RawDog.Colors.accent)
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
                                    .tint(RawDog.Colors.accent)
                                }
                            }
                            .listRowBackground(RawDog.Colors.surface)
                        }
                    } header: {
                        Text("Content Filters")
                            .foregroundStyle(RawDog.Colors.textSecondary)
                    } footer: {
                        Text("Allow the site but hide addictive feeds like Shorts, Reels, and Explore.")
                            .foregroundStyle(RawDog.Colors.textSecondary.opacity(0.7))
                    }

                    // Restriction Profile Summary
                    if let profile = AppState.shared.restrictionProfile {
                        Section {
                            settingsRow("shield.fill", "Restriction Status") {
                                Text(AppState.shared.isRestrictionActive ? "Active" : "Inactive")
                                    .foregroundStyle(AppState.shared.isRestrictionActive ? RawDog.Colors.approved : RawDog.Colors.destructive)
                            }
                            settingsRow("timer", "Timed Window Apps") {
                                Text("\(profile.timedWindowApps.count)")
                                    .foregroundStyle(RawDog.Colors.textSecondary)
                            }
                            settingsRow("globe", "Blocked Websites") {
                                Text("\(profile.blockedWebsites.count)")
                                    .foregroundStyle(RawDog.Colors.textSecondary)
                            }
                            settingsRow("clock.badge.checkmark", "Daily Extension Cap") {
                                Text("\(profile.dailyExtensionCapMinutes) min")
                                    .foregroundStyle(RawDog.Colors.textSecondary)
                            }
                        } header: {
                            Text("Restriction Profile")
                                .foregroundStyle(RawDog.Colors.textSecondary)
                        }
                    }

                    // Actions
                    Section {
                        Button {
                            showingReOnboardAlert = true
                        } label: {
                            HStack(spacing: 12) {
                                settingsIcon("arrow.counterclockwise")
                                Text("Re-run Onboarding")
                                    .foregroundStyle(RawDog.Colors.textPrimary)
                            }
                        }
                        .listRowBackground(RawDog.Colors.surface)
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
                                settingsIcon("exclamationmark.triangle.fill")
                                Text("Emergency Disable")
                                    .foregroundStyle(RawDog.Colors.windowClosed)
                            }
                        }
                        .listRowBackground(RawDog.Colors.surface)
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
                                settingsIcon("trash.fill")
                                Text("Reset All Data")
                                    .foregroundStyle(RawDog.Colors.destructive)
                            }
                        }
                        .listRowBackground(RawDog.Colors.surface)
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
                            .foregroundStyle(RawDog.Colors.textSecondary)
                    }

                    // About
                    Section {
                        settingsRow("info.circle", "Version") {
                            Text("\(viewModel.appVersion) (\(viewModel.buildNumber))")
                                .foregroundStyle(RawDog.Colors.textSecondary)
                        }
                    } header: {
                        Text("About")
                            .foregroundStyle(RawDog.Colors.textSecondary)
                    } footer: {
                        Text("RawDog — Your phone. Disciplined.")
                            .foregroundStyle(RawDog.Colors.textSecondary.opacity(0.5))
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 12)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear { viewModel.checkContentBlockerState() }
            .onChange(of: scenePhase) {
                if scenePhase == .active {
                    viewModel.checkContentBlockerState()
                }
            }
        }
        .preferredColorScheme(.dark)
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

    private func settingsIcon(_ systemName: String) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 14))
            .foregroundStyle(RawDog.Colors.background)
            .frame(width: 28, height: 28)
            .background(RawDog.Colors.accent, in: RoundedRectangle(cornerRadius: 6))
            .accessibilityHidden(true)
    }

    private func settingsRow<Trailing: View>(_ icon: String, _ title: String, @ViewBuilder trailing: () -> Trailing) -> some View {
        HStack(spacing: 12) {
            settingsIcon(icon)
            Text(title)
                .font(RawDog.Typography.subheadline)
                .foregroundStyle(RawDog.Colors.textPrimary)
            Spacer()
            trailing()
        }
        .listRowBackground(RawDog.Colors.surface)
    }
}
