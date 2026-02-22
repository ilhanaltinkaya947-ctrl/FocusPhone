import SwiftUI

struct CommitmentDetailView: View {
    let commitment: Commitment
    @ObservedObject var viewModel: CommitmentViewModel

    private var stats: HabitStats {
        viewModel.statsFor(commitment)
    }

    private var recentLogs: [CommitmentLog] {
        Array(CommitmentStore.logsForCommitment(id: commitment.id).prefix(14))
    }

    var body: some View {
        ZStack {
            RawDog.Colors.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: RawDog.Spacing.lg) {
                    headerSection
                    statsCard
                    weekdayBreakdownCard
                    recentHistoryCard
                    actionsSection
                }
                .padding()
            }
        }
        .navigationTitle(commitment.title)
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: RawDog.Spacing.sm) {
            Text(commitment.emoji)
                .font(.system(size: 56))

            Text(commitment.category.displayName)
                .font(RawDog.Typography.caption)
                .foregroundStyle(RawDog.Colors.textSecondary)

            if let status = viewModel.todayStatus(for: commitment) {
                RawDog.StatusBadge(
                    text: status.rawValue.capitalized,
                    icon: status == .verified ? "checkmark.circle" : "clock",
                    color: status == .verified ? RawDog.Colors.approved : RawDog.Colors.textSecondary
                )
            }
        }
    }

    // MARK: - Stats Card

    private var statsCard: some View {
        RawDog.Card {
            RawDog.SectionHeader(title: "Stats", icon: "chart.bar")

            HStack(spacing: RawDog.Spacing.lg) {
                statItem(value: "\(stats.currentStreak)", label: "Streak")
                statItem(value: "\(stats.bestStreak)", label: "Best")
                statItem(value: "\(Int(stats.completionRate * 100))%", label: "Rate")
                statItem(value: trendLabel, label: "Trend")
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(RawDog.Typography.title2)
                .foregroundStyle(RawDog.Colors.accent)

            Text(label)
                .font(RawDog.Typography.caption2)
                .foregroundStyle(RawDog.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var trendLabel: String {
        switch stats.trend {
        case .improving: return "Up"
        case .declining: return "Down"
        case .steady: return "Steady"
        }
    }

    // MARK: - Weekday Breakdown

    private var weekdayBreakdownCard: some View {
        RawDog.Card {
            RawDog.SectionHeader(title: "By Day", icon: "calendar")

            let dayLabels = ["", "S", "M", "T", "W", "T", "F", "S"]
            let maxCount = stats.weekdayBreakdown.values.max() ?? 1

            HStack(alignment: .bottom, spacing: RawDog.Spacing.sm) {
                ForEach(1...7, id: \.self) { weekday in
                    let count = stats.weekdayBreakdown[weekday] ?? 0
                    let height = maxCount > 0 ? CGFloat(count) / CGFloat(maxCount) * 60 : 0

                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(RawDog.Colors.accent.opacity(count > 0 ? 1 : 0.2))
                            .frame(width: 24, height: max(4, height))

                        Text(dayLabels[weekday])
                            .font(RawDog.Typography.caption2)
                            .foregroundStyle(RawDog.Colors.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 80, alignment: .bottom)
        }
    }

    // MARK: - Recent History

    private var recentHistoryCard: some View {
        RawDog.Card {
            RawDog.SectionHeader(title: "Recent", icon: "clock.arrow.circlepath")

            if recentLogs.isEmpty {
                Text("No logs yet")
                    .font(RawDog.Typography.caption)
                    .foregroundStyle(RawDog.Colors.textSecondary)
            } else {
                ForEach(recentLogs) { log in
                    HStack {
                        statusIcon(log.status)

                        Text(dateString(log.date))
                            .font(RawDog.Typography.subheadline)
                            .foregroundStyle(RawDog.Colors.textPrimary)

                        Spacer()

                        if let result = log.aiVerificationResult {
                            Text("\(Int(result.confidence * 100))%")
                                .font(RawDog.Typography.caption)
                                .foregroundStyle(RawDog.Colors.textSecondary)
                        }

                        if let filename = log.photoFilename,
                           let photo = CommitmentStore.loadPhoto(filename: filename) {
                            Image(uiImage: photo)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 32, height: 32)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                    }
                    .padding(.vertical, 4)

                    if log.id != recentLogs.last?.id {
                        Divider()
                            .background(RawDog.Colors.surfaceElevated)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func statusIcon(_ status: CommitmentLogStatus) -> some View {
        switch status {
        case .verified:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(RawDog.Colors.approved)
        case .failed:
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(RawDog.Colors.destructive)
        case .skipped:
            Image(systemName: "forward.fill")
                .foregroundStyle(RawDog.Colors.textSecondary)
        case .pending:
            Image(systemName: "clock")
                .foregroundStyle(RawDog.Colors.windowClosed)
        }
    }

    private func dateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    // MARK: - Actions

    private var actionsSection: some View {
        VStack(spacing: RawDog.Spacing.sm) {
            RawDog.PillButton(title: commitment.isActive ? "Pause" : "Resume", style: .secondary) {
                viewModel.toggleActive(commitment)
            }

            RawDog.PillButton(title: "Delete", style: .destructive) {
                viewModel.deleteCommitment(commitment)
            }
        }
    }
}
