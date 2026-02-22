import SwiftUI

struct ProfileReviewView: View {
    let profile: PersonalRestrictionProfile
    let onAccept: () -> Void
    let onBack: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "shield.checkered")
                        .font(.system(size: 48))
                        .foregroundStyle(.blue)
                    Text("Your Restriction Profile")
                        .font(.title2.bold())
                    if let summary = profile.onboardingSummary {
                        Text(summary)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 8)

                // Permanent Blocks
                if !profile.blockedWebsites.isEmpty || profile.blockAppStore || profile.blockAppDeletion || profile.blockYouTubeNativeApp {
                    profileSection(title: "Permanent Blocks", icon: "lock.fill", color: .red) {
                        if profile.blockYouTubeNativeApp {
                            detailRow("YouTube native app blocked")
                        }
                        if profile.blockAppStore {
                            detailRow("App Store blocked")
                        }
                        if profile.blockAppDeletion {
                            detailRow("App deletion blocked")
                        }
                        ForEach(profile.blockedWebsites, id: \.self) { site in
                            detailRow(site)
                        }
                    }
                }

                // Timed Window Apps
                if !profile.timedWindowApps.isEmpty {
                    profileSection(title: "Timed Window Apps", icon: "timer", color: .orange) {
                        ForEach(profile.timedWindowApps) { app in
                            HStack {
                                Text(app.appName)
                                    .font(.subheadline)
                                Spacer()
                                Text("\(app.windowDurationMinutes)min / \(app.cooldownMinutes)min cooldown")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                // Content Filters
                if !profile.browserContentFilters.isEmpty {
                    profileSection(title: "Browser Content Filters", icon: "eye.slash", color: .purple) {
                        ForEach(profile.browserContentFilters, id: \.self) { filterID in
                            if let preset = ContentFilterPresetStore.preset(for: filterID) {
                                detailRow(preset.displayName)
                            } else {
                                detailRow(filterID)
                            }
                        }
                    }
                }

                // Daily Cap
                profileSection(title: "Daily Extension Cap", icon: "clock.badge.checkmark", color: .green) {
                    detailRow("\(profile.dailyExtensionCapMinutes) minutes per day")
                }

                // Presets
                if !profile.activePresetIDs.isEmpty {
                    profileSection(title: "Active Presets", icon: "square.stack.fill", color: .blue) {
                        ForEach(profile.activePresetIDs, id: \.self) { presetID in
                            if let preset = RestrictionPresets.preset(for: presetID) {
                                detailRow(preset.displayName)
                            } else {
                                detailRow(presetID)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 12) {
                Button {
                    onAccept()
                } label: {
                    Text("Apply Restrictions")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Button {
                    onBack()
                } label: {
                    Text("Go Back & Adjust")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.blue)
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 16)
            .background(.ultraThinMaterial)
        }
    }

    // MARK: - Helpers

    private func profileSection<Content: View>(title: String, icon: String, color: Color, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.subheadline.bold())
                .foregroundStyle(color)
            VStack(alignment: .leading, spacing: 4) {
                content()
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 10))
        }
    }

    private func detailRow(_ text: String) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(.secondary)
                .frame(width: 4, height: 4)
            Text(text)
                .font(.subheadline)
        }
    }
}
