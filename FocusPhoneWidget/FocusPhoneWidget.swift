import WidgetKit
import SwiftUI

// MARK: - Data Types

struct WidgetTimeBlock {
    let startHour: Int
    let startMinute: Int
    let endHour: Int
    let endMinute: Int
    let modeName: String
    let modeColorHex: String
    let modeIcon: String
}

struct FocusPhoneWidgetEntry: TimelineEntry {
    let date: Date
    let modeName: String
    let modeIcon: String
    let modeColorHex: String
    let todayBlocks: [WidgetTimeBlock]
    let nextTransitionTime: String?
    let nextTransitionMode: String?
}

// MARK: - Provider

struct FocusPhoneWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> FocusPhoneWidgetEntry {
        FocusPhoneWidgetEntry(
            date: .now,
            modeName: "Deep Work",
            modeIcon: "brain.head.profile",
            modeColorHex: "#4A90D9",
            todayBlocks: [],
            nextTransitionTime: "2:00 PM",
            nextTransitionMode: "Exercise"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (FocusPhoneWidgetEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FocusPhoneWidgetEntry>) -> Void) {
        let entry = currentEntry()
        let timeline = Timeline(entries: [entry], policy: .after(.now.addingTimeInterval(15 * 60)))
        completion(timeline)
    }

    private func currentEntry() -> FocusPhoneWidgetEntry {
        let appState = AppState.shared
        let now = Date()
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: now)

        let blocks = appState.timeBlocks(forDay: weekday)
        let modes = appState.modes

        let widgetBlocks: [WidgetTimeBlock] = blocks.compactMap { block in
            guard let mode = modes.first(where: { $0.id == block.modeID }) else { return nil }
            return WidgetTimeBlock(
                startHour: block.startHour,
                startMinute: block.startMinute,
                endHour: block.endHour,
                endMinute: block.endMinute,
                modeName: mode.name,
                modeColorHex: mode.colorHex,
                modeIcon: mode.icon
            )
        }.sorted { ($0.startHour * 60 + $0.startMinute) < ($1.startHour * 60 + $1.startMinute) }

        // Find next transition
        let currentMinutes = calendar.component(.hour, from: now) * 60 + calendar.component(.minute, from: now)
        var nextTime: String?
        var nextMode: String?

        for block in widgetBlocks {
            let blockStart = block.startHour * 60 + block.startMinute
            if blockStart > currentMinutes {
                var comps = calendar.dateComponents([.year, .month, .day], from: now)
                comps.hour = block.startHour
                comps.minute = block.startMinute
                if let date = calendar.date(from: comps) {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "h:mm a"
                    nextTime = formatter.string(from: date)
                }
                nextMode = block.modeName
                break
            }
        }

        // Current mode
        let modeName: String
        let modeIcon: String
        let modeColorHex: String

        if let activeModeID = appState.activeModeID,
           let activeMode = modes.first(where: { $0.id == activeModeID }) {
            modeName = activeMode.name
            modeIcon = activeMode.icon
            modeColorHex = activeMode.colorHex
        } else {
            modeName = "No Active Mode"
            modeIcon = "calendar"
            modeColorHex = "#8E8E93"
        }

        return FocusPhoneWidgetEntry(
            date: now,
            modeName: modeName,
            modeIcon: modeIcon,
            modeColorHex: modeColorHex,
            todayBlocks: widgetBlocks,
            nextTransitionTime: nextTime,
            nextTransitionMode: nextMode
        )
    }
}

// MARK: - Small Widget

struct SmallWidgetView: View {
    var entry: FocusPhoneWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: entry.modeIcon)
                    .font(.title3)
                    .foregroundStyle(Color(hex: entry.modeColorHex))
                Spacer()
                Text("FP")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(entry.modeName)
                .font(.headline)
                .lineLimit(2)

            if let nextTime = entry.nextTransitionTime,
               let nextMode = entry.nextTransitionMode {
                Text("Next: \(nextMode)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text(nextTime)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(Color(hex: entry.modeColorHex))
            }
        }
        .padding()
        .containerBackground(for: .widget) {
            Color(hex: entry.modeColorHex).opacity(0.08)
        }
    }
}

// MARK: - Medium Widget

struct MediumWidgetView: View {
    var entry: FocusPhoneWidgetEntry

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: entry.modeIcon)
                    .font(.title2)
                    .foregroundStyle(Color(hex: entry.modeColorHex))

                Spacer()

                Text(entry.modeName)
                    .font(.headline)
                    .lineLimit(2)

                if let nextTime = entry.nextTransitionTime,
                   let nextMode = entry.nextTransitionMode {
                    Text("Next: \(nextMode) at \(nextTime)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            MiniTimelineView(blocks: entry.todayBlocks)
                .frame(width: 80)
        }
        .padding()
        .containerBackground(for: .widget) {
            Color(hex: entry.modeColorHex).opacity(0.08)
        }
    }
}

