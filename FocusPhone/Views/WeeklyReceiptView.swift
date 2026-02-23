import SwiftUI

// MARK: - Weekly Receipt View

struct WeeklyReceiptView: View {
    @State private var stats = RetentionService.shared.calculateWeeklyStats()
    @State private var photos: [(UIImage, String)] = []
    @State private var aiInsight: String?
    @State private var isLoadingInsight = false
    @State private var shareImage: UIImage?
    @State private var showShareSheet = false

    var body: some View {
        ScrollView {
            VStack(spacing: RawDog.Spacing.lg) {
                headerSection
                statsGrid
                if !photos.isEmpty {
                    photoGrid
                }
                aiInsightSection
                shareButton
            }
            .padding(.horizontal, RawDog.Spacing.md)
            .padding(.top, RawDog.Spacing.md)
            .padding(.bottom, 40)
        }
        .background(RawDog.Colors.background)
        .onAppear {
            loadPhotos()
            loadAIInsight()
        }
        .sheet(isPresented: $showShareSheet) {
            if let image = shareImage {
                ShareSheet(items: [image])
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: RawDog.Spacing.sm) {
            Text("WEEKLY RECEIPT")
                .font(RawDog.Typography.caption2)
                .foregroundStyle(RawDog.Colors.textSecondary)
                .tracking(2)

            Text(weekRangeText)
                .font(RawDog.Typography.title2)
                .foregroundStyle(RawDog.Colors.textPrimary)

            if stats.longestStreakThisWeek > 0 {
                Text("\(stats.longestStreakThisWeek) DAY STREAK")
                    .font(RawDog.Typography.largeTitle)
                    .foregroundStyle(RawDog.Colors.accent)
            }
        }
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: RawDog.Spacing.sm) {
            statCard(
                value: "\(stats.commitmentsCompleted)/\(stats.totalScheduled)",
                label: "Commitments",
                icon: "checkmark.circle.fill"
            )
            statCard(
                value: "\(stats.completionPercentage)%",
                label: "Completion",
                icon: "chart.bar.fill"
            )
            statCard(
                value: String(format: "%.1fh", stats.hoursReclaimed),
                label: "Hours Reclaimed",
                icon: "clock.fill"
            )
            statCard(
                value: "\(stats.verifiedPhotoCount)",
                label: "Photo Proofs",
                icon: "camera.fill"
            )
        }
    }

