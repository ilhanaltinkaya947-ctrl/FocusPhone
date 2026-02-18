import SwiftUI

struct StatsView: View {
    @StateObject private var viewModel = StatsViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    activeModeCard
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
            HStack(spacing: 12) {
                Image(systemName: mode.icon)
                    .font(.title)
                    .foregroundStyle(Color(hex: mode.colorHex))
                    .frame(width: 44, height: 44)
                    .background(Color(hex: mode.colorHex).opacity(0.12), in: RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Currently Active")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(mode.name)
                        .font(.title3)
                        .fontWeight(.semibold)
                }

                Spacer()
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        } else {
            HStack(spacing: 12) {
                Image(systemName: "moon.zzz.fill")
                    .font(.title)
                    .foregroundStyle(.secondary)
                    .frame(width: 44, height: 44)
                    .background(Color(.systemGray5), in: RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Currently")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("No Active Mode")
                        .font(.title3)
                        .fontWeight(.semibold)
                }

                Spacer()
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: - Today's Usage

    private var todayUsageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today")
                .font(.headline)

            if viewModel.todayUsageByMode.isEmpty {
                Text("No sessions recorded today")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                ForEach(viewModel.todayUsageByMode, id: \.modeName) { item in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color(hex: item.colorHex))
                            .frame(width: 10, height: 10)
                        Text(item.modeName)
                            .font(.subheadline)
                        Spacer()
                        Text(viewModel.formatDuration(item.duration))
                            .font(.subheadline)
                            .fontWeight(.medium)
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
                ForEach(Array(viewModel.weeklyData.enumerated()), id: \.offset) { _, day in
                    VStack(spacing: 4) {
                        weeklyBar(day: day)
                        Text(dayLabel(day.date))
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
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
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(.systemGray5))
                        .frame(height: 4)
                } else {
                    let totalHeight = max(4, barFraction * geo.size.height * 0.9)
                    VStack(spacing: 1) {
                        ForEach(Array(day.segments.enumerated()), id: \.offset) { _, segment in
                            let segFraction = segment.minutes / day.totalMinutes
                            let height = max(2, CGFloat(segFraction) * totalHeight)
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color(hex: segment.colorHex))
                                .frame(height: height)
                        }
                    }
                    .frame(height: totalHeight)
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
        HStack(spacing: 12) {
            Image(systemName: "flame.fill")
                .font(.title)
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text("Current Streak")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(viewModel.streakDays) day\(viewModel.streakDays == 1 ? "" : "s")")
                    .font(.title3)
                    .fontWeight(.semibold)
            }

            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}
