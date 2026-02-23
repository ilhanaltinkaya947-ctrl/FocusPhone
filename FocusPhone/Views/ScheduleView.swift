import SwiftUI

struct ScheduleView: View {
    @StateObject private var commitmentVM = CommitmentViewModel()
    @State private var todayCommitments: [Commitment] = []
    @State private var timedWindowApps: [TimedWindowApp] = []
    @State private var showingExtensionRequest = false
    @State private var selectedAppForExtension = ""
    @State private var dailyUsed = 0
    @State private var dailyCap = 30
    @State private var showingCreateCommitment = false

    private let calendar = Calendar.current

    var body: some View {
        NavigationStack {
            ZStack {
                RawDog.Colors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: RawDog.Spacing.md) {
                        // Hero card
                        heroCard

                        // Today's commitment timeline
                        if !todayCommitments.isEmpty {
                            timelineSection
                        }

                        // Timed windows
                        if !timedWindowApps.isEmpty {
                            timedWindowsSection
                        }

                        // Extension cap
                        extensionCapCard

                        // Tomorrow preview
                        tomorrowPreview

                        Spacer().frame(height: 20)
                    }
                    .padding(.vertical, RawDog.Spacing.md)
                }
            }
            .navigationTitle(dateHeader)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingCreateCommitment = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(RawDog.Colors.accent)
                    }
                }
            }
            .onAppear { refreshData() }
            .sheet(isPresented: $showingExtensionRequest) {
                ExtensionRequestView(appName: selectedAppForExtension)
            }
            .sheet(isPresented: $showingCreateCommitment) {
                CreateCommitmentView(viewModel: commitmentVM)
            }
            .onChange(of: showingCreateCommitment) {
                if !showingCreateCommitment { refreshData() }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Date Header

    private var dateHeader: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: Date())
    }

    // MARK: - Hero Card

    private var heroCard: some View {
        let total = todayCommitments.count
        let done = todayCommitments.filter { todayStatus(for: $0) == .verified }.count
        let allDone = total > 0 && done == total

        return VStack(spacing: RawDog.Spacing.sm) {
            RawDogMascot(
                state: allDone ? .proud : (AppState.shared.isRestrictionActive ? .neutral : .sideeye),
                size: 80
            )

            if total == 0 {
                Text("No commitments today")
                    .font(RawDog.Typography.headline)
                    .foregroundStyle(RawDog.Colors.textPrimary)
                Text("Tap + to add one")
                    .font(RawDog.Typography.caption)
                    .foregroundStyle(RawDog.Colors.textSecondary)
            } else if allDone {
                Text("All done. You earned it.")
                    .font(RawDog.Typography.headline)
                    .foregroundStyle(RawDog.Colors.approved)
            } else {
                Text("\(done)/\(total) verified today")
                    .font(RawDog.Typography.headline)
                    .foregroundStyle(RawDog.Colors.textPrimary)

                // Progress ring
                ProgressView(value: total > 0 ? Double(done) / Double(total) : 0)
                    .tint(RawDog.Colors.accent)
                    .padding(.horizontal, 40)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(RawDog.Colors.surface, in: RoundedRectangle(cornerRadius: RawDog.Radius.card))
        .overlay(
            allDone
                ? RoundedRectangle(cornerRadius: RawDog.Radius.card)
                    .strokeBorder(RawDog.Colors.approved.opacity(0.3), lineWidth: 1)
                : nil
        )
        .padding(.horizontal)
    }

    // MARK: - Timeline Section

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: RawDog.Spacing.sm) {
            RawDog.SectionHeader(title: "Today's Schedule", icon: "calendar")
                .padding(.horizontal)

            ForEach(sortedCommitments) { commitment in
                timelineRow(commitment)
            }
        }
    }

    private var sortedCommitments: [Commitment] {
        todayCommitments.sorted {
            let h0 = $0.scheduledHour * 60 + $0.scheduledMinute
            let h1 = $1.scheduledHour * 60 + $1.scheduledMinute
            return h0 < h1
        }
    }

    private func timelineRow(_ commitment: Commitment) -> some View {
        let status = todayStatus(for: commitment)
        let isNow = isActiveNow(commitment)

        return HStack(spacing: 12) {
            // Time column
            VStack(spacing: 2) {
                Text(timeString(for: commitment))
                    .font(RawDog.Typography.caption.weight(.semibold).monospacedDigit())
                    .foregroundStyle(isNow ? RawDog.Colors.accent : RawDog.Colors.textSecondary)
            }
            .frame(width: 50)

            // Status indicator line
            VStack(spacing: 0) {
                Circle()
                    .fill(statusColor(status, isNow: isNow))
                    .frame(width: 10, height: 10)
                    .overlay(
                        isNow
                            ? Circle()
                                .stroke(RawDog.Colors.accent.opacity(0.4), lineWidth: 3)
                                .frame(width: 18, height: 18)
                            : nil
                    )
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(commitment.emoji)
                        .font(.callout)
                    Text(commitment.title)
                        .font(RawDog.Typography.subheadline.weight(.medium))
                        .foregroundStyle(RawDog.Colors.textPrimary)
                    Spacer()
                    statusBadge(status)
                }

                // Photo thumbnail if verified
                if status == .verified,
                   let log = CommitmentStore.todayLog(for: commitment.id),
                   let filename = log.photoFilename,
                   let image = CommitmentStore.loadPhoto(filename: filename) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 48, height: 48)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                // Streak info
                let streak = CommitmentStore.stats(for: commitment.id).currentStreak
                if streak > 0 {
                    Text("\(streak) day streak")
                        .font(RawDog.Typography.caption2)
                        .foregroundStyle(RawDog.Colors.textSecondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            isNow
                ? RawDog.Colors.accent.opacity(0.05)
                : Color.clear
        )
        .background(RawDog.Colors.surface, in: RoundedRectangle(cornerRadius: RawDog.Radius.small))
        .overlay(
            isNow
                ? RoundedRectangle(cornerRadius: RawDog.Radius.small)
                    .strokeBorder(RawDog.Colors.accent.opacity(0.2), lineWidth: 1)
                : nil
        )
        .padding(.horizontal)
    }

    // MARK: - Timed Windows

    private var timedWindowsSection: some View {
        VStack(alignment: .leading, spacing: RawDog.Spacing.sm) {
            RawDog.SectionHeader(title: "App Windows", icon: "timer")
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

        return HStack(spacing: 12) {
            Circle()
                .fill(isOpen ? RawDog.Colors.windowOpen : RawDog.Colors.windowClosed)
                .frame(width: 8, height: 8)

            Text(app.appName)
                .font(RawDog.Typography.subheadline.weight(.medium))
                .foregroundStyle(RawDog.Colors.textPrimary)

            Spacer()

            if isOpen, let mins = remaining {
                Text("\(mins)m left")
                    .font(RawDog.Typography.caption.weight(.medium))
                    .foregroundStyle(RawDog.Colors.windowOpen)
            } else {
                Button {
                    selectedAppForExtension = app.appName
                    showingExtensionRequest = true
                } label: {
                    Text("Request")
                        .font(RawDog.Typography.caption2)
                        .foregroundStyle(RawDog.Colors.accent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(RawDog.Colors.accent.opacity(0.1), in: Capsule())
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(RawDog.Colors.surface, in: RoundedRectangle(cornerRadius: RawDog.Radius.small))
        .padding(.horizontal)
    }

    // MARK: - Extension Cap

    private var extensionCapCard: some View {
        HStack {
            RawDog.SectionHeader(title: "Extensions", icon: "clock.fill")
            Spacer()
            Text("\(dailyUsed)/\(dailyCap)m")
                .font(RawDog.Typography.caption.weight(.medium).monospacedDigit())
                .foregroundStyle(dailyUsed >= dailyCap ? RawDog.Colors.destructive : RawDog.Colors.textSecondary)
        }
        .padding(RawDog.Spacing.md)
        .background(RawDog.Colors.surface, in: RoundedRectangle(cornerRadius: RawDog.Radius.card))
        .padding(.horizontal)
    }

    // MARK: - Tomorrow Preview

    private var tomorrowPreview: some View {
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let tomorrowWeekday = calendar.component(.weekday, from: tomorrow)
        let tomorrowCommitments = CommitmentStore.commitments
            .filter { $0.isActive && $0.scheduledDays.contains(tomorrowWeekday) }
            .sorted { $0.scheduledHour * 60 + $0.scheduledMinute < $1.scheduledHour * 60 + $1.scheduledMinute }

        return Group {
            if !tomorrowCommitments.isEmpty {
                VStack(alignment: .leading, spacing: RawDog.Spacing.sm) {
                    RawDog.SectionHeader(title: "Tomorrow", icon: "arrow.right.circle")
                        .padding(.horizontal)

                    HStack(spacing: 10) {
                        ForEach(tomorrowCommitments) { c in
                            HStack(spacing: 4) {
                                Text(c.emoji)
                                    .font(.caption2)
                                Text(timeString(for: c))
                                    .font(RawDog.Typography.caption2)
                                    .foregroundStyle(RawDog.Colors.textSecondary)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(RawDog.Colors.surfaceElevated, in: Capsule())
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    // MARK: - Helpers

    private func todayStatus(for commitment: Commitment) -> CommitmentLogStatus? {
        CommitmentStore.todayLog(for: commitment.id)?.status
    }

    private func isActiveNow(_ commitment: Commitment) -> Bool {
        let now = Date()
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        let currentMinutes = hour * 60 + minute
        let commitMinutes = commitment.scheduledHour * 60 + commitment.scheduledMinute
        // Active window: 30 min before to 30 min after
        return currentMinutes >= (commitMinutes - 30) && currentMinutes <= (commitMinutes + 30)
    }

    private func timeString(for commitment: Commitment) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: commitment.scheduledTime)
    }

    private func statusColor(_ status: CommitmentLogStatus?, isNow: Bool) -> Color {
        switch status {
        case .verified: return RawDog.Colors.approved
        case .failed: return RawDog.Colors.destructive
        case .pending, .skipped, nil:
            return isNow ? RawDog.Colors.accent : RawDog.Colors.surfaceElevated
        }
    }

    @ViewBuilder
    private func statusBadge(_ status: CommitmentLogStatus?) -> some View {
        switch status {
        case .verified:
            Label("Done", systemImage: "checkmark")
                .font(RawDog.Typography.caption2)
                .foregroundStyle(RawDog.Colors.approved)
        case .failed:
            Label("Missed", systemImage: "xmark")
                .font(RawDog.Typography.caption2)
                .foregroundStyle(RawDog.Colors.destructive)
        case .pending:
            Text("Pending")
                .font(RawDog.Typography.caption2)
                .foregroundStyle(RawDog.Colors.textSecondary)
        default:
            EmptyView()
        }
    }

    private func refreshData() {
        let appState = AppState.shared
        let todayWeekday = calendar.component(.weekday, from: Date())
        todayCommitments = CommitmentStore.commitments
            .filter { $0.isActive && $0.scheduledDays.contains(todayWeekday) }
        timedWindowApps = appState.timedWindowStates
        dailyUsed = appState.dailyExtensionMinutesUsed
        dailyCap = appState.restrictionProfile?.dailyExtensionCapMinutes ?? 30
    }
}
