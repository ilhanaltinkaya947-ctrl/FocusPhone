import WidgetKit
import SwiftUI

// MARK: - Data Types

struct WidgetTimedApp {
    let appName: String
    let isWindowOpen: Bool
    let minutesRemaining: Int?
    let nextWindowTime: String?
}

struct FocusPhoneWidgetEntry: TimelineEntry {
    let date: Date
    let isRestricted: Bool
    let timedApps: [WidgetTimedApp]
    let extensionMinutesUsed: Int
    let extensionMinutesCap: Int
    let summary: String?
}

// MARK: - Provider

struct FocusPhoneWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> FocusPhoneWidgetEntry {
        FocusPhoneWidgetEntry(
            date: .now,
            isRestricted: true,
            timedApps: [
                WidgetTimedApp(appName: "Instagram", isWindowOpen: false, minutesRemaining: nil, nextWindowTime: "2:00 PM"),
            ],
            extensionMinutesUsed: 10,
            extensionMinutesCap: 30,
            summary: "Your phone is restricted"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (FocusPhoneWidgetEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FocusPhoneWidgetEntry>) -> Void) {
        let entry = currentEntry()
        let refreshDate = Date.now.addingTimeInterval(5 * 60) // refresh every 5 min
        let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
        completion(timeline)
    }

    private func currentEntry() -> FocusPhoneWidgetEntry {
        let appState = AppState.shared
        let profile = appState.restrictionProfile
        let windowStates = appState.timedWindowStates
        let slots = profile.map { TimedWindowService.generateAllSlots(for: $0) } ?? []
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"

        let timedApps: [WidgetTimedApp] = windowStates.map { app in
            let isOpen = TimedWindowService.isWindowOpen(for: app.id, in: slots)
            let remaining = TimedWindowService.remainingTime(for: app.id, in: slots)
            let nextTime = TimedWindowService.nextWindowTime(for: app.id, in: slots)
            return WidgetTimedApp(
                appName: app.appName,
                isWindowOpen: isOpen,
                minutesRemaining: remaining,
                nextWindowTime: nextTime.map { formatter.string(from: $0) }
            )
        }

        return FocusPhoneWidgetEntry(
            date: .now,
            isRestricted: appState.isRestrictionActive,
            timedApps: timedApps,
            extensionMinutesUsed: appState.dailyExtensionMinutesUsed,
            extensionMinutesCap: profile?.dailyExtensionCapMinutes ?? 30,
            summary: profile?.onboardingSummary
        )
    }
}

// MARK: - Small Widget

struct SmallWidgetView: View {
    var entry: FocusPhoneWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: entry.isRestricted ? "lock.fill" : "lock.open.fill")
                    .font(.title3)
                    .foregroundStyle(entry.isRestricted ? .blue : .gray)
                Spacer()
            }

            Spacer()

            Text(entry.isRestricted ? "Restricted" : "Unrestricted")
                .font(.headline)

            if let app = entry.timedApps.first(where: { $0.isWindowOpen }) {
                Text("\(app.appName): \(app.minutesRemaining ?? 0)m left")
                    .font(.caption2)
                    .foregroundStyle(.green)
            } else if let app = entry.timedApps.first, let nextTime = app.nextWindowTime {
                Text("\(app.appName) at \(nextTime)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .widgetURL(URL(string: "focusphone://dashboard"))
        .containerBackground(for: .widget) {
            Color.blue.opacity(entry.isRestricted ? 0.08 : 0.03)
        }
    }
}

// MARK: - Medium Widget

