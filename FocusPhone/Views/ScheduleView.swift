import SwiftUI

struct ScheduleView: View {
    @StateObject private var commitmentVM = CommitmentViewModel()
    @State private var todayCommitments: [Commitment] = []
    @State private var showingCreateCommitment = false
    @State private var selectedCommitment: Commitment?
    @State private var showMentorChat = false
    @State private var screenTimeInsight: String?
    @State private var weeklyVerifications: [Int] = Array(repeating: 0, count: 7)
    @State private var weeklyTotals: [Int] = Array(repeating: 0, count: 7)

    private let calendar = Calendar.current

    private var greeting: String {
        let hour = calendar.component(.hour, from: Date())
        let name = UserMemoryStore.shared.memory.name
        let displayName = name.isEmpty ? "" : ", \(name)"
        if hour < 12 { return "Good morning\(displayName)" }
        if hour < 17 { return "Good afternoon\(displayName)" }
        return "Good evening\(displayName)"
    }

    private var todayDone: Int {
        todayCommitments.filter { todayStatus(for: $0) == .verified }.count
    }

    private var todayTotal: Int {
        todayCommitments.count
    }

    private var focusProgress: Double {
        guard todayTotal > 0 else { return 0 }
        return Double(todayDone) / Double(todayTotal)
    }

