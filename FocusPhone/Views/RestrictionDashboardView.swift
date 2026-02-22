import SwiftUI

struct RestrictionDashboardView: View {
    @State private var timedWindowApps: [TimedWindowApp] = []
    @State private var showingExtensionRequest = false
    @State private var selectedAppForExtension: String = ""
    @State private var dailyUsed = 0
    @State private var dailyCap = 30

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Status card
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
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(.systemGray5), in: RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 16)
            }
            .navigationTitle("Dashboard")
            .onAppear { refreshData() }
            .sheet(isPresented: $showingExtensionRequest) {
                ExtensionRequestView(appName: selectedAppForExtension)
            }
        }
    }

    // MARK: - Status Card

    private var statusCard: some View {
        VStack(spacing: 8) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 36))
                .foregroundStyle(.blue)

            Text(AppState.shared.isRestrictionActive ? "Your phone is restricted" : "Restrictions inactive")
                .font(.headline)

            if let summary = AppState.shared.restrictionProfile?.onboardingSummary {
                Text(summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    // MARK: - Extension Usage Card

    private var extensionUsageCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Daily Extensions", systemImage: "clock.fill")
                    .font(.subheadline.bold())
                Spacer()
                Text("\(dailyUsed)/\(dailyCap) min")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(dailyUsed >= dailyCap ? .red : .secondary)
            }

            ProgressView(value: dailyCap > 0 ? Double(dailyUsed) / Double(dailyCap) : 0)
                .tint(dailyUsed >= dailyCap ? .red : .blue)
        }
        .padding(16)
        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }

    // MARK: - Timed Windows

    private var timedWindowsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Timed Window Apps")
                .font(.subheadline.bold())
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
                .fill(isOpen ? Color.green : Color.orange)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 2) {
                Text(app.appName)
                    .font(.subheadline.weight(.medium))

                if isOpen, let mins = remaining {
                    Text("Window open — \(mins) min left")
                        .font(.caption)
                        .foregroundStyle(.green)
                } else if let next = nextWindow {
                    Text("Next window: \(next, style: .relative)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("\(app.windowDurationMinutes)min / \(app.cooldownMinutes)min cooldown")
                        .font(.caption)
                        .foregroundStyle(.secondary)
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
                        .foregroundStyle(.blue)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal)
    }

    // MARK: - Permanent Blocks

    private var permanentBlocksSummary: some View {
        let profile = AppState.shared.restrictionProfile

        return VStack(alignment: .leading, spacing: 8) {
            Text("Permanent Blocks")
                .font(.subheadline.bold())
                .padding(.horizontal)

            VStack(alignment: .leading, spacing: 4) {
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
            .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
        }
    }

    private func summaryRow(_ text: String, icon: String) -> some View {
        Label(text, systemImage: icon)
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    // MARK: - Data

    private func refreshData() {
        let appState = AppState.shared
        timedWindowApps = appState.timedWindowStates
        dailyUsed = appState.dailyExtensionMinutesUsed
        dailyCap = appState.restrictionProfile?.dailyExtensionCapMinutes ?? 30
    }
}
