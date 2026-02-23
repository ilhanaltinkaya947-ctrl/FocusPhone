import SwiftUI

struct ProfileReviewView: View {
    let profile: PersonalRestrictionProfile
    let onAccept: () -> Void
    let onBack: () -> Void

    var body: some View {
        ZStack {
            RawDog.Colors.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: RawDog.Spacing.lg) {
                    // Header
                    VStack(spacing: RawDog.Spacing.sm) {
                        RawDogMascot(state: .proud, size: 80)

                        Text("Your Restriction Profile")
                            .font(RawDog.Typography.title2)
                            .foregroundStyle(RawDog.Colors.textPrimary)

                        if let summary = profile.onboardingSummary {
                            Text(summary)
                                .font(RawDog.Typography.subheadline)
                                .foregroundStyle(RawDog.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, RawDog.Spacing.md)

                    // Permanent Blocks
                    if !profile.blockedWebsites.isEmpty || profile.blockAppStore || profile.blockAppDeletion || profile.blockYouTubeNativeApp {
                        profileSection(title: "PERMANENT BLOCKS", icon: "lock.fill", accentColor: RawDog.Colors.destructive) {
                            if profile.blockYouTubeNativeApp {
                                detailRow("YouTube native app", icon: "play.rectangle.fill")
                            }
                            if profile.blockAppStore {
                                detailRow("App Store", icon: "bag.fill")
                            }
                            if profile.blockAppDeletion {
                                detailRow("App deletion", icon: "trash.slash.fill")
                            }
                            ForEach(profile.blockedWebsites, id: \.self) { site in
                                detailRow(site, icon: "globe")
                            }
                        }
                    }

                    // Timed Window Apps
                    if !profile.timedWindowApps.isEmpty {
                        profileSection(title: "TIMED WINDOWS", icon: "timer", accentColor: RawDog.Colors.windowOpen) {
                            ForEach(profile.timedWindowApps) { app in
                                HStack {
                                    Image(systemName: "app.fill")
                                        .font(.caption)
                                        .foregroundStyle(RawDog.Colors.windowOpen.opacity(0.7))
                                        .frame(width: 16)
                                    Text(app.appName)
                                        .font(RawDog.Typography.subheadline)
                                        .foregroundStyle(RawDog.Colors.textPrimary)
                                    Spacer()
                                    Text("\(app.windowDurationMinutes)m")
                                        .font(RawDog.Typography.caption.weight(.semibold))
                                        .foregroundStyle(RawDog.Colors.windowOpen)
                                    Text("/")
                                        .font(RawDog.Typography.caption)
                                        .foregroundStyle(RawDog.Colors.textSecondary)
                                    Text("\(app.cooldownMinutes)m cd")
                                        .font(RawDog.Typography.caption)
                                        .foregroundStyle(RawDog.Colors.textSecondary)
                                }
                            }
                        }
                    }

                    // Content Filters
                    if !profile.browserContentFilters.isEmpty {
                        profileSection(title: "CONTENT FILTERS", icon: "eye.slash", accentColor: RawDog.Colors.accent) {
                            ForEach(profile.browserContentFilters, id: \.self) { filterID in
                                if let preset = ContentFilterPresetStore.preset(for: filterID) {
                                    detailRow(preset.displayName, icon: "line.3.horizontal.decrease")
                                } else {
                                    detailRow(filterID, icon: "line.3.horizontal.decrease")
                                }
                            }
                        }
                    }

                    // Daily Cap
                    profileSection(title: "DAILY EXTENSION CAP", icon: "clock.badge.checkmark", accentColor: RawDog.Colors.windowClosed) {
                        HStack {
                            Image(systemName: "hourglass")
                                .font(.caption)
                                .foregroundStyle(RawDog.Colors.windowClosed.opacity(0.7))
                                .frame(width: 16)
                            Text("\(profile.dailyExtensionCapMinutes) minutes per day")
                                .font(RawDog.Typography.subheadline)
                                .foregroundStyle(RawDog.Colors.textPrimary)
                        }
                    }

                    // Presets
                    if !profile.activePresetIDs.isEmpty {
                        profileSection(title: "ACTIVE PRESETS", icon: "square.stack.fill", accentColor: RawDog.Colors.accent) {
                            ForEach(profile.activePresetIDs, id: \.self) { presetID in
                                if let preset = RestrictionPresets.preset(for: presetID) {
                                    detailRow(preset.displayName, icon: "checkmark.shield.fill")
                                } else {
                                    detailRow(presetID, icon: "checkmark.shield.fill")
                                }
                            }
                        }
                    }

                    Spacer().frame(height: 100)
                }
                .padding(.horizontal, 20)
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 10) {
                RawDog.PillButton(title: "Apply Restrictions") {
                    onAccept()
                }

                Button {
                    onBack()
                } label: {
                    Text("Go Back & Adjust")
                        .font(RawDog.Typography.subheadline.weight(.medium))
                        .foregroundStyle(RawDog.Colors.textSecondary)
                }
            }
            .padding(.horizontal, 32)
            .padding(.top, 12)
            .padding(.bottom, 16)
            .background(
                LinearGradient(
                    colors: [RawDog.Colors.background.opacity(0), RawDog.Colors.background, RawDog.Colors.background],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Helpers

    private func profileSection<Content: View>(
        title: String,
        icon: String,
        accentColor: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: RawDog.Spacing.sm) {
            Label {
                Text(title)
                    .font(RawDog.Typography.caption2)
                    .foregroundStyle(accentColor)
            } icon: {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundStyle(accentColor)
            }

            VStack(alignment: .leading, spacing: 10) {
                content()
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RawDog.Colors.surface, in: RoundedRectangle(cornerRadius: RawDog.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: RawDog.Radius.card)
                    .strokeBorder(accentColor.opacity(0.1), lineWidth: 1)
            )
        }
    }

    private func detailRow(_ text: String, icon: String = "circle.fill") -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(RawDog.Colors.accent.opacity(0.5))
                .frame(width: 16)
            Text(text)
                .font(RawDog.Typography.subheadline)
                .foregroundStyle(RawDog.Colors.textPrimary)
        }
    }
}
