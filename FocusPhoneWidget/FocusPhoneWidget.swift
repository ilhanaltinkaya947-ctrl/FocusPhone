import WidgetKit
import SwiftUI

// MARK: - Data Types

struct WidgetTimedApp {
    let appName: String
    let isWindowOpen: Bool
    let minutesRemaining: Int?
    let nextWindowTime: String?
}

struct RawDogWidgetEntry: TimelineEntry {
    let date: Date
    let isRestricted: Bool
    let timedApps: [WidgetTimedApp]
    let extensionMinutesUsed: Int
    let extensionMinutesCap: Int
    let summary: String?
}

// MARK: - Provider

struct RawDogWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> RawDogWidgetEntry {
        RawDogWidgetEntry(
            date: .now,
            isRestricted: true,
            timedApps: [
                WidgetTimedApp(appName: "Instagram", isWindowOpen: false, minutesRemaining: nil, nextWindowTime: "2:00 PM"),
            ],
            extensionMinutesUsed: 10,
            extensionMinutesCap: 30,
            summary: "Your phone is disciplined"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (RawDogWidgetEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RawDogWidgetEntry>) -> Void) {
        let entry = currentEntry()
        let refreshDate = Date.now.addingTimeInterval(5 * 60)
        let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
        completion(timeline)
    }

    private func currentEntry() -> RawDogWidgetEntry {
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

        return RawDogWidgetEntry(
            date: .now,
            isRestricted: appState.isRestrictionActive,
            timedApps: timedApps,
            extensionMinutesUsed: appState.dailyExtensionMinutesUsed,
            extensionMinutesCap: profile?.dailyExtensionCapMinutes ?? 30,
            summary: profile?.onboardingSummary
        )
    }
}

// MARK: - Widget Colors (inline, no DesignSystem access in extension)

private enum WidgetColors {
    static let accent = Color(red: 232/255, green: 244/255, blue: 255/255)     // ice blue
    static let background = Color.black
    static let surface = Color(red: 17/255, green: 17/255, blue: 17/255)
    static let textSecondary = Color(red: 136/255, green: 136/255, blue: 136/255)
    static let windowOpen = Color(red: 52/255, green: 199/255, blue: 89/255)
    static let windowClosed = Color(red: 255/255, green: 149/255, blue: 0/255)
}

// MARK: - Small Widget

struct SmallWidgetView: View {
    var entry: RawDogWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: entry.isRestricted ? "lock.fill" : "lock.open.fill")
                    .font(.title3)
                    .foregroundStyle(entry.isRestricted ? WidgetColors.accent : WidgetColors.textSecondary)
                Spacer()
            }

            Spacer()

            Text(entry.isRestricted ? "Disciplined" : "Unrestricted")
                .font(.headline)
                .foregroundStyle(.white)

            if let app = entry.timedApps.first(where: { $0.isWindowOpen }) {
                Text("\(app.appName): \(app.minutesRemaining ?? 0)m left")
                    .font(.caption2)
                    .foregroundStyle(WidgetColors.windowOpen)
            } else if let app = entry.timedApps.first, let nextTime = app.nextWindowTime {
                Text("\(app.appName) at \(nextTime)")
                    .font(.caption2)
                    .foregroundStyle(WidgetColors.textSecondary)
            }
        }
        .padding()
        .widgetURL(URL(string: "rawdog://dashboard"))
        .containerBackground(for: .widget) {
            WidgetColors.background
        }
    }
}

// MARK: - Medium Widget

