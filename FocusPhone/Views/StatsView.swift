import SwiftUI

struct StatsView: View {
    @StateObject private var viewModel = StatsViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: FPTheme.spacing16) {
                    activeModeCard
                    todayOverviewRow
                    todayUsageSection
                    weeklyChartSection
                    streakCard
                }
                .padding()
            }
            .background(FPTheme.backgroundPrimary)
            .navigationTitle("Stats")
            .onAppear { viewModel.refresh() }
        }
    }

    // MARK: - Active Mode Card

    @ViewBuilder
    private var activeModeCard: some View {
        if let mode = viewModel.activeMode {
            HStack(spacing: 14) {
                Image(systemName: mode.icon)
                    .font(.title2)
                    .foregroundStyle(ModeColor.blockForeground(lightHex: mode.colorHex))
                    .frame(width: 48, height: 48)
                    .background(ModeColor.blockBackground(lightHex: mode.colorHex), in: RoundedRectangle(cornerRadius: FPTheme.smallRadius))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Currently Active")
                        .font(FPTheme.captionFont)
                        .foregroundStyle(FPTheme.textSecondary)
                    Text(mode.name)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(FPTheme.textPrimary)
                }

                Spacer()

                Circle()
                    .fill(ModeColor.adaptive(lightHex: mode.colorHex))
                    .frame(width: 10, height: 10)
                    .modifier(PulseModifier())
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: FPTheme.cardRadius)
                    .fill(ModeColor.blockBackground(lightHex: mode.colorHex))
                    .overlay(
                        RoundedRectangle(cornerRadius: FPTheme.cardRadius)
                            .strokeBorder(ModeColor.adaptive(lightHex: mode.colorHex).opacity(0.2), lineWidth: 1)
                    )
            )
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Currently active: \(mode.name)")
        } else {
            HStack(spacing: 14) {
                Image(systemName: "moon.zzz.fill")
                    .font(.title2)
                    .foregroundStyle(FPTheme.textSecondary)
                    .frame(width: 48, height: 48)
                    .background(FPTheme.backgroundSecondary, in: RoundedRectangle(cornerRadius: FPTheme.smallRadius))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Currently")
                        .font(FPTheme.captionFont)
                        .foregroundStyle(FPTheme.textSecondary)
                    Text("No Active Mode")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(FPTheme.textSecondary)
                }

                Spacer()
            }
            .padding()
            .background(FPTheme.backgroundSecondary, in: RoundedRectangle(cornerRadius: FPTheme.cardRadius))
            .accessibilityElement(children: .combine)
            .accessibilityLabel("No active mode")
        }
    }

    // MARK: - Today Overview

    private var todayOverviewRow: some View {
        HStack(spacing: FPTheme.spacing12) {
            statCard(
                icon: "clock.fill",
                iconColor: Color(hex: "#A0B8D0"),
                title: "Focus Time",
                value: viewModel.formatDuration(viewModel.todayTotalDuration)
            )
            statCard(
                icon: "list.bullet.circle.fill",
                iconColor: Color(hex: "#C4B5D4"),
                title: "Sessions",
                value: "\(viewModel.todaySessions.count)"
            )
        }
    }

    private func statCard(icon: String, iconColor: Color, title: String, value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(iconColor)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(FPTheme.captionFont)
                    .foregroundStyle(FPTheme.textSecondary)
                Text(value)
                    .font(.headline)
                    .foregroundStyle(FPTheme.textPrimary)
            }

            Spacer()
        }
        .padding(FPTheme.spacing12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(FPTheme.backgroundSecondary, in: RoundedRectangle(cornerRadius: FPTheme.smallRadius))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }

    // MARK: - Today's Usage

    private var todayUsageSection: some View {
        VStack(alignment: .leading, spacing: FPTheme.spacing12) {
            Text("Today")
                .font(FPTheme.sectionTitleFont)
                .foregroundStyle(FPTheme.textPrimary)

            if viewModel.todayUsageByMode.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 6) {
                        Image(systemName: "tray")
                            .font(.title2)
                            .foregroundStyle(FPTheme.textSecondary.opacity(0.4))
                        Text("No sessions recorded today")
                            .font(.subheadline)
                            .foregroundStyle(FPTheme.textSecondary)
                    }
                    Spacer()
                }
                .padding(.vertical, FPTheme.spacing16)
            } else {
                ForEach(viewModel.todayUsageByMode, id: \.modeName) { item in
                    HStack(spacing: 10) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(ModeColor.adaptive(lightHex: item.colorHex))
                            .frame(width: 4, height: 28)

                        Text(item.modeName)
                            .font(.subheadline)
                            .foregroundStyle(FPTheme.textPrimary)

                        Spacer()

                        Text(viewModel.formatDuration(item.duration))
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(FPTheme.textSecondary)
                    }
                }
            }
        }
        .padding()
        .background(FPTheme.backgroundSecondary, in: RoundedRectangle(cornerRadius: FPTheme.cardRadius))
    }

    // MARK: - Weekly Chart

    private var weeklyChartSection: some View {
        VStack(alignment: .leading, spacing: FPTheme.spacing12) {
            Text("This Week")
                .font(FPTheme.sectionTitleFont)
                .foregroundStyle(FPTheme.textPrimary)

            HStack(alignment: .bottom, spacing: 8) {
                ForEach(Array(viewModel.weeklyData.enumerated()), id: \.offset) { _, day in
                    let isToday = Calendar.current.isDateInToday(day.date)
                    VStack(spacing: 6) {
                        weeklyBar(day: day)
                        Text(dayLabel(day.date))
                            .font(.system(size: 10, weight: isToday ? .bold : .regular))
                            .foregroundStyle(isToday ? FPTheme.textPrimary : FPTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(dayLabel(day.date)): \(Int(day.totalMinutes)) minutes")
                }
            }
            .frame(height: 140)
        }
        .padding()
        .background(FPTheme.backgroundSecondary, in: RoundedRectangle(cornerRadius: FPTheme.cardRadius))
    }

    @ViewBuilder
    private func weeklyBar(day: (date: Date, totalMinutes: Double, segments: [(colorHex: String, minutes: Double)])) -> some View {
        let maxMinutes: Double = max(viewModel.weeklyData.map(\.totalMinutes).max() ?? 1, 1)
        let barFraction = CGFloat(day.totalMinutes / maxMinutes)

        GeometryReader { geo in
            VStack(spacing: 0) {
                Spacer()
                if day.segments.isEmpty {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(FPTheme.divider)
                        .frame(height: 4)
                } else {
                    let totalHeight = max(4, barFraction * geo.size.height * 0.9)
                    VStack(spacing: 1) {
                        ForEach(Array(day.segments.enumerated()), id: \.offset) { _, segment in
                            let segFraction = segment.minutes / day.totalMinutes
                            let height = max(2, CGFloat(segFraction) * totalHeight)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(ModeColor.adaptive(lightHex: segment.colorHex))
                                .frame(height: height)
                        }
                    }
                    .frame(height: totalHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }
        }
    }

    private func dayLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return String(formatter.string(from: date).prefix(3))
    }

    // MARK: - Streak Card

    private var streakCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "flame.fill")
                .font(.title2)
                .foregroundStyle(Color(hex: "#F0C9A6"))
                .frame(width: 48, height: 48)
                .background(Color(hex: "#F0C9A6").opacity(0.15), in: RoundedRectangle(cornerRadius: FPTheme.smallRadius))

            VStack(alignment: .leading, spacing: 2) {
                Text("Current Streak")
                    .font(FPTheme.captionFont)
                    .foregroundStyle(FPTheme.textSecondary)
                Text("\(viewModel.streakDays) day\(viewModel.streakDays == 1 ? "" : "s")")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(FPTheme.textPrimary)
            }

            Spacer()
        }
        .padding()
        .background(FPTheme.backgroundSecondary, in: RoundedRectangle(cornerRadius: FPTheme.cardRadius))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Current streak: \(viewModel.streakDays) day\(viewModel.streakDays == 1 ? "" : "s")")
    }
}

// MARK: - Pulse Animation Modifier

private struct PulseModifier: ViewModifier {
    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .opacity(isPulsing ? 0.4 : 1.0)
            .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: isPulsing)
            .onAppear { isPulsing = true }
    }
}
