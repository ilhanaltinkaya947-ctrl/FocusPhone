import SwiftUI

struct RestrictionDashboardView: View {
    @State private var timedWindowApps: [TimedWindowApp] = []
    @State private var showingExtensionRequest = false
    @State private var selectedAppForExtension: String = ""
    @State private var dailyUsed = 0
    @State private var dailyCap = 30

    var body: some View {
        NavigationStack {
            ZStack {
                RawDog.Colors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: RawDog.Spacing.md) {
                        // Mascot + status
                        statusCard

                        // Daily extension usage
                        extensionUsageCard

                        // Timed window apps
                        if !timedWindowApps.isEmpty {
                            timedWindowsSection
                        }

                        // Permanent blocks summary
                        permanentBlocksSummary

                        // Extension request button
                        Button {
                            selectedAppForExtension = "General"
                            showingExtensionRequest = true
                        } label: {
                            Label("Request Extension", systemImage: "clock.badge.questionmark")
                                .font(RawDog.Typography.headline)
                                .foregroundStyle(RawDog.Colors.accent)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(RawDog.Colors.surface, in: RoundedRectangle(cornerRadius: RawDog.Radius.card))
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, RawDog.Spacing.md)
                }
            }
            .navigationTitle("RawDog")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear { refreshData() }
            .sheet(isPresented: $showingExtensionRequest) {
                ExtensionRequestView(appName: selectedAppForExtension)
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Status Card

    private var statusCard: some View {
        VStack(spacing: RawDog.Spacing.sm) {
            RawDogMascot(
                state: AppState.shared.isRestrictionActive ? .proud : .neutral,
                size: 100
            )

            Text(AppState.shared.isRestrictionActive ? "Your phone is disciplined" : "Restrictions inactive")
                .font(RawDog.Typography.headline)
                .foregroundStyle(RawDog.Colors.textPrimary)

            if let summary = AppState.shared.restrictionProfile?.onboardingSummary {
                Text(summary)
                    .font(RawDog.Typography.caption)
                    .foregroundStyle(RawDog.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(RawDog.Colors.surface, in: RoundedRectangle(cornerRadius: RawDog.Radius.card))
        .padding(.horizontal)
    }

    // MARK: - Extension Usage Card

    private var extensionUsageCard: some View {
        VStack(alignment: .leading, spacing: RawDog.Spacing.sm) {
            HStack {
                RawDog.SectionHeader(title: "Daily Extensions", icon: "clock.fill")
                Spacer()
                Text("\(dailyUsed)/\(dailyCap) min")
                    .font(RawDog.Typography.caption.weight(.medium))
                    .foregroundStyle(dailyUsed >= dailyCap ? RawDog.Colors.destructive : RawDog.Colors.textSecondary)
            }

            ProgressView(value: dailyCap > 0 ? Double(dailyUsed) / Double(dailyCap) : 0)
                .tint(dailyUsed >= dailyCap ? RawDog.Colors.destructive : RawDog.Colors.accent)
        }
        .padding(RawDog.Spacing.md)
        .background(RawDog.Colors.surface, in: RoundedRectangle(cornerRadius: RawDog.Radius.card))
        .padding(.horizontal)
    }

    // MARK: - Timed Windows

    private var timedWindowsSection: some View {
        VStack(alignment: .leading, spacing: RawDog.Spacing.sm) {
            RawDog.SectionHeader(title: "Timed Windows", icon: "timer")
                .padding(.horizontal)

            ForEach(timedWindowApps) { app in
                timedWindowRow(app)
            }
        }
    }

    private func timedWindowRow(_ app: TimedWindowApp) -> some View {
        let profile = AppState.shared.restrictionProfile
        let slots = profile.map { TimedWindowService.generateAllSlots(for: $0) } ?? []
        let isOpen = TimedWindowService.isWindowOpen(for: app.id, in: slots)
        let remaining = TimedWindowService.remainingTime(for: app.id, in: slots)
        let nextWindow = TimedWindowService.nextWindowTime(for: app.id, in: slots)

        return HStack(spacing: 12) {
            Circle()
                .fill(isOpen ? RawDog.Colors.windowOpen : RawDog.Colors.windowClosed)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 2) {
                Text(app.appName)
                    .font(RawDog.Typography.subheadline.weight(.medium))
                    .foregroundStyle(RawDog.Colors.textPrimary)

                if isOpen, let mins = remaining {
                    Text("Window open — \(mins) min left")
                        .font(RawDog.Typography.caption)
                        .foregroundStyle(RawDog.Colors.windowOpen)
                } else if let next = nextWindow {
                    Text("Next window: \(next, style: .relative)")
                        .font(RawDog.Typography.caption)
                        .foregroundStyle(RawDog.Colors.textSecondary)
                } else {
                    Text("\(app.windowDurationMinutes)min / \(app.cooldownMinutes)min cooldown")
                        .font(RawDog.Typography.caption)
                        .foregroundStyle(RawDog.Colors.textSecondary)
                }
            }

            Spacer()

            if !isOpen {
                Button {
                    selectedAppForExtension = app.appName
                    showingExtensionRequest = true
                } label: {
                    Image(systemName: "clock.badge.questionmark")
                        .font(.caption)
                        .foregroundStyle(RawDog.Colors.accent)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, RawDog.Spacing.sm)
        .background(RawDog.Colors.surface, in: RoundedRectangle(cornerRadius: RawDog.Radius.small))
        .padding(.horizontal)
    }

    // MARK: - Permanent Blocks

    private var permanentBlocksSummary: some View {
        let profile = AppState.shared.restrictionProfile

        return VStack(alignment: .leading, spacing: RawDog.Spacing.sm) {
            RawDog.SectionHeader(title: "Permanent Blocks", icon: "lock.fill")
                .padding(.horizontal)

            VStack(alignment: .leading, spacing: RawDog.Spacing.xs) {
                if profile?.blockYouTubeNativeApp == true {
                    summaryRow("YouTube native app", icon: "play.rectangle.fill")
                }
                if profile?.blockAppStore == true {
                    summaryRow("App Store", icon: "bag.fill")
                }
                if profile?.blockAppDeletion == true {
                    summaryRow("App deletion", icon: "trash.fill")
                }
                let sites = profile?.blockedWebsites ?? []
                if !sites.isEmpty {
                    summaryRow("\(sites.count) websites", icon: "globe")
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RawDog.Colors.surface, in: RoundedRectangle(cornerRadius: RawDog.Radius.card))
            .padding(.horizontal)
        }
    }

    private func summaryRow(_ text: String, icon: String) -> some View {
        Label(text, systemImage: icon)
            .font(RawDog.Typography.caption)
            .foregroundStyle(RawDog.Colors.textSecondary)
    }

    // MARK: - Data

    private func refreshData() {
        let appState = AppState.shared
        timedWindowApps = appState.timedWindowStates
        dailyUsed = appState.dailyExtensionMinutesUsed
        dailyCap = appState.restrictionProfile?.dailyExtensionCapMinutes ?? 30
    }
}
