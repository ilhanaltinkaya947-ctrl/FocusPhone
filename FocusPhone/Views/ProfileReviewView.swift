import SwiftUI

struct ProfileReviewView: View {
    let profile: PersonalRestrictionProfile
    let onAccept: () -> Void
    let onBack: () -> Void

    var body: some View {
        ZStack {
            RawDog.Colors.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(spacing: RawDog.Spacing.sm) {
                        RawDogMascot(state: .neutral, size: 80)

                        Text("Your Restriction Profile")
                            .font(RawDog.Typography.title2)
                            .foregroundStyle(RawDog.Colors.textPrimary)

                        if let summary = profile.onboardingSummary {
                            Text(summary)
                                .font(RawDog.Typography.subheadline)
                                .foregroundStyle(RawDog.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, RawDog.Spacing.sm)

                    // Permanent Blocks
                    if !profile.blockedWebsites.isEmpty || profile.blockAppStore || profile.blockAppDeletion || profile.blockYouTubeNativeApp {
                        profileSection(title: "Permanent Blocks", icon: "lock.fill") {
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
                        profileSection(title: "Timed Window Apps", icon: "timer") {
                            ForEach(profile.timedWindowApps) { app in
                                HStack {
                                    Text(app.appName)
                                        .font(RawDog.Typography.subheadline)
                                        .foregroundStyle(RawDog.Colors.textPrimary)
                                    Spacer()
                                    Text("\(app.windowDurationMinutes)min / \(app.cooldownMinutes)min cooldown")
                                        .font(RawDog.Typography.caption)
                                        .foregroundStyle(RawDog.Colors.textSecondary)
                                }
                            }
                        }
                    }

                    // Content Filters
                    if !profile.browserContentFilters.isEmpty {
                        profileSection(title: "Browser Content Filters", icon: "eye.slash") {
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
                    profileSection(title: "Daily Extension Cap", icon: "clock.badge.checkmark") {
                        detailRow("\(profile.dailyExtensionCapMinutes) minutes per day")
                    }

                    // Presets
                    if !profile.activePresetIDs.isEmpty {
                        profileSection(title: "Active Presets", icon: "square.stack.fill") {
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
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 12) {
                RawDog.PillButton(title: "Apply Restrictions") {
                    onAccept()
                }

                Button {
                    onBack()
                } label: {
                    Text("Go Back & Adjust")
                        .font(RawDog.Typography.subheadline.weight(.medium))
                        .foregroundStyle(RawDog.Colors.accent)
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 16)
            .background(RawDog.Colors.background.opacity(0.95))
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Helpers

    private func profileSection<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: RawDog.Spacing.sm) {
            RawDog.SectionHeader(title: title, icon: icon)

            VStack(alignment: .leading, spacing: RawDog.Spacing.xs) {
                content()
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RawDog.Colors.surface, in: RoundedRectangle(cornerRadius: RawDog.Radius.small))
        }
    }

    private func detailRow(_ text: String) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(RawDog.Colors.accent.opacity(0.5))
                .frame(width: 4, height: 4)
            Text(text)
                .font(RawDog.Typography.subheadline)
                .foregroundStyle(RawDog.Colors.textPrimary)
        }
    }
}
