import SwiftUI

// MARK: - Monthly Report View

struct MonthlyReportView: View {
    @State private var stats = RetentionService.shared.calculateMonthlyStats()
    @State private var streakCalendar: [Date: DayStatus] = [:]
    @State private var photos: [(UIImage, String)] = []
    @State private var aiParagraph: String?
    @State private var isLoadingAI = false
    @State private var previousMonthStats: MonthlyRetentionStats?

    var body: some View {
        ScrollView {
            VStack(spacing: RawDog.Spacing.lg) {
                headerSection
                statsOverview
                streakCalendarSection
                monthComparison
                if !photos.isEmpty {
                    photoGallery
                }
                aiSection
            }
            .padding(.horizontal, RawDog.Spacing.md)
            .padding(.top, RawDog.Spacing.md)
            .padding(.bottom, 40)
        }
        .background(RawDog.Colors.background)
        .onAppear {
            buildCalendar()
            loadPhotos()
            loadPreviousMonth()
            loadAIParagraph()
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: RawDog.Spacing.sm) {
            Text("MONTHLY REPORT")
                .font(RawDog.Typography.caption2)
                .foregroundStyle(RawDog.Colors.textSecondary)
                .tracking(2)

            Text(monthName)
                .font(RawDog.Typography.title)
                .foregroundStyle(RawDog.Colors.textPrimary)
        }
    }

    // MARK: - Stats Overview

