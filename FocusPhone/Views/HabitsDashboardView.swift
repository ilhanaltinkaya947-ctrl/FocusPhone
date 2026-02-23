import SwiftUI

struct HabitsDashboardView: View {
    @State private var weeklyInsight: WeeklyInsight?
    @State private var isLoadingInsight = false
    @State private var insightError: String?

    private var commitments: [Commitment] {
        CommitmentStore.commitments.filter { $0.isActive }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                RawDog.Colors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: RawDog.Spacing.lg) {
                        // Mascot
                        RawDogMascot(state: .neutral, size: 80)
                            .padding(.top, RawDog.Spacing.sm)

                        Text("YOUR RECEIPTS")
                            .font(RawDog.Typography.title2)
                            .foregroundStyle(RawDog.Colors.accent)

                        if commitments.isEmpty {
                            emptyState
                        } else {
                            // Per-commitment cards
                            ForEach(commitments) { commitment in
                                commitmentReceiptCard(commitment)
                            }

                            // Photo strip
                            photoStripSection

                            // Weekly AI insight
                            insightCard
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Receipts")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { loadInsightIfNeeded() }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: RawDog.Spacing.md) {
            Text("No active commitments")
                .font(RawDog.Typography.headline)
                .foregroundStyle(RawDog.Colors.textSecondary)

            Text("Add commitments in the Commit tab to see your receipts here.")
                .font(RawDog.Typography.caption)
                .foregroundStyle(RawDog.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, RawDog.Spacing.xl)
    }

    // MARK: - Commitment Receipt Card

    private func commitmentReceiptCard(_ commitment: Commitment) -> some View {
        let habitStats = CommitmentStore.stats(for: commitment.id)

        return RawDog.Card {
            VStack(alignment: .leading, spacing: RawDog.Spacing.md) {
                // Header
                HStack {
                    Text(commitment.emoji)
                        .font(.system(size: 28))
                    Text(commitment.title)
                        .font(RawDog.Typography.headline)
                        .foregroundStyle(RawDog.Colors.textPrimary)
                    Spacer()
                    trendBadge(habitStats.trend)
                }

                // Week bubbles (last 7 days)
                weekBubbles(for: commitment)

                // Stats row
                HStack(spacing: RawDog.Spacing.lg) {
                    miniStat(value: "\(habitStats.currentStreak)", label: "Streak")
                    miniStat(value: "\(Int(habitStats.completionRate * 100))%", label: "Rate")
                    miniStat(value: "\(habitStats.bestStreak)", label: "Best")
                    miniStat(value: "\(habitStats.totalVerified)", label: "Total")
                }
            }
        }
    }

    private func weekBubbles(for commitment: Commitment) -> some View {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let logs = CommitmentStore.logsForCommitment(id: commitment.id)
        let dayLabels = ["S", "M", "T", "W", "T", "F", "S"]

        return HStack(spacing: RawDog.Spacing.sm) {
            ForEach(0..<7, id: \.self) { offset in
                let day = calendar.date(byAdding: .day, value: -(6 - offset), to: today)!
                let weekday = calendar.component(.weekday, from: day)
                let log = logs.first {
                    calendar.isDate($0.date, inSameDayAs: day)
                }

                VStack(spacing: 4) {
                    Text(dayLabels[weekday - 1])
                        .font(RawDog.Typography.caption2)
                        .foregroundStyle(RawDog.Colors.textSecondary)

                    Circle()
                        .fill(bubbleColor(for: log?.status))
                        .frame(width: 28, height: 28)
                        .overlay {
                            if log?.status == .verified {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(RawDog.Colors.background)
                            }
                        }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func bubbleColor(for status: CommitmentLogStatus?) -> Color {
        switch status {
        case .verified: return RawDog.Colors.approved
        case .failed: return RawDog.Colors.destructive
        case .skipped: return RawDog.Colors.textSecondary.opacity(0.4)
        case .pending: return RawDog.Colors.windowClosed.opacity(0.5)
        case .none: return RawDog.Colors.surfaceElevated
        }
    }

    private func trendBadge(_ trend: HabitTrend) -> some View {
        HStack(spacing: 2) {
            Image(systemName: trendIcon(trend))
                .font(.system(size: 10))
            Text(trendLabel(trend))
                .font(RawDog.Typography.caption2)
        }
        .foregroundStyle(trendColor(trend))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(trendColor(trend).opacity(0.15), in: Capsule())
    }

    private func trendIcon(_ trend: HabitTrend) -> String {
        switch trend {
        case .improving: return "arrow.up.right"
        case .declining: return "arrow.down.right"
        case .steady: return "arrow.right"
        }
    }

    private func trendLabel(_ trend: HabitTrend) -> String {
        switch trend {
        case .improving: return "Up"
        case .declining: return "Down"
        case .steady: return "Steady"
        }
    }

    private func trendColor(_ trend: HabitTrend) -> Color {
        switch trend {
        case .improving: return RawDog.Colors.approved
        case .declining: return RawDog.Colors.destructive
        case .steady: return RawDog.Colors.textSecondary
        }
    }

    private func miniStat(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(RawDog.Typography.headline)
                .foregroundStyle(RawDog.Colors.accent)
            Text(label)
                .font(RawDog.Typography.caption2)
                .foregroundStyle(RawDog.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Photo Strip

    private var photoStripSection: some View {
        let recentPhotos = recentVerifiedPhotos(limit: 5)

        return Group {
            if !recentPhotos.isEmpty {
                RawDog.Card {
                    VStack(alignment: .leading, spacing: RawDog.Spacing.sm) {
                        RawDog.SectionHeader(title: "Proof", icon: "photo.stack")

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: RawDog.Spacing.sm) {
                                ForEach(recentPhotos, id: \.0) { filename, image in
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 80, height: 80)
                                        .clipShape(RoundedRectangle(cornerRadius: RawDog.Radius.small))
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func recentVerifiedPhotos(limit: Int) -> [(String, UIImage)] {
        let allLogs = CommitmentStore.logs
            .filter { $0.status == .verified && $0.photoFilename != nil }
            .sorted { $0.date > $1.date }
            .prefix(limit)

        return allLogs.compactMap { log in
            guard let filename = log.photoFilename,
                  let image = CommitmentStore.loadPhoto(filename: filename) else { return nil }
            return (filename, image)
        }
    }

    // MARK: - Weekly AI Insight

    private var insightCard: some View {
        RawDog.Card {
            VStack(alignment: .leading, spacing: RawDog.Spacing.md) {
                RawDog.SectionHeader(title: "Weekly Insight", icon: "brain.head.profile")

                if isLoadingInsight {
                    HStack(spacing: RawDog.Spacing.sm) {
                        ProgressView()
                            .tint(RawDog.Colors.accent)
                        Text("RawDog is analyzing your week...")
                            .font(RawDog.Typography.caption)
                            .foregroundStyle(RawDog.Colors.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, RawDog.Spacing.md)
                } else if let insight = weeklyInsight {
                    Text(insight.headline)
                        .font(RawDog.Typography.headline)
                        .foregroundStyle(RawDog.Colors.accent)

                    Text(insight.insight)
                        .font(RawDog.Typography.body)
                        .foregroundStyle(RawDog.Colors.textPrimary)

                    if let adjustment = insight.adjustment {
                        HStack(alignment: .top, spacing: RawDog.Spacing.sm) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundStyle(RawDog.Colors.accent)
                                .font(.system(size: 14))
                            Text(adjustment)
                                .font(RawDog.Typography.caption)
                                .foregroundStyle(RawDog.Colors.textSecondary)
                        }
                    }

                    if let milestone = insight.milestone {
                        HStack(spacing: RawDog.Spacing.sm) {
                            Image(systemName: "trophy.fill")
                                .foregroundStyle(RawDog.Colors.approved)
                                .font(.system(size: 14))
                            Text(milestone)
                                .font(RawDog.Typography.caption)
                                .foregroundStyle(RawDog.Colors.approved)
                        }
                    }
                } else if let error = insightError {
                    Text(error)
                        .font(RawDog.Typography.caption)
                        .foregroundStyle(RawDog.Colors.destructive)

                    RawDog.PillButton(title: "Retry", style: .secondary) {
                        loadInsight()
                    }
                } else {
                    Text("Tap to generate your weekly insight.")
                        .font(RawDog.Typography.caption)
                        .foregroundStyle(RawDog.Colors.textSecondary)

                    RawDog.PillButton(title: "Generate Insight", style: .secondary) {
                        loadInsight()
                    }
                }
            }
        }
    }

    // MARK: - Data Loading

    private func loadInsightIfNeeded() {
        // Auto-load if we have commitments with logs and no cached insight
        guard weeklyInsight == nil, !commitments.isEmpty else { return }
        let hasLogs = commitments.contains { !CommitmentStore.logsForCommitment(id: $0.id).isEmpty }
        guard hasLogs else { return }
        loadInsight()
    }

    private func loadInsight() {
        isLoadingInsight = true
        insightError = nil

        var statsDict: [String: HabitStats] = [:]
        for commitment in commitments {
            statsDict[commitment.title] = CommitmentStore.stats(for: commitment.id)
        }

        Task {
            do {
                let insight = try await GroqService.shared.generateWeeklyInsights(stats: statsDict)
                await MainActor.run {
                    weeklyInsight = insight
                    isLoadingInsight = false
                }
            } catch {
                await MainActor.run {
                    insightError = error.localizedDescription
                    isLoadingInsight = false
                }
            }
        }
    }
}