struct MediumWidgetView: View {
    var entry: RawDogWidgetEntry

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: entry.isRestricted ? "lock.fill" : "lock.open.fill")
                        .font(.title2)
                        .foregroundStyle(entry.isRestricted ? WidgetColors.accent : WidgetColors.textSecondary)
                }

                Spacer()

                Text(entry.isRestricted ? "Disciplined" : "Unrestricted")
                    .font(.headline)
                    .foregroundStyle(.white)

                Text("\(entry.extensionMinutesUsed)/\(entry.extensionMinutesCap)m extensions")
                    .font(.caption2)
                    .foregroundStyle(WidgetColors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 4) {
                ForEach(entry.timedApps.prefix(3), id: \.appName) { app in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(app.isWindowOpen ? WidgetColors.windowOpen : WidgetColors.windowClosed)
                            .frame(width: 6, height: 6)
                        Text(app.appName)
                            .font(.caption2)
                            .foregroundStyle(.white)
                        Spacer()
                        if app.isWindowOpen, let mins = app.minutesRemaining {
                            Text("\(mins)m")
                                .font(.caption2.bold())
                                .foregroundStyle(WidgetColors.windowOpen)
                        } else if let time = app.nextWindowTime {
                            Text(time)
                                .font(.caption2)
                                .foregroundStyle(WidgetColors.textSecondary)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .widgetURL(URL(string: "rawdog://dashboard"))
        .containerBackground(for: .widget) {
            WidgetColors.background
        }
    }
}

// MARK: - Large Widget

struct LargeWidgetView: View {
    var entry: RawDogWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: entry.isRestricted ? "lock.fill" : "lock.open.fill")
                    .foregroundStyle(entry.isRestricted ? WidgetColors.accent : WidgetColors.textSecondary)
                Text(entry.isRestricted ? "Disciplined" : "Unrestricted")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                Text("\(entry.extensionMinutesUsed)/\(entry.extensionMinutesCap)m")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(WidgetColors.accent)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(WidgetColors.accent.opacity(0.15), in: Capsule())
            }

            if let summary = entry.summary {
                Text(summary)
                    .font(.caption)
                    .foregroundStyle(WidgetColors.textSecondary)
            }

            Rectangle()
                .fill(WidgetColors.surface)
                .frame(height: 1)

            // Timed apps
            ForEach(entry.timedApps, id: \.appName) { app in
                HStack(spacing: 8) {
                    Circle()
                        .fill(app.isWindowOpen ? WidgetColors.windowOpen : WidgetColors.windowClosed)
                        .frame(width: 8, height: 8)

                    Text(app.appName)
                        .font(.subheadline)
                        .foregroundStyle(.white)

                    Spacer()

                    if app.isWindowOpen, let mins = app.minutesRemaining {
                        Text("\(mins)m left")
                            .font(.caption.bold())
                            .foregroundStyle(WidgetColors.windowOpen)
                    } else if let time = app.nextWindowTime {
                        Text("Next: \(time)")
                            .font(.caption)
                            .foregroundStyle(WidgetColors.textSecondary)
                    } else {
                        Text("Blocked")
                            .font(.caption)
                            .foregroundStyle(WidgetColors.windowClosed)
                    }
                }
            }

            Spacer()
        }
        .padding()
        .widgetURL(URL(string: "rawdog://dashboard"))
        .containerBackground(for: .widget) {
            WidgetColors.background
        }
    }
}

// MARK: - Lock Screen Widgets

struct AccessoryCircularView: View {
    var entry: RawDogWidgetEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            Image(systemName: entry.isRestricted ? "lock.fill" : "lock.open.fill")
                .font(.title3)
        }
    }
}

struct AccessoryRectangularView: View {
    var entry: RawDogWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: "lock.fill")
                    .font(.caption)
                Text(entry.isRestricted ? "Disciplined" : "Unrestricted")
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
        .widgetURL(URL(string: "rawdog://dashboard"))
    }
}

struct AccessoryInlineView: View {
    var entry: RawDogWidgetEntry

    var body: some View {
        if let app = entry.timedApps.first(where: { $0.isWindowOpen }),
           let mins = app.minutesRemaining {
            Label("\(app.appName) \(mins)m", systemImage: "timer")
        } else {
            Label(entry.isRestricted ? "Disciplined" : "Unrestricted", systemImage: "lock.fill")
        }
    }
}

// MARK: - Entry View Router

struct RawDogWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: RawDogWidgetEntry

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
struct RawDogWidget: Widget {
    let kind = "RawDogWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RawDogWidgetProvider()) { entry in
            RawDogWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("RawDog")
        .description("Your commitments. Your proof.")
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