    var body: some View {
        ZStack {
            RawDog.Colors.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: RawDog.Spacing.lg) {
                    // Greeting header
                    greetingHeader

                    // Focus ring
                    focusRing

                    // Stat cards
                    statCards

                    // Session cards
                    if !todayCommitments.isEmpty {
                        sessionCards
                    }

                    // Screen time insight
                    insightCard

                    // Weekly chart
                    weeklyChart

                    // Mentor card
                    mentorCard

                    Spacer().frame(height: 20)
                }
                .padding(.top, RawDog.Spacing.md)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingCreateCommitment = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(RawDog.Colors.accentIce)
                }
            }
        }
        .onAppear { refreshData() }
        .sheet(isPresented: $showingCreateCommitment) {
            CreateCommitmentView(viewModel: commitmentVM)
        }
        .sheet(item: $selectedCommitment) { commitment in
            CommitmentDetailView(commitment: commitment, viewModel: commitmentVM)
        }
        .fullScreenCover(isPresented: $showMentorChat) {
            MentorChatView()
        }
        .onChange(of: showingCreateCommitment) {
            if !showingCreateCommitment { refreshData() }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Greeting Header

    private var greetingHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(greeting)
                .font(RawDog.Typography.title)
                .foregroundStyle(RawDog.Colors.textPrimary)

            Text("Let's stay focused today")
                .font(RawDog.Typography.subheadline)
                .foregroundStyle(RawDog.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }

    // MARK: - Focus Ring

    private var focusRing: some View {
        VStack(spacing: RawDog.Spacing.sm) {
            ZStack {
                // Track
                Circle()
                    .stroke(RawDog.Colors.trackBackground, lineWidth: 8)
                    .frame(width: 200, height: 200)

                // Progress
                Circle()
                    .trim(from: 0, to: focusProgress)
                    .stroke(
                        RawDog.Colors.accentIce,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.6), value: focusProgress)

                // Mascot inside
                AnimatedMascot(
                    state: todayDone == todayTotal && todayTotal > 0 ? .proud : .neutral,
                    size: 80
                )
            }

            // Fraction label
            if todayTotal > 0 {
                Text("\(todayDone) of \(todayTotal) done")
                    .font(RawDog.Typography.headline)
                    .foregroundStyle(RawDog.Colors.textPrimary)
            } else {
                Text("No commitments today")
                    .font(RawDog.Typography.headline)
                    .foregroundStyle(RawDog.Colors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, RawDog.Spacing.sm)
    }

    // MARK: - Stat Cards

    private var statCards: some View {
        let memory = UserMemoryStore.shared.memory
        let topStreak = memory.currentStreaks.values.max() ?? 0
        let hoursRecovered = String(format: "%.1f", Double(memory.totalVerifiedSessions) * 0.5)
        let commitments = CommitmentStore.commitments.filter(\.isActive)
        let avgRate: Int = {
            guard !commitments.isEmpty else { return 0 }
            let total = commitments.map { CommitmentStore.stats(for: $0.id).completionRate }.reduce(0, +)
            return Int(total / Double(commitments.count) * 100)
        }()

        return HStack(spacing: RawDog.Spacing.sm) {
            statCard(value: "\(topStreak)", label: "Streak", icon: "flame.fill")
            statCard(value: "\(hoursRecovered)h", label: "Recovered", icon: "clock.fill")
            statCard(value: "\(avgRate)%", label: "Rate", icon: "chart.bar.fill")
        }
        .padding(.horizontal)
    }

    private func statCard(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(RawDog.Colors.accentIce)

            Text(value)
                .font(RawDog.Typography.title2)
                .foregroundStyle(RawDog.Colors.textPrimary)

            Text(label)
                .font(RawDog.Typography.caption2)
                .foregroundStyle(RawDog.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(RawDog.Colors.cardBackground, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(RawDog.Colors.borderSubtle, lineWidth: 1)
        )
    }

    // MARK: - Session Cards

    private var sessionCards: some View {
        VStack(alignment: .leading, spacing: RawDog.Spacing.sm) {
            RawDog.SectionHeader(title: "Today", icon: "calendar")
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(sortedCommitments) { commitment in
                        sessionCard(commitment)
                            .onTapGesture {
                                selectedCommitment = commitment
                            }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private func sessionCard(_ commitment: Commitment) -> some View {
        let status = todayStatus(for: commitment)

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(commitment.emoji)
                    .font(.title2)
                Spacer()
                statusBadge(status)
            }

            Text(commitment.title)
                .font(RawDog.Typography.subheadline.weight(.medium))
                .foregroundStyle(RawDog.Colors.textPrimary)
                .lineLimit(1)

            Text(timeString(for: commitment))
                .font(RawDog.Typography.caption)
                .foregroundStyle(RawDog.Colors.textSecondary)
        }
        .padding(14)
        .frame(width: 160)
        .background(RawDog.Colors.cardBackground, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(RawDog.Colors.borderSubtle, lineWidth: 1)
        )
    }

    // MARK: - Insight Card

    private var insightCard: some View {
        Group {
            if let insight = screenTimeInsight {
                HStack(spacing: 12) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 16))
                        .foregroundStyle(RawDog.Colors.accentIce)

                    Text(insight)
                        .font(RawDog.Typography.subheadline)
                        .foregroundStyle(RawDog.Colors.textPrimary)
                        .lineLimit(2)
                }
                .padding(RawDog.Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RawDog.Colors.cardBackground, in: RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(RawDog.Colors.borderSubtle, lineWidth: 1)
                )
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Weekly Chart

    private var weeklyChart: some View {
        VStack(alignment: .leading, spacing: RawDog.Spacing.sm) {
            RawDog.SectionHeader(title: "This Week", icon: "chart.bar")
                .padding(.horizontal)

            HStack(alignment: .bottom, spacing: RawDog.Spacing.sm) {
                let dayLabels = ["M", "T", "W", "T", "F", "S", "S"]

                ForEach(0..<7, id: \.self) { i in
                    VStack(spacing: 4) {
                        let verified = weeklyVerifications[i]
                        let total = weeklyTotals[i]
                        let height: CGFloat = total > 0 ? CGFloat(verified) / CGFloat(max(total, 1)) * 60 : 4
                        let allDone = total > 0 && verified >= total

                        RoundedRectangle(cornerRadius: 4)
                            .fill(allDone ? RawDog.Colors.accentIce : RawDog.Colors.trackBackground)
                            .frame(height: max(4, height))

                        Text(dayLabels[i])
                            .font(RawDog.Typography.caption2)
                            .foregroundStyle(RawDog.Colors.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 80, alignment: .bottom)
            .padding(RawDog.Spacing.md)
            .background(RawDog.Colors.cardBackground, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(RawDog.Colors.borderSubtle, lineWidth: 1)
            )
            .padding(.horizontal)
        }
    }

    // MARK: - Mentor Card

    private var mentorCard: some View {
        Button {
            showMentorChat = true
        } label: {
            HStack(spacing: 12) {
                AnimatedMascot(state: .neutral, size: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Talk to RawDog")
                        .font(RawDog.Typography.headline)
                        .foregroundStyle(RawDog.Colors.textPrimary)
                    Text("Your accountability coach")
                        .font(RawDog.Typography.caption)
                        .foregroundStyle(RawDog.Colors.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(RawDog.Colors.textSecondary)
            }
            .padding(RawDog.Spacing.md)
            .background(RawDog.Colors.cardBackground, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(RawDog.Colors.borderSubtle, lineWidth: 1)
            )
            .padding(.horizontal)
        }
    }

    // MARK: - Helpers

    private var sortedCommitments: [Commitment] {
        todayCommitments.sorted {
            let h0 = $0.scheduledHour * 60 + $0.scheduledMinute
            let h1 = $1.scheduledHour * 60 + $1.scheduledMinute
            return h0 < h1
        }
    }

    private func todayStatus(for commitment: Commitment) -> CommitmentLogStatus? {
        CommitmentStore.todayLog(for: commitment.id)?.status
    }

    private func timeString(for commitment: Commitment) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: commitment.scheduledTime)
    }

    @ViewBuilder
    private func statusBadge(_ status: CommitmentLogStatus?) -> some View {
        switch status {
        case .verified:
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16))
                .foregroundStyle(RawDog.Colors.approved)
        case .failed:
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 16))
                .foregroundStyle(RawDog.Colors.destructive)
        case .pending:
            Image(systemName: "clock")
                .font(.system(size: 16))
                .foregroundStyle(RawDog.Colors.windowClosed)
        default:
            EmptyView()
        }
    }

    private func refreshData() {
        let todayWeekday = calendar.component(.weekday, from: Date())
        todayCommitments = CommitmentStore.commitments
            .filter { $0.isActive && $0.scheduledDays.contains(todayWeekday) }

        // Load weekly data
        loadWeeklyData()

        // Load AI insight
        loadInsight()
    }

    private func loadWeeklyData() {
        let today = calendar.startOfDay(for: Date())
        // Find Monday of this week
        let weekday = calendar.component(.weekday, from: today)
        let daysFromMonday = (weekday + 5) % 7 // Mon=0, Tue=1, ... Sun=6
        guard let monday = calendar.date(byAdding: .day, value: -daysFromMonday, to: today) else { return }

        let allCommitments = CommitmentStore.commitments.filter(\.isActive)
        let allLogs = CommitmentStore.logs

        var verifications = Array(repeating: 0, count: 7)
        var totals = Array(repeating: 0, count: 7)

        for i in 0..<7 {
            guard let day = calendar.date(byAdding: .day, value: i, to: monday),
                  day <= today else { continue }
            let dayWeekday = calendar.component(.weekday, from: day)
            let dayStart = calendar.startOfDay(for: day)

            let scheduled = allCommitments.filter { $0.scheduledDays.contains(dayWeekday) }.count
            let verified = allLogs.filter {
                calendar.startOfDay(for: $0.date) == dayStart && $0.status == .verified
            }.count

            verifications[i] = verified
            totals[i] = scheduled
        }

        weeklyVerifications = verifications
        weeklyTotals = totals
    }

    private func loadInsight() {
        let done = RetentionService.shared.todayCompletedCount()
        let total = RetentionService.shared.todayScheduledCount()

        Task {
            do {
                let memory = UserMemoryStore.shared.memory
                let system = """
                You are RawDog, a Shiba Inu coach. One-line screen time insight. \
                Reference their actual data. Max 1 sentence. Casual. \(memory.toContextString())
                """
                let prompt = "Today: \(done)/\(total) done. Generate a one-liner insight about their focus today."
                let response = try await GroqService.shared.callRetention(system: system, user: prompt, maxTokens: 50)
                await MainActor.run {
                    screenTimeInsight = response
                }
            } catch {
                // Silent fail - insight is optional
            }
        }
    }
}
