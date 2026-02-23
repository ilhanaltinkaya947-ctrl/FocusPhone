import Foundation
import UserNotifications

// MARK: - Notification Event

struct NotificationEvent: Codable, Identifiable {
    let id: UUID
    let type: String
    let sentAt: Date
    let hour: Int
    var opened: Bool
    var openedAt: Date?

    init(type: String, sentAt: Date = Date()) {
        self.id = UUID()
        self.type = type
        self.sentAt = sentAt
        self.hour = Calendar.current.component(.hour, from: sentAt)
        self.opened = false
        self.openedAt = nil
    }
}

// MARK: - Notification Intelligence Service

final class NotificationIntelligenceService {
    static let shared = NotificationIntelligenceService()

    private static let eventsKey = "notifIntelligenceEvents"
    private static let dailyCountKey = "notifIntelligenceDailyCount"
    private static let dailyCountDateKey = "notifIntelligenceDailyCountDate"

    static let maxPerDay = 4
    static let reduceThreshold = 3 // consecutive ignored → reduce frequency

    // MARK: - Persistence

    var events: [NotificationEvent] {
        get { AppState.shared.load(forKey: Self.eventsKey) ?? [] }
        set { AppState.shared.save(newValue, forKey: Self.eventsKey) }
    }

    private var todaySentCount: Int {
        get {
            let savedDate = Constants.sharedDefaults.object(forKey: Self.dailyCountDateKey) as? Date
            if let date = savedDate, Calendar.current.isDateInToday(date) {
                return Constants.sharedDefaults.integer(forKey: Self.dailyCountKey)
            }
            return 0
        }
        set {
            Constants.sharedDefaults.set(newValue, forKey: Self.dailyCountKey)
            Constants.sharedDefaults.set(Date(), forKey: Self.dailyCountDateKey)
        }
    }

    // MARK: - Can Send Check

    /// Returns true if we should send a notification now (respects fatigue limits)
    func canSend(type: String) -> Bool {
        // Max per day limit
        guard todaySentCount < Self.maxPerDay else { return false }

        // Check consecutive ignored
        let recentEvents = events.suffix(Self.reduceThreshold)
        let allIgnored = recentEvents.count >= Self.reduceThreshold && recentEvents.allSatisfy({ !$0.opened })

        if allIgnored {
            // Only allow critical notifications (streak milestones, comeback)
            let criticalTypes = ["streak_milestone", "streak_broken", "comeback"]
            return criticalTypes.contains(type)
        }

        return true
    }

    // MARK: - Record Sent

    func recordSent(type: String) {
        var list = events
        list.append(NotificationEvent(type: type))
        // Keep last 90 days
        let cutoff = Calendar.current.date(byAdding: .day, value: -90, to: Date()) ?? Date()
        list.removeAll { $0.sentAt < cutoff }
        events = list
        todaySentCount += 1
    }

    // MARK: - Record Opened

    func recordOpened(type: String) {
        var list = events
        // Find most recent unopened event of this type
        if let idx = list.lastIndex(where: { $0.type == type && !$0.opened }) {
            list[idx].opened = true
            list[idx].openedAt = Date()
            events = list
        }
    }

    // MARK: - Open Rate Analytics

    /// Open rate for a specific notification type (0.0 - 1.0)
    func openRate(for type: String) -> Double {
        let typeEvents = events.filter { $0.type == type }
        guard !typeEvents.isEmpty else { return 0 }
        let opened = typeEvents.filter(\.opened).count
        return Double(opened) / Double(typeEvents.count)
    }

    /// Overall open rate across all types
    var overallOpenRate: Double {
        guard !events.isEmpty else { return 0 }
        let opened = events.filter(\.opened).count
        return Double(opened) / Double(events.count)
    }

    /// Best hour to send notifications (highest open rate)
    var bestHour: Int? {
        let hourGroups = Dictionary(grouping: events, by: \.hour)
        var bestRate = 0.0
        var bestH: Int?

        for (hour, hourEvents) in hourGroups {
            let opened = hourEvents.filter(\.opened).count
            let rate = Double(opened) / Double(hourEvents.count)
            if rate > bestRate {
                bestRate = rate
                bestH = hour
            }
        }

        return bestH
    }

    /// Worst hours (lowest open rate) — avoid scheduling here
    var worstHours: [Int] {
        let hourGroups = Dictionary(grouping: events, by: \.hour)
        return hourGroups
            .filter { $0.value.count >= 3 } // need enough data
            .sorted { hourRate($0.value) < hourRate($1.value) }
            .prefix(3)
            .map(\.key)
    }

    private func hourRate(_ events: [NotificationEvent]) -> Double {
        guard !events.isEmpty else { return 0 }
        return Double(events.filter(\.opened).count) / Double(events.count)
    }

    // MARK: - Optimal Time Suggestion

    /// Suggests a SimpleTime for a notification type based on open rate data
    func optimalTime(for type: String, fallback: SimpleTime) -> SimpleTime {
        let typeEvents = events.filter { $0.type == type }
        guard typeEvents.count >= 5 else { return fallback } // need enough data

        let openedEvents = typeEvents.filter(\.opened)
        guard !openedEvents.isEmpty else { return fallback }

        // Average hour of opened notifications
        let avgHour = openedEvents.map(\.hour).reduce(0, +) / openedEvents.count
        return SimpleTime(hour: avgHour, minute: 0)
    }

    // MARK: - Fatigue Detection

    /// Number of consecutive ignored notifications
    var consecutiveIgnored: Int {
        var count = 0
        for event in events.reversed() {
            if event.opened { break }
            count += 1
        }
        return count
    }

    /// True if user is in fatigue state (3+ consecutive ignored)
    var isFatigued: Bool {
        consecutiveIgnored >= Self.reduceThreshold
    }

    /// Suggested max per day based on engagement patterns
    var suggestedMaxPerDay: Int {
        if isFatigued { return 2 }
        if overallOpenRate < 0.3 { return 3 }
        return Self.maxPerDay
    }

    // MARK: - Smart Grouping

    /// Groups multiple pending notifications into fewer, combined ones
    func shouldGroup(types: [String]) -> Bool {
        // If 3+ notifications pending within same hour, group them
        return types.count >= 3
    }

    func groupedMessage(types: [String], messages: [String]) -> String {
        guard messages.count > 1 else { return messages.first ?? "" }
        // Combine into a single notification
        return messages.prefix(2).joined(separator: " | ")
    }

    // MARK: - Weekly Report

    struct WeeklyNotifReport {
        let totalSent: Int
        let totalOpened: Int
        let openRate: Double
        let bestHour: Int?
        let mostEngagedType: String?
        let leastEngagedType: String?
    }

    func weeklyReport() -> WeeklyNotifReport {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let weekEvents = events.filter { $0.sentAt >= weekAgo }

        let opened = weekEvents.filter(\.opened)

        let typeGroups = Dictionary(grouping: weekEvents, by: \.type)
        let typeRates = typeGroups.mapValues { events -> Double in
            guard !events.isEmpty else { return 0 }
            return Double(events.filter(\.opened).count) / Double(events.count)
        }

        let mostEngaged = typeRates.max(by: { $0.value < $1.value })?.key
        let leastEngaged = typeRates.min(by: { $0.value < $1.value })?.key

        return WeeklyNotifReport(
            totalSent: weekEvents.count,
            totalOpened: opened.count,
            openRate: weekEvents.isEmpty ? 0 : Double(opened.count) / Double(weekEvents.count),
            bestHour: bestHour,
            mostEngagedType: mostEngaged,
            leastEngagedType: leastEngaged
        )
    }
}