    private func statCard(value: String, label: String, icon: String) -> some View {
        RawDog.Card {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(RawDog.Colors.accent)
                Spacer()
            }
            Text(value)
                .font(RawDog.Typography.title)
                .foregroundStyle(RawDog.Colors.textPrimary)
            Text(label)
                .font(RawDog.Typography.caption)
                .foregroundStyle(RawDog.Colors.textSecondary)
        }
    }

    // MARK: - Photo Grid

    private var photoGrid: some View {
        VStack(alignment: .leading, spacing: RawDog.Spacing.sm) {
            RawDog.SectionHeader(title: "PROOF", icon: "camera.fill")

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
            ], spacing: 4) {
                ForEach(Array(photos.prefix(9).enumerated()), id: \.offset) { _, item in
                    Image(uiImage: item.0)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: RawDog.Radius.small))
                }
            }
        }
    }

    // MARK: - AI Insight

    private var aiInsightSection: some View {
        Group {
            if let insight = aiInsight {
                RawDog.GlowCard(accentColor: RawDog.Colors.accentGlow) {
                    RawDog.SectionHeader(title: "RAWDOG SAYS", icon: "quote.bubble.fill")
                    Text(insight)
                        .font(RawDog.Typography.body)
                        .foregroundStyle(RawDog.Colors.textPrimary)
                }
            } else if isLoadingInsight {
                RawDog.Card {
                    HStack {
                        ProgressView()
                            .tint(RawDog.Colors.accent)
                        Text("RawDog is thinking...")
                            .font(RawDog.Typography.caption)
                            .foregroundStyle(RawDog.Colors.textSecondary)
                    }
                }
            }
        }
    }

    // MARK: - Share Button

    private var shareButton: some View {
        RawDog.PillButton(title: "Share Your Receipt") {
            generateShareImage()
        }
    }

    // MARK: - Data Loading

    private func loadPhotos() {
        let calendar = Calendar.current
        let now = Date()
        var weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? now
        if calendar.component(.weekday, from: weekStart) == 1 {
            weekStart = calendar.date(byAdding: .day, value: -6, to: weekStart) ?? weekStart
        }

        let weekLogs = CommitmentStore.logs.filter {
            $0.date >= weekStart && $0.date <= now && $0.photoFilename != nil
        }

        var loaded: [(UIImage, String)] = []
        for log in weekLogs {
            if let filename = log.photoFilename,
               let image = CommitmentStore.loadPhoto(filename: filename) {
                let commitment = CommitmentStore.commitments.first { $0.id == log.commitmentId }
                loaded.append((image, commitment?.title ?? ""))
            }
        }
        photos = loaded
    }

    private func loadAIInsight() {
        isLoadingInsight = true
        Task {
            do {
                let commitments = CommitmentStore.commitments.filter(\.isActive)
                var statsDict: [String: HabitStats] = [:]
                for c in commitments {
                    statsDict[c.title] = CommitmentStore.stats(for: c.id)
                }
                let insight = try await GroqService.shared.generateWeeklyInsights(stats: statsDict)
                await MainActor.run {
                    aiInsight = insight.headline + " " + insight.insight
                    isLoadingInsight = false
                }
            } catch {
                await MainActor.run {
                    aiInsight = nil
                    isLoadingInsight = false
                }
            }
        }
    }

    // MARK: - Share Image Generation

    private func generateShareImage() {
        let shareView = ReceiptShareCard(
            stats: stats,
            photos: photos.map(\.0),
            insight: aiInsight
        )

        let renderer = ImageRenderer(content: shareView)
        renderer.scale = UIScreen.main.scale

        if let image = renderer.uiImage {
            shareImage = image
            showShareSheet = true
        }
    }

    // MARK: - Helpers

    private var weekRangeText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let calendar = Calendar.current
        let now = Date()
        var weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? now
        if calendar.component(.weekday, from: weekStart) == 1 {
            weekStart = calendar.date(byAdding: .day, value: -6, to: weekStart) ?? weekStart
        }
        let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) ?? now
        return "\(formatter.string(from: weekStart)) – \(formatter.string(from: weekEnd))"
    }
}

// MARK: - Shareable Receipt Card (for ImageRenderer)

private struct ReceiptShareCard: View {
    let stats: WeeklyRetentionStats
    let photos: [UIImage]
    let insight: String?

    var body: some View {
        VStack(spacing: 20) {
            // Header
            Text("RAWDOG WEEKLY RECEIPT")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(Color(hex: "888888"))
                .tracking(3)

            if stats.longestStreakThisWeek > 0 {
                Text("\(stats.longestStreakThisWeek) DAYS STRAIGHT")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "E8F4FF"))
            }

            // Stats row
            HStack(spacing: 24) {
                shareStatItem(value: "\(stats.commitmentsCompleted)/\(stats.totalScheduled)", label: "Done")
                shareStatItem(value: "\(stats.completionPercentage)%", label: "Rate")
                shareStatItem(value: String(format: "%.1fh", stats.hoursReclaimed), label: "Reclaimed")
            }

            // Photo strip
            if !photos.isEmpty {
                HStack(spacing: 4) {
                    ForEach(Array(photos.prefix(5).enumerated()), id: \.offset) { _, photo in
                        Image(uiImage: photo)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 56, height: 56)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }

            // AI insight
            if let insight = insight {
                Text(insight)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Color(hex: "888888"))
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .padding(.horizontal, 16)
            }

            // Watermark
            Text("rawdog.app")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(Color(hex: "444444"))
        }
        .padding(32)
        .frame(width: 340)
        .background(Color.black)
    }

    private func shareStatItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(Color.white)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color(hex: "888888"))
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
