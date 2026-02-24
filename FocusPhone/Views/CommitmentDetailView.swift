import SwiftUI

struct CommitmentDetailView: View {
    let commitment: Commitment
    @ObservedObject var viewModel: CommitmentViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var aiInsight: String?

    private var stats: HabitStats {
        viewModel.statsFor(commitment)
    }

    private var recentLogs: [CommitmentLog] {
        Array(CommitmentStore.logsForCommitment(id: commitment.id).prefix(14))
    }

    private var completionProgress: Double {
        stats.completionRate
    }

    var body: some View {
        ZStack {
            RawDog.Colors.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: RawDog.Spacing.lg) {
                    // Drag indicator
                    dragIndicator

                    // Progress ring with emoji
                    progressRing

                    // Title + category
                    titleSection

                    // Week bubbles
                    weekBubbles

                    // Photo strip
                    photoStrip

                    // AI insight
                    insightSection

                    // Stats grid 2x2
                    statsGrid

                    // Actions
                    actionsSection
                }
                .padding()
                .padding(.bottom, 20)
            }
        }
        .presentationDragIndicator(.hidden)
        .preferredColorScheme(.dark)
        .onAppear { loadInsight() }
    }

    // MARK: - Drag Indicator

    private var dragIndicator: some View {
        Capsule()
            .fill(RawDog.Colors.textSecondary.opacity(0.3))
            .frame(width: 36, height: 5)
            .padding(.top, 8)
    }

    // MARK: - Progress Ring

    private var progressRing: some View {
        ZStack {
            Circle()
                .stroke(RawDog.Colors.trackBackground, lineWidth: 6)
                .frame(width: 120, height: 120)

            Circle()
                .trim(from: 0, to: completionProgress)
                .stroke(
                    RawDog.Colors.accentIce,
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .frame(width: 120, height: 120)
                .rotationEffect(.degrees(-90))

            Text(commitment.emoji)
                .font(.system(size: 44))
        }
    }

    // MARK: - Title

    private var titleSection: some View {
        VStack(spacing: 4) {
            Text(commitment.title)
                .font(RawDog.Typography.title2)
                .foregroundStyle(RawDog.Colors.textPrimary)

            Text(commitment.category.displayName)
                .font(RawDog.Typography.caption)
                .foregroundStyle(RawDog.Colors.textSecondary)

            if let status = viewModel.todayStatus(for: commitment) {
                RawDog.StatusBadge(
                    text: status.rawValue.capitalized,
                    icon: status == .verified ? "checkmark.circle" : "clock",
                    color: status == .verified ? RawDog.Colors.approved : RawDog.Colors.textSecondary
                )
                .padding(.top, 4)
            }
        }
    }

    // MARK: - Week Bubbles (last 7 days)

    private var weekBubbles: some View {
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
                        .frame(width: 36, height: 36)
                        .overlay {
                            if log?.status == .verified {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(RawDog.Colors.background)
                            }
                        }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(RawDog.Spacing.md)
        .background(RawDog.Colors.cardBackground, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(RawDog.Colors.borderSubtle, lineWidth: 1)
        )
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

    // MARK: - Photo Strip

    private var photoStrip: some View {
        let photos = recentPhotos(limit: 8)

        return Group {
            if !photos.isEmpty {
                VStack(alignment: .leading, spacing: RawDog.Spacing.sm) {
                    RawDog.SectionHeader(title: "Proof", icon: "photo.stack")

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: RawDog.Spacing.sm) {
                            ForEach(photos, id: \.0) { filename, image in
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 80, height: 80)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                }
            }
        }
    }

    private func recentPhotos(limit: Int) -> [(String, UIImage)] {
        recentLogs
            .filter { $0.status == .verified && $0.photoFilename != nil }
            .prefix(limit)
            .compactMap { log in
                guard let filename = log.photoFilename,
                      let image = CommitmentStore.loadPhoto(filename: filename) else { return nil }
                return (filename, image)
            }
    }

    // MARK: - AI Insight

    private var insightSection: some View {
        Group {
            if let insight = aiInsight {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 14))
                        .foregroundStyle(RawDog.Colors.accentIce)
                        .padding(.top, 2)

                    Text(insight)
                        .font(RawDog.Typography.subheadline)
                        .foregroundStyle(RawDog.Colors.textPrimary)
                }
                .padding(RawDog.Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RawDog.Colors.cardBackground, in: RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(RawDog.Colors.borderSubtle, lineWidth: 1)
                )
            }
        }
    }

    // MARK: - Stats Grid 2x2

    private var statsGrid: some View {
        let columns = [GridItem(.flexible()), GridItem(.flexible())]

        return LazyVGrid(columns: columns, spacing: RawDog.Spacing.sm) {
            gridStat(value: "\(stats.currentStreak)", label: "Current Streak", icon: "flame.fill")
            gridStat(value: "\(stats.bestStreak)", label: "Best Streak", icon: "trophy.fill")
            gridStat(value: "\(Int(stats.completionRate * 100))%", label: "Completion Rate", icon: "chart.bar.fill")
            gridStat(value: "\(stats.totalVerified)", label: "Total Verified", icon: "checkmark.seal.fill")
        }
    }

    private func gridStat(value: String, label: String, icon: String) -> some View {
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
        .padding(.vertical, 16)
        .background(RawDog.Colors.cardBackground, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(RawDog.Colors.borderSubtle, lineWidth: 1)
        )
    }

    // MARK: - Actions

    private var actionsSection: some View {
        VStack(spacing: RawDog.Spacing.sm) {
            RawDog.PillButton(title: commitment.isActive ? "Pause" : "Resume", style: .secondary) {
                viewModel.toggleActive(commitment)
                dismiss()
            }

            RawDog.PillButton(title: "Delete", style: .destructive) {
                viewModel.deleteCommitment(commitment)
                dismiss()
            }
        }
    }

    // MARK: - Data Loading

    private func loadInsight() {
        Task {
            do {
                let system = """
                You are RawDog, a Shiba Inu coach. One-line pattern insight about this specific commitment. \
                Max 1 sentence. Reference their data. Casual.
                """
                let prompt = """
                Commitment: \(commitment.title). \
                Streak: \(stats.currentStreak) days. Best: \(stats.bestStreak). \
                Rate: \(Int(stats.completionRate * 100))%. \
                Trend: \(stats.trend). \
                Give a one-liner insight.
                """
                let response = try await GroqService.shared.callRetention(system: system, user: prompt, maxTokens: 50)
                await MainActor.run { aiInsight = response }
            } catch {
                // Silent fail
            }
        }
    }
}
