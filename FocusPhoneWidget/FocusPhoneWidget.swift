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
    let isActive: Bool
    let todayBlocks: [WidgetTimeBlock]
    let nextTransitionTime: String?
    let nextTransitionMode: String?
    let minutesRemaining: Int?
}

// MARK: - Provider

struct FocusPhoneWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> FocusPhoneWidgetEntry {
        FocusPhoneWidgetEntry(
            date: .now,
            modeName: "Deep Work",
            modeIcon: "brain.head.profile",
            modeColorHex: "#4A90D9",
            isActive: true,
            todayBlocks: [],
            nextTransitionTime: "2:00 PM",
            nextTransitionMode: "Exercise",
            minutesRemaining: 45
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (FocusPhoneWidgetEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FocusPhoneWidgetEntry>) -> Void) {
        let entry = currentEntry()

        // Refresh at the next block transition, or in 15 min if no upcoming transition
        let refreshDate = nextTransitionDate() ?? .now.addingTimeInterval(15 * 60)
        let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
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

        // Find current & next transition
        let currentMinutes = calendar.component(.hour, from: now) * 60 + calendar.component(.minute, from: now)
        var nextTime: String?
        var nextMode: String?
        var minutesRemaining: Int?

        // Check if currently inside a block — compute remaining minutes
        for block in widgetBlocks {
            let blockStart = block.startHour * 60 + block.startMinute
            let blockEnd = block.endHour * 60 + block.endMinute
            if currentMinutes >= blockStart && currentMinutes < blockEnd {
                minutesRemaining = blockEnd - currentMinutes
                break
            }
        }

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
        let isActive: Bool

        if let activeModeID = appState.activeModeID,
           let activeMode = modes.first(where: { $0.id == activeModeID }) {
            modeName = activeMode.name
            modeIcon = activeMode.icon
            modeColorHex = activeMode.colorHex
            isActive = true
        } else {
            modeName = "No Active Mode"
            modeIcon = "calendar"
            modeColorHex = "#8E8E93"
            isActive = false
        }

        return FocusPhoneWidgetEntry(
            date: now,
            modeName: modeName,
            modeIcon: modeIcon,
            modeColorHex: modeColorHex,
            isActive: isActive,
            todayBlocks: widgetBlocks,
            nextTransitionTime: nextTime,
            nextTransitionMode: nextMode,
            minutesRemaining: minutesRemaining
        )
    }

    /// Returns the Date of the nearest block start/end so the widget refreshes exactly at transitions.
    private func nextTransitionDate() -> Date? {
        let now = Date()
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: now)
        let currentMinutes = calendar.component(.hour, from: now) * 60 + calendar.component(.minute, from: now)

        let blocks = AppState.shared.timeBlocks(forDay: weekday)
        var candidates: [Int] = []

        for block in blocks {
            let start = block.startHour * 60 + block.startMinute
            let end = block.endHour * 60 + block.endMinute
            if start > currentMinutes { candidates.append(start) }
            if end > currentMinutes { candidates.append(end) }
        }

        guard let nextMinutes = candidates.min() else { return nil }

        var comps = calendar.dateComponents([.year, .month, .day], from: now)
        comps.hour = nextMinutes / 60
        comps.minute = nextMinutes % 60
        comps.second = 5 // small buffer past the transition
        return calendar.date(from: comps)
    }
}

// MARK: - Small Widget

struct SmallWidgetView: View {
    var entry: FocusPhoneWidgetEntry
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: entry.modeIcon)
                    .font(.title3)
                    .foregroundStyle(color)
                Spacer()
                if entry.isActive, let mins = entry.minutesRemaining {
                    Text("\(mins)m")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(color)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(color.opacity(0.15), in: Capsule())
                }
            }

            Spacer()

            Text(entry.modeName)
                .font(.headline)
                .lineLimit(2)

            if let nextMode = entry.nextTransitionMode,
               let nextTime = entry.nextTransitionTime {
                Text("\(nextMode) at \(nextTime)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            } else if !entry.isActive {
                Text("No upcoming blocks")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .widgetURL(URL(string: "focusphone://calendar"))
        .containerBackground(for: .widget) {
            color.opacity(0.08)
        }
    }
}

// MARK: - Medium Widget

