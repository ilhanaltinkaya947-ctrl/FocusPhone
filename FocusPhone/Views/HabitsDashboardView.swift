import SwiftUI

struct HabitsDashboardView: View {
    @State private var weeklyInsight: WeeklyInsight?
    @State private var isLoadingInsight = false
    @State private var insightError: String?
    @State private var heatmapData: [Date: DayStatus] = [:]

    private var commitments: [Commitment] {
        CommitmentStore.commitments.filter { $0.isActive }
    }

    private var monthlyStats: MonthlyRetentionStats {
        RetentionService.shared.calculateMonthlyStats()
    }

    private var monthlyProgress: Double {
        guard monthlyStats.totalScheduled > 0 else { return 0 }
        return Double(monthlyStats.commitmentsCompleted) / Double(monthlyStats.totalScheduled)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                RawDog.Colors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: RawDog.Spacing.lg) {
                        if commitments.isEmpty {
                            emptyState
                        } else {
                            // Monthly overview ring
                            monthlyRing

                            // Per-commitment breakdown
                            commitmentBreakdown

                            // Photo gallery
                            photoGallery

                            // Heatmap (last 90 days)
                            heatmapSection

                            // Weekly AI insight
                            insightCard
                        }
                    }
                    .padding()
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Receipts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear {
                loadInsightIfNeeded()
                buildHeatmap()
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: RawDog.Spacing.md) {
            Text("No active commitments")
                .font(RawDog.Typography.headline)
                .foregroundStyle(RawDog.Colors.textSecondary)

            Text("Add commitments in the Commit tab\nto see your receipts here.")
                .font(RawDog.Typography.caption)
                .foregroundStyle(RawDog.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, RawDog.Spacing.xl)
    }

    // MARK: - Monthly Overview Ring

    private var monthlyRing: some View {
        VStack(spacing: RawDog.Spacing.sm) {
            ZStack {
                Circle()
                    .stroke(RawDog.Colors.trackBackground, lineWidth: 8)
                    .frame(width: 160, height: 160)

                Circle()
                    .trim(from: 0, to: monthlyProgress)
                    .stroke(
                        RawDog.Colors.accentIce,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 2) {
                    Text("\(monthlyStats.completionPercentage)%")
                        .font(RawDog.Typography.title)
                        .foregroundStyle(RawDog.Colors.textPrimary)
                    Text("this month")
                        .font(RawDog.Typography.caption2)
                        .foregroundStyle(RawDog.Colors.textSecondary)
                }
            }

            Text(monthName)
                .font(RawDog.Typography.caption)
                .foregroundStyle(RawDog.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Per-Commitment Breakdown

    private var commitmentBreakdown: some View {
        VStack(alignment: .leading, spacing: RawDog.Spacing.sm) {
            RawDog.SectionHeader(title: "Breakdown", icon: "list.bullet")

            ForEach(commitments) { commitment in
                let habitStats = CommitmentStore.stats(for: commitment.id)

                HStack(spacing: 12) {
                    Text(commitment.emoji)
                        .font(.title3)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(commitment.title)
                            .font(RawDog.Typography.subheadline.weight(.medium))
                            .foregroundStyle(RawDog.Colors.textPrimary)

                        // Mini completion bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(RawDog.Colors.trackBackground)
                                    .frame(height: 4)

                                Capsule()
                                    .fill(RawDog.Colors.accentIce)
                                    .frame(width: geo.size.width * habitStats.completionRate, height: 4)
                            }
                        }
                        .frame(height: 4)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(habitStats.currentStreak)d")
                            .font(RawDog.Typography.headline)
                            .foregroundStyle(RawDog.Colors.accentIce)
                        Text("streak")
                            .font(RawDog.Typography.caption2)
                            .foregroundStyle(RawDog.Colors.textSecondary)
                    }
                }
                .padding(12)
                .background(RawDog.Colors.cardBackground, in: RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(RawDog.Colors.borderSubtle, lineWidth: 1)
                )
            }
        }
    }

    // MARK: - Photo Gallery (3-column grid)

    private var photoGallery: some View {
        let photos = monthlyPhotos()
        let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

        return Group {
            if !photos.isEmpty {
                VStack(alignment: .leading, spacing: RawDog.Spacing.sm) {
                    RawDog.SectionHeader(title: "This Month's Proof", icon: "photo.stack.fill")

                    LazyVGrid(columns: columns, spacing: 4) {
                        ForEach(Array(photos.enumerated()), id: \.offset) { _, item in
                            Image(uiImage: item)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 110)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
            }
        }
    }

    private func monthlyPhotos() -> [UIImage] {
        let calendar = Calendar.current
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: Date())) ?? Date()

        return CommitmentStore.logs
            .filter { $0.date >= monthStart && $0.status == .verified && $0.photoFilename != nil }
            .sorted { $0.date > $1.date }
            .compactMap { log in
                guard let filename = log.photoFilename else { return nil }
                return CommitmentStore.loadPhoto(filename: filename)
            }
    }