struct MiniTimelineView: View {
    let blocks: [WidgetTimeBlock]
    private let startHour = 6
    private let endHour = 24
    private var totalMinutes: CGFloat { CGFloat((endHour - startHour) * 60) }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))

                ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                    let startMin = CGFloat(max(0, block.startHour * 60 + block.startMinute - startHour * 60))
                    let endMin = CGFloat(min(Int(totalMinutes), block.endHour * 60 + block.endMinute - startHour * 60))
                    let top = startMin / totalMinutes * geo.size.height
                    let height = max(2, (endMin - startMin) / totalMinutes * geo.size.height)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(hex: block.modeColorHex))
                        .frame(height: height)
                        .offset(y: top)
                }

                let now = Date()
                let calendar = Calendar.current
                let currentMin = CGFloat(calendar.component(.hour, from: now) * 60 + calendar.component(.minute, from: now) - startHour * 60)
                let timeY = currentMin / totalMinutes * geo.size.height

                if currentMin >= 0 && currentMin <= totalMinutes {
                    Circle()
                        .fill(.red)
                        .frame(width: 6, height: 6)
                        .offset(y: timeY - 3)
                }
            }
        }
    }
}

// MARK: - Large Widget

struct LargeWidgetView: View {
    var entry: FocusPhoneWidgetEntry
    private let startHour = 6
    private let endHour = 24

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: entry.modeIcon)
                    .foregroundStyle(Color(hex: entry.modeColorHex))
                Text(entry.modeName)
                    .font(.headline)
                Spacer()
                Text("Today")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            GeometryReader { geo in
                let totalMinutes = CGFloat((endHour - startHour) * 60)
                let labelsWidth: CGFloat = 36
                let blocksWidth = geo.size.width - labelsWidth - 4

                ZStack(alignment: .topLeading) {
                    ForEach(startHour..<endHour, id: \.self) { hour in
                        let y = CGFloat((hour - startHour) * 60) / totalMinutes * geo.size.height
                        HStack(spacing: 4) {
                            Text(hourLabel(hour))
                                .font(.system(size: 9))
                                .foregroundStyle(.tertiary)
                                .frame(width: labelsWidth, alignment: .trailing)
                            Rectangle()
                                .fill(Color(.systemGray5))
                                .frame(height: 0.5)
                        }
                        .offset(y: y - 6)
                    }

                    ForEach(Array(entry.todayBlocks.enumerated()), id: \.offset) { _, block in
                        let startMin = CGFloat(max(0, block.startHour * 60 + block.startMinute - startHour * 60))
                        let endMin = CGFloat(min(Int(totalMinutes), block.endHour * 60 + block.endMinute - startHour * 60))
                        let top = startMin / totalMinutes * geo.size.height
                        let height = max(4, (endMin - startMin) / totalMinutes * geo.size.height)

                        HStack(spacing: 0) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color(hex: block.modeColorHex))
                                .frame(width: 3)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(hex: block.modeColorHex).opacity(0.15))
                                .overlay(alignment: .leading) {
                                    if height > 14 {
                                        Text(block.modeName)
                                            .font(.system(size: 9))
                                            .foregroundStyle(Color(hex: block.modeColorHex))
                                            .lineLimit(1)
                                            .padding(.leading, 4)
                                    }
                                }
                        }
                        .frame(width: blocksWidth, height: height)
                        .offset(x: labelsWidth + 4, y: top)
                    }

                    let now = Date()
                    let calendar = Calendar.current
                    let currentMin = CGFloat(calendar.component(.hour, from: now) * 60 + calendar.component(.minute, from: now) - startHour * 60)
                    let timeY = currentMin / totalMinutes * geo.size.height

                    if currentMin >= 0 && currentMin <= totalMinutes {
                        HStack(spacing: 0) {
                            Circle()
                                .fill(.red)
                                .frame(width: 6, height: 6)
                                .offset(x: labelsWidth + 1)
                            Rectangle()
                                .fill(.red)
                                .frame(height: 1)
                                .offset(x: labelsWidth + 1)
                        }
                        .offset(y: timeY - 3)
                    }
                }
            }
        }
        .padding()
        .containerBackground(for: .widget) {
            Color(hex: entry.modeColorHex).opacity(0.05)
        }
    }

    private func hourLabel(_ hour: Int) -> String {
        if hour == 0 || hour == 24 { return "12a" }
        if hour == 12 { return "12p" }
        if hour < 12 { return "\(hour)a" }
        return "\(hour - 12)p"
    }
}

// MARK: - Entry View Router

struct FocusPhoneWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: FocusPhoneWidgetEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Widget

@main
struct FocusPhoneWidget: Widget {
    let kind = "FocusPhoneWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FocusPhoneWidgetProvider()) { entry in
            FocusPhoneWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("FocusPhone")
        .description("See your current mode and today's schedule.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