struct MediumWidgetView: View {
    var entry: FocusPhoneWidgetEntry
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: entry.modeIcon)
                        .font(.title2)
                        .foregroundStyle(color)
                    if entry.isActive, let mins = entry.minutesRemaining {
                        Text("\(mins)m left")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(color)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(color.opacity(0.15), in: Capsule())
                    }
                }

                Spacer()

                Text(entry.modeName)
                    .font(.headline)
                    .lineLimit(2)

                if let nextMode = entry.nextTransitionMode,
                   let nextTime = entry.nextTransitionTime {
                    Text("Next: \(nextMode) at \(nextTime)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            MiniTimelineView(blocks: entry.todayBlocks, modeColorHex: entry.modeColorHex)
                .frame(width: 80)
        }
        .padding()
        .widgetURL(URL(string: "focusphone://calendar"))
        .containerBackground(for: .widget) {
            color.opacity(0.08)
        }
    }
}

// MARK: - Mini Timeline (for Medium Widget)

struct MiniTimelineView: View {
    let blocks: [WidgetTimeBlock]
    let modeColorHex: String
    private let startHour = 6
    private let endHour = 24
    private var totalMinutes: CGFloat { CGFloat((endHour - startHour) * 60) }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(.systemGray5).opacity(0.5))

                ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                    let startMin = CGFloat(max(0, block.startHour * 60 + block.startMinute - startHour * 60))
                    let endMin = CGFloat(min(Int(totalMinutes), block.endHour * 60 + block.endMinute - startHour * 60))
                    let top = startMin / totalMinutes * geo.size.height
                    let height = max(2, (endMin - startMin) / totalMinutes * geo.size.height)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(hex: block.modeColorHex))
                        .frame(height: height)
                        .padding(.horizontal, 2)
                        .offset(y: top)
                }

                // Current time indicator
                let now = Date()
                let calendar = Calendar.current
                let currentMin = CGFloat(calendar.component(.hour, from: now) * 60 + calendar.component(.minute, from: now) - startHour * 60)
                let timeY = currentMin / totalMinutes * geo.size.height

                if currentMin >= 0 && currentMin <= totalMinutes {
                    Capsule()
                        .fill(.red)
                        .frame(width: 10, height: 3)
                        .offset(y: timeY - 1.5)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

// MARK: - Large Widget

struct LargeWidgetView: View {
    var entry: FocusPhoneWidgetEntry
    let color: Color
    private let startHour = 6
    private let endHour = 24

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: entry.modeIcon)
                    .foregroundStyle(color)
                Text(entry.modeName)
                    .font(.headline)
                Spacer()
                if entry.isActive, let mins = entry.minutesRemaining {
                    Text("\(mins)m left")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(color)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(color.opacity(0.15), in: Capsule())
                } else {
                    Text("Today")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Timeline
            GeometryReader { geo in
                let totalMinutes = CGFloat((endHour - startHour) * 60)
                let labelsWidth: CGFloat = 32
                let blocksWidth = geo.size.width - labelsWidth - 4

                ZStack(alignment: .topLeading) {
                    // Hour grid lines
                    ForEach(startHour..<endHour, id: \.self) { hour in
                        if hour % 2 == 0 {
                            let y = CGFloat((hour - startHour) * 60) / totalMinutes * geo.size.height
                            HStack(spacing: 4) {
                                Text(hourLabel(hour))
                                    .font(.system(size: 9))
                                    .foregroundStyle(.tertiary)
                                    .frame(width: labelsWidth, alignment: .trailing)
                                Rectangle()
                                    .fill(Color(.separator).opacity(0.3))
                                    .frame(height: 0.5)
                            }
                            .offset(y: y - 6)
                        }
                    }

                    // Time blocks
                    ForEach(Array(entry.todayBlocks.enumerated()), id: \.offset) { _, block in
                        let startMin = CGFloat(max(0, block.startHour * 60 + block.startMinute - startHour * 60))
                        let endMin = CGFloat(min(Int(totalMinutes), block.endHour * 60 + block.endMinute - startHour * 60))
                        let top = startMin / totalMinutes * geo.size.height
                        let height = max(4, (endMin - startMin) / totalMinutes * geo.size.height)
                        let blockColor = Color(hex: block.modeColorHex)

                        HStack(spacing: 0) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(blockColor)
                                .frame(width: 3)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(blockColor.opacity(0.12))
                                .overlay(alignment: .leading) {
                                    if height > 14 {
                                        HStack(spacing: 3) {
                                            Image(systemName: block.modeIcon)
                                                .font(.system(size: 8))
                                            Text(block.modeName)
                                                .font(.system(size: 9))
                                        }
                                        .foregroundStyle(blockColor)
                                        .lineLimit(1)
                                        .padding(.leading, 4)
                                    }
                                }
                        }
                        .frame(width: blocksWidth, height: height)
                        .offset(x: labelsWidth + 4, y: top)
                    }

                    // Current time line
                    let now = Date()
                    let calendar = Calendar.current
                    let currentMin = CGFloat(calendar.component(.hour, from: now) * 60 + calendar.component(.minute, from: now) - startHour * 60)
                    let timeY = currentMin / totalMinutes * geo.size.height

                    if currentMin >= 0 && currentMin <= totalMinutes {
                        HStack(spacing: 0) {
                            Circle()
                                .fill(.red)
                                .frame(width: 6, height: 6)
                            Rectangle()
                                .fill(.red)
                                .frame(height: 1)
                        }
                        .offset(x: labelsWidth + 1, y: timeY - 3)
                    }
                }
            }
        }
        .padding()
        .widgetURL(URL(string: "focusphone://calendar"))
        .containerBackground(for: .widget) {
            color.opacity(0.05)
        }
    }

    private func hourLabel(_ hour: Int) -> String {
        if hour == 0 || hour == 24 { return "12a" }
        if hour == 12 { return "12p" }
        if hour < 12 { return "\(hour)a" }
        return "\(hour - 12)p"
    }
}