    // MARK: - Heatmap (GitHub-style, last 90 days)

    private var heatmapSection: some View {
        VStack(alignment: .leading, spacing: RawDog.Spacing.sm) {
            RawDog.SectionHeader(title: "90-Day View", icon: "calendar")

            heatmapGrid
                .padding(RawDog.Spacing.sm)
                .background(RawDog.Colors.cardBackground, in: RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(RawDog.Colors.borderSubtle, lineWidth: 1)
                )

            // Legend
            HStack(spacing: RawDog.Spacing.sm) {
                legendItem(color: RawDog.Colors.approved.opacity(0.8), label: "All done")
                legendItem(color: RawDog.Colors.windowClosed.opacity(0.6), label: "Partial")
                legendItem(color: RawDog.Colors.destructive.opacity(0.4), label: "Missed")
                legendItem(color: RawDog.Colors.surfaceElevated, label: "None")
            }
        }
    }

    private var heatmapGrid: some View {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)

        // Build 90 days of data
        let days: [(date: Date, status: DayStatus)] = (0..<90).reversed().compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            let status = heatmapData[calendar.startOfDay(for: date)] ?? .none
            return (date, status)
        }

        // Group into weeks (rows of 7)
        return LazyVGrid(columns: columns, spacing: 2) {
            ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                RoundedRectangle(cornerRadius: 2)
                    .fill(colorForStatus(day.status))
                    .frame(height: 14)
                    .overlay {
                        if calendar.isDateInToday(day.date) {
                            RoundedRectangle(cornerRadius: 2)
                                .strokeBorder(RawDog.Colors.accentIce, lineWidth: 1)
                        }
                    }
            }
        }
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 10, height: 10)
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(RawDog.Colors.textSecondary)
        }
    }

    private func colorForStatus(_ status: DayStatus) -> Color {
        switch status {
        case .allDone: return RawDog.Colors.approved.opacity(0.8)
        case .partial: return RawDog.Colors.windowClosed.opacity(0.6)
        case .missed: return RawDog.Colors.destructive.opacity(0.4)
        case .none: return RawDog.Colors.surfaceElevated
        }
    }

    // MARK: - Weekly AI Insight

    private var insightCard: some View {
        VStack(alignment: .leading, spacing: RawDog.Spacing.md) {
            RawDog.SectionHeader(title: "Weekly Insight", icon: "brain.head.profile")

            if isLoadingInsight {
                HStack(spacing: RawDog.Spacing.sm) {
                    ProgressView()
                        .tint(RawDog.Colors.accentIce)
                    Text("RawDog is analyzing your week...")
                        .font(RawDog.Typography.caption)
                        .foregroundStyle(RawDog.Colors.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, RawDog.Spacing.md)
            } else if let insight = weeklyInsight {
                Text(insight.headline)
                    .font(RawDog.Typography.headline)
                    .foregroundStyle(RawDog.Colors.accentIce)

                Text(insight.insight)
                    .font(RawDog.Typography.body)
                    .foregroundStyle(RawDog.Colors.textPrimary)

                if let adjustment = insight.adjustment {
                    HStack(alignment: .top, spacing: RawDog.Spacing.sm) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundStyle(RawDog.Colors.accentIce)
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
        .padding(RawDog.Spacing.md)
        .background(RawDog.Colors.cardBackground, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(RawDog.Colors.borderSubtle, lineWidth: 1)
        )
    }

    // MARK: - Data Loading

    private func buildHeatmap() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let allCommitments = CommitmentStore.commitments.filter(\.isActive)
        let allLogs = CommitmentStore.logs
        var data: [Date: DayStatus] = [:]

        for offset in 0..<90 {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
            let dayStart = calendar.startOfDay(for: date)
            let weekday = calendar.component(.weekday, from: date)

            let scheduled = allCommitments.filter { $0.scheduledDays.contains(weekday) }.count
            guard scheduled > 0 else { continue }

            let dayLogs = allLogs.filter { calendar.startOfDay(for: $0.date) == dayStart }
            let verified = dayLogs.filter { $0.status == .verified }.count

            if verified >= scheduled {
                data[dayStart] = .allDone
            } else if verified > 0 {
                data[dayStart] = .partial
            } else {
                data[dayStart] = .missed
            }
        }

        heatmapData = data
    }

    private func loadInsightIfNeeded() {
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

    private var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: Date())
    }
}