struct MediumWidgetView: View {
    var entry: FocusPhoneWidgetEntry

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: entry.isRestricted ? "lock.fill" : "lock.open.fill")
                        .font(.title2)
                        .foregroundStyle(entry.isRestricted ? .blue : .gray)
                }

                Spacer()

                Text(entry.isRestricted ? "Restricted" : "Unrestricted")
                    .font(.headline)

                Text("\(entry.extensionMinutesUsed)/\(entry.extensionMinutesCap)m extensions")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Timed apps list
            VStack(alignment: .leading, spacing: 4) {
                ForEach(entry.timedApps.prefix(3), id: \.appName) { app in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(app.isWindowOpen ? Color.green : Color.orange)
                            .frame(width: 6, height: 6)
                        Text(app.appName)
                            .font(.caption2)
                        Spacer()
                        if app.isWindowOpen, let mins = app.minutesRemaining {
                            Text("\(mins)m")
                                .font(.caption2.bold())
                                .foregroundStyle(.green)
                        } else if let time = app.nextWindowTime {
                            Text(time)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .widgetURL(URL(string: "focusphone://dashboard"))
        .containerBackground(for: .widget) {
            Color.blue.opacity(entry.isRestricted ? 0.08 : 0.03)
        }
    }
}

// MARK: - Large Widget

struct LargeWidgetView: View {
    var entry: FocusPhoneWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: entry.isRestricted ? "lock.fill" : "lock.open.fill")
                    .foregroundStyle(entry.isRestricted ? .blue : .gray)
                Text(entry.isRestricted ? "Phone Restricted" : "Unrestricted")
                    .font(.headline)
                Spacer()
                Text("\(entry.extensionMinutesUsed)/\(entry.extensionMinutesCap)m")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.blue)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.15), in: Capsule())
            }

            if let summary = entry.summary {
                Text(summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            // Timed apps
            ForEach(entry.timedApps, id: \.appName) { app in
                HStack(spacing: 8) {
                    Circle()
                        .fill(app.isWindowOpen ? Color.green : Color.orange)
                        .frame(width: 8, height: 8)

                    Text(app.appName)
                        .font(.subheadline)

                    Spacer()

                    if app.isWindowOpen, let mins = app.minutesRemaining {
                        Text("\(mins)m left")
                            .font(.caption.bold())
                            .foregroundStyle(.green)
                    } else if let time = app.nextWindowTime {
                        Text("Next: \(time)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Blocked")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }

            Spacer()
        }
        .padding()
        .widgetURL(URL(string: "focusphone://dashboard"))
        .containerBackground(for: .widget) {
            Color.blue.opacity(entry.isRestricted ? 0.05 : 0.02)
        }
    }
}

// MARK: - Lock Screen Widgets

struct AccessoryCircularView: View {
    var entry: FocusPhoneWidgetEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            Image(systemName: entry.isRestricted ? "lock.fill" : "lock.open.fill")
                .font(.title3)
        }
    }
}

struct AccessoryRectangularView: View {
    var entry: FocusPhoneWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: "lock.fill")
                    .font(.caption)
                Text(entry.isRestricted ? "Restricted" : "Unrestricted")
                    .font(.headline)
                    .lineLimit(1)
            }

            if let app = entry.timedApps.first(where: { $0.isWindowOpen }),
               let mins = app.minutesRemaining {
                Text("\(app.appName) — \(mins)m left")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("\(entry.extensionMinutesUsed)/\(entry.extensionMinutesCap)m extensions used")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .widgetURL(URL(string: "focusphone://dashboard"))
    }
}

struct AccessoryInlineView: View {
    var entry: FocusPhoneWidgetEntry

    var body: some View {
        if let app = entry.timedApps.first(where: { $0.isWindowOpen }),
           let mins = app.minutesRemaining {
            Label("\(app.appName) \(mins)m", systemImage: "timer")
        } else {
            Label(entry.isRestricted ? "Restricted" : "Unrestricted", systemImage: "lock.fill")
        }
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
        case .accessoryCircular:
            AccessoryCircularView(entry: entry)
        case .accessoryRectangular:
            AccessoryRectangularView(entry: entry)
        case .accessoryInline:
            AccessoryInlineView(entry: entry)
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
        .description("See your restriction status and timed window apps.")
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