    private var statsOverview: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: RawDog.Spacing.sm) {
            overviewStat(
                value: String(format: "%.1fh", stats.hoursReclaimed),
                label: "Hours\nRecovered"
            )
            overviewStat(
                value: "\(stats.commitmentsCompleted)",
                label: "Sessions\nVerified"
            )
            overviewStat(
                value: "\(stats.longestStreak)d",
                label: "Longest\nStreak"
            )
        }
    }

    private func overviewStat(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(RawDog.Typography.title)
                .foregroundStyle(RawDog.Colors.accent)
            Text(label)
                .font(RawDog.Typography.caption)
                .foregroundStyle(RawDog.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, RawDog.Spacing.sm)
        .background(RawDog.Colors.surface, in: RoundedRectangle(cornerRadius: RawDog.Radius.card))
    }

    // MARK: - Streak Calendar (GitHub contribution graph style)

    private var streakCalendarSection: some View {
        VStack(alignment: .leading, spacing: RawDog.Spacing.sm) {
            RawDog.SectionHeader(title: "STREAK CALENDAR", icon: "calendar")

            calendarGrid
                .padding(RawDog.Spacing.sm)
                .background(RawDog.Colors.surface, in: RoundedRectangle(cornerRadius: RawDog.Radius.card))
        }
    }

    private var calendarGrid: some View {
        let calendar = Calendar.current
        let now = Date()
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
        let range = calendar.range(of: .day, in: .month, for: now) ?? 1..<31
        let daysInMonth = range.count
        let firstWeekday = calendar.component(.weekday, from: monthStart) - 1

        let columns = Array(repeating: GridItem(.flexible(), spacing: 3), count: 7)

        return VStack(alignment: .leading, spacing: 4) {
            // Day labels
            HStack {
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                    Text(day)
                        .font(RawDog.Typography.caption2)
                        .foregroundStyle(RawDog.Colors.textSecondary)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: columns, spacing: 3) {
                // Empty cells for offset
                ForEach(0..<firstWeekday, id: \.self) { _ in
                    Color.clear
                        .frame(height: 28)
                }

                // Day cells
                ForEach(1...daysInMonth, id: \.self) { day in
                    let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart)!
                    let status = streakCalendar[calendar.startOfDay(for: date)] ?? .none

                    RoundedRectangle(cornerRadius: 4)
                        .fill(colorForStatus(status))
                        .frame(height: 28)
                        .overlay {
                            if calendar.isDateInToday(date) {
                                RoundedRectangle(cornerRadius: 4)
                                    .strokeBorder(RawDog.Colors.accent, lineWidth: 1.5)
                            }
                        }
                }
            }

            // Legend
            HStack(spacing: RawDog.Spacing.sm) {
                legendItem(color: RawDog.Colors.approved.opacity(0.8), label: "All done")
                legendItem(color: RawDog.Colors.windowClosed.opacity(0.6), label: "Partial")
                legendItem(color: RawDog.Colors.destructive.opacity(0.4), label: "Missed")
                legendItem(color: RawDog.Colors.surface, label: "None")
            }
            .padding(.top, 4)
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

    // MARK: - Month Comparison

    private var monthComparison: some View {
        Group {
            if let prev = previousMonthStats, prev.totalScheduled > 0 {
                RawDog.Card {
                    RawDog.SectionHeader(title: "VS LAST MONTH", icon: "arrow.up.right")

                    HStack(spacing: RawDog.Spacing.md) {
                        comparisonItem(
                            current: stats.completionPercentage,
                            previous: prev.completionPercentage,
                            label: "Completion"
                        )
                        comparisonItem(
                            current: Int(stats.hoursReclaimed),
                            previous: Int(prev.hoursReclaimed),
                            label: "Hours"
                        )
                        comparisonItem(
                            current: stats.longestStreak,
                            previous: prev.longestStreak,
                            label: "Best Streak"
                        )
                    }
                }
            }
        }
    }

    private func comparisonItem(current: Int, previous: Int, label: String) -> some View {
        let diff = current - previous
        let arrow = diff > 0 ? "arrow.up" : diff < 0 ? "arrow.down" : "minus"
        let color = diff > 0 ? RawDog.Colors.approved : diff < 0 ? RawDog.Colors.destructive : RawDog.Colors.textSecondary

        return VStack(spacing: 4) {
            HStack(spacing: 2) {
                Image(systemName: arrow)
                    .font(.system(size: 10, weight: .bold))
                Text("\(abs(diff))")
                    .font(RawDog.Typography.headline)
            }
            .foregroundStyle(color)

            Text(label)
                .font(RawDog.Typography.caption2)
                .foregroundStyle(RawDog.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Photo Gallery

    private var photoGallery: some View {
        VStack(alignment: .leading, spacing: RawDog.Spacing.sm) {
            RawDog.SectionHeader(title: "THIS MONTH'S PROOF", icon: "photo.stack.fill")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(photos.enumerated()), id: \.offset) { _, item in
                        VStack(spacing: 4) {
                            Image(uiImage: item.0)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 120)
                                .clipShape(RoundedRectangle(cornerRadius: RawDog.Radius.small))

                            Text(item.1)
                                .font(RawDog.Typography.caption2)
                                .foregroundStyle(RawDog.Colors.textSecondary)
                                .lineLimit(1)
                        }
                    }
                }
            }
        }
    }

    // MARK: - AI Section

    private var aiSection: some View {
        Group {
            if let paragraph = aiParagraph {
                RawDog.GlowCard(accentColor: RawDog.Colors.accentGlow) {
                    RawDog.SectionHeader(title: "RAWDOG'S TAKE", icon: "quote.bubble.fill")
                    Text(paragraph)
                        .font(RawDog.Typography.body)
                        .foregroundStyle(RawDog.Colors.textPrimary)
                }
            } else if isLoadingAI {
                RawDog.Card {
                    HStack {
                        ProgressView()
                            .tint(RawDog.Colors.accent)
                        Text("Analyzing your month...")
                            .font(RawDog.Typography.caption)
                            .foregroundStyle(RawDog.Colors.textSecondary)
                    }
                }
            }
        }
    }

    // MARK: - Data Loading

    private func buildCalendar() {
        let calendar = Calendar.current
        let now = Date()
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
        let range = calendar.range(of: .day, in: .month, for: now) ?? 1..<31

        let allLogs = CommitmentStore.logs.filter { $0.date >= monthStart && $0.date <= now }
        let commitments = CommitmentStore.commitments.filter(\.isActive)
        var calendarData: [Date: DayStatus] = [:]

        for dayNum in range {
            guard let date = calendar.date(byAdding: .day, value: dayNum - 1, to: monthStart),
                  date <= now else { continue }
            let dayStart = calendar.startOfDay(for: date)
            let weekday = calendar.component(.weekday, from: date)

            let scheduled = commitments.filter { $0.scheduledDays.contains(weekday) }.count
            guard scheduled > 0 else { continue }

            let dayLogs = allLogs.filter { calendar.startOfDay(for: $0.date) == dayStart }
            let verified = dayLogs.filter { $0.status == .verified }.count

            if verified >= scheduled {
                calendarData[dayStart] = .allDone
            } else if verified > 0 {
                calendarData[dayStart] = .partial
            } else {
                calendarData[dayStart] = .missed
            }
        }

        streakCalendar = calendarData
    }

    private func loadPhotos() {
        let calendar = Calendar.current
        let now = Date()
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now

        let monthLogs = CommitmentStore.logs.filter {
            $0.date >= monthStart && $0.date <= now && $0.photoFilename != nil
        }

        var loaded: [(UIImage, String)] = []
        for log in monthLogs {
            if let filename = log.photoFilename,
               let image = CommitmentStore.loadPhoto(filename: filename) {
                let commitment = CommitmentStore.commitments.first { $0.id == log.commitmentId }
                loaded.append((image, commitment?.title ?? ""))
            }
        }
        photos = loaded
    }

    private func loadPreviousMonth() {
        let calendar = Calendar.current
        let now = Date()
        guard let prevMonth = calendar.date(byAdding: .month, value: -1, to: now) else { return }
        let prevStart = calendar.date(from: calendar.dateComponents([.year, .month], from: prevMonth)) ?? prevMonth
        let prevEnd = calendar.date(byAdding: .month, value: 1, to: prevStart) ?? now

        let commitments = CommitmentStore.commitments.filter(\.isActive)
        let prevLogs = CommitmentStore.logs.filter { $0.date >= prevStart && $0.date < prevEnd }
        let verified = prevLogs.filter { $0.status == .verified }

        var totalScheduled = 0
        var dayDate = prevStart
        while dayDate < prevEnd {
            let weekday = calendar.component(.weekday, from: dayDate)
            for commitment in commitments {
                if commitment.scheduledDays.contains(weekday) {
                    totalScheduled += 1
                }
            }
            dayDate = calendar.date(byAdding: .day, value: 1, to: dayDate) ?? prevEnd
        }

        let longestStreak = commitments.map { CommitmentStore.stats(for: $0.id).bestStreak }.max() ?? 0

        previousMonthStats = MonthlyRetentionStats(
            commitmentsCompleted: verified.count,
            totalScheduled: totalScheduled,
            hoursReclaimed: Double(verified.count) * 0.5,
            longestStreak: longestStreak,
            monthStartDate: prevStart
        )
    }

    private func loadAIParagraph() {
        isLoadingAI = true
        Task {
            do {
                let memory = UserMemoryStore.shared.memory
                let system = """
                You are RawDog, a Shiba Inu accountability coach. Write a brief monthly summary paragraph. \
                Reference their actual data. Honest, forward-looking. Max 3 sentences. No fluff.

                \(memory.toContextString())
                """

                let prompt = """
                Monthly stats: \(stats.commitmentsCompleted)/\(stats.totalScheduled) commitments, \
                \(String(format: "%.1f", stats.hoursReclaimed))h reclaimed, \
                longest streak: \(stats.longestStreak) days, \
                \(stats.verifiedPhotoCount) photo proofs.
                Write a monthly reflection paragraph.
                """

                let response = try await GroqService.shared.callRetention(system: system, user: prompt, maxTokens: 200)
                await MainActor.run {
                    aiParagraph = response
                    isLoadingAI = false
                }
            } catch {
                await MainActor.run {
                    isLoadingAI = false
                }
            }
        }
    }

    // MARK: - Helpers

    private var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: Date())
    }
}

// MARK: - Day Status

enum DayStatus {
    case allDone
    case partial
    case missed
    case none
}