// MARK: - Lock Screen: Accessory Circular

struct AccessoryCircularView: View {
    var entry: FocusPhoneWidgetEntry

    var body: some View {
        if entry.isActive, let mins = entry.minutesRemaining, mins > 0 {
            Gauge(value: Double(mins), in: 0...max(Double(mins), 60)) {
                Image(systemName: entry.modeIcon)
            } currentValueLabel: {
                Text("\(mins)")
                    .font(.system(.body, design: .rounded).bold())
            }
            .gaugeStyle(.accessoryCircular)
        } else {
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: entry.isActive ? entry.modeIcon : "calendar")
                    .font(.title3)
            }
        }
    }
}

// MARK: - Lock Screen: Accessory Rectangular

struct AccessoryRectangularView: View {
    var entry: FocusPhoneWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: entry.modeIcon)
                    .font(.caption)
                Text(entry.modeName)
                    .font(.headline)
                    .lineLimit(1)
            }

            if entry.isActive, let mins = entry.minutesRemaining {
                Text("\(mins) min remaining")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if let nextMode = entry.nextTransitionMode,
                      let nextTime = entry.nextTransitionTime {
                Text("\(nextMode) at \(nextTime)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            } else {
                Text("No upcoming blocks")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .widgetURL(URL(string: "focusphone://calendar"))
    }
}

// MARK: - Lock Screen: Accessory Inline

struct AccessoryInlineView: View {
    var entry: FocusPhoneWidgetEntry

    var body: some View {
        if entry.isActive, let mins = entry.minutesRemaining {
            Label("\(entry.modeName) · \(mins)m", systemImage: entry.modeIcon)
        } else {
            Label(entry.modeName, systemImage: entry.modeIcon)
        }
    }
}

// MARK: - Entry View Router

struct FocusPhoneWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: FocusPhoneWidgetEntry

    private var color: Color { Color(hex: entry.modeColorHex) }

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry, color: color)
        case .systemMedium:
            MediumWidgetView(entry: entry, color: color)
        case .systemLarge:
            LargeWidgetView(entry: entry, color: color)
        case .accessoryCircular:
            AccessoryCircularView(entry: entry)
        case .accessoryRectangular:
            AccessoryRectangularView(entry: entry)
        case .accessoryInline:
            AccessoryInlineView(entry: entry)
        default:
            SmallWidgetView(entry: entry, color: color)
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
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline,
        ])
    }
}
