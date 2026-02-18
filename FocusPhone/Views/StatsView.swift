import SwiftUI

struct StatsView: View {
    @StateObject private var viewModel = StatsViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    activeModeCard
                    todayOverviewRow
                    todayUsageSection
                    weeklyChartSection
                    streakCard
                }
                .padding()
            }
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
                    .foregroundStyle(Color(hex: mode.colorHex))
                    .frame(width: 48, height: 48)
                    .background(Color(hex: mode.colorHex).opacity(0.12), in: RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Currently Active")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(mode.name)
                        .font(.title3.weight(.semibold))
                }

                Spacer()

                Circle()
                    .fill(Color(hex: mode.colorHex))
                    .frame(width: 10, height: 10)
                    .modifier(PulseModifier())
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: mode.colorHex).opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(Color(hex: mode.colorHex).opacity(0.2), lineWidth: 1)
                    )
            )
        } else {
            HStack(spacing: 14) {
                Image(systemName: "moon.zzz.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                    .frame(width: 48, height: 48)
                    .background(Color(.systemGray5), in: RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Currently")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("No Active Mode")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: - Today Overview (Total Focus Time + Sessions Count)

    private var todayOverviewRow: some View {
        HStack(spacing: 12) {
            statCard(
                icon: "clock.fill",
                iconColor: .blue,
                title: "Focus Time",
                value: viewModel.formatDuration(viewModel.todayTotalDuration)
            )
            statCard(
                icon: "list.bullet.circle.fill",
                iconColor: .purple,
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
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.headline)
            }

            Spacer()
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Today's Usage

    private var todayUsageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today")
                .font(.headline)

            if viewModel.todayUsageByMode.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 6) {
                        Image(systemName: "tray")
                            .font(.title2)
                            .foregroundStyle(.quaternary)
                        Text("No sessions recorded today")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 16)
            } else {
                ForEach(viewModel.todayUsageByMode, id: \.modeName) { item in
                    HStack(spacing: 10) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(hex: item.colorHex))
                            .frame(width: 4, height: 28)

                        Text(item.modeName)
                            .font(.subheadline)

                        Spacer()

                        Text(viewModel.formatDuration(item.duration))
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Weekly Chart

    private var weeklyChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Week")
                .font(.headline)

            HStack(alignment: .bottom, spacing: 8) {
                ForEach(Array(viewModel.weeklyData.enumerated()), id: \.offset) { index, day in
                    let isToday = Calendar.current.isDateInToday(day.date)
                    VStack(spacing: 6) {
                        weeklyBar(day: day)
                        Text(dayLabel(day.date))
                            .font(.system(size: 10, weight: isToday ? .bold : .regular))
                            .foregroundStyle(isToday ? .primary : .secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 140)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
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
                        .fill(Color(.systemGray5))
                        .frame(height: 4)
                } else {
                    let totalHeight = max(4, barFraction * geo.size.height * 0.9)
                    VStack(spacing: 1) {
                        ForEach(Array(day.segments.enumerated()), id: \.offset) { _, segment in
                            let segFraction = segment.minutes / day.totalMinutes
                            let height = max(2, CGFloat(segFraction) * totalHeight)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color(hex: segment.colorHex))
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
                .foregroundStyle(.orange)
                .frame(width: 48, height: 48)
                .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 2) {
                Text("Current Streak")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(viewModel.streakDays) day\(viewModel.streakDays == 1 ? "" : "s")")
                    .font(.title3.weight(.semibold))
            }

            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
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
