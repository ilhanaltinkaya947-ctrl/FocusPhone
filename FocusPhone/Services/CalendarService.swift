import Foundation
import EventKit

// MARK: - Calendar Block Model

struct CalendarBlock: Codable, Identifiable, Equatable {
    var id = UUID()
    var type: BlockType
    var title: String
    var startTime: String   // "HH:MM"
    var days: [String]      // ["monday", "tuesday", ...]
    var restrictionLevel: RestrictionLevel
    var notes: String?
    var commitmentID: UUID?

    enum BlockType: String, Codable {
        case commitment
        case freeTime
        case sleep
        case morning
        case windDown
        case existing
    }

    enum RestrictionLevel: String, Codable {
        case locked   // apps fully blocked
        case limited  // hourly limits active, browser filters on
        case free     // no restrictions
    }

    var startHour: Int {
        let parts = startTime.split(separator: ":")
        return Int(parts.first ?? "0") ?? 0
    }

    var startMinute: Int {
        let parts = startTime.split(separator: ":")
        return Int(parts.last ?? "0") ?? 0
    }

    /// Color representation for UI
    var displayColor: String {
        switch type {
        case .commitment: "destructive"  // red — locked
        case .freeTime: "accent"         // ice blue — limited
        case .sleep: "textSecondary"     // grey — offline
        case .morning: "windowClosed"    // orange — morning routine
        case .windDown: "windowClosed"   // orange — wind down
        case .existing: "textPrimary"    // white — normal
        }
    }
}

// MARK: - Calendar Service

final class CalendarService {
    static let shared = CalendarService()

    private let eventStore = EKEventStore()
    private let calendarName = "RawDog"
    private static let scheduleKey = "weeklyCalendarBlocks"

    // MARK: - Permissions

    func requestAccess() async -> Bool {
        do {
            return try await eventStore.requestFullAccessToEvents()
        } catch {
            print("CalendarService: Access error: \(error)")
            return false
        }
    }

    // MARK: - RawDog Calendar

    func getOrCreateRawDogCalendar() -> EKCalendar? {
        if let existing = eventStore.calendars(for: .event).first(where: { $0.title == calendarName }) {
            return existing
        }

        let calendar = EKCalendar(for: .event, eventStore: eventStore)
        calendar.title = calendarName
        calendar.cgColor = CGColor(red: 0.91, green: 0.96, blue: 1.0, alpha: 1.0)

        if let iCloud = eventStore.sources.first(where: { $0.sourceType == .calDAV }) {
            calendar.source = iCloud
        } else if let local = eventStore.sources.first(where: { $0.sourceType == .local }) {
            calendar.source = local
        } else {
            calendar.source = eventStore.defaultCalendarForNewEvents?.source
        }

        do {
            try eventStore.saveCalendar(calendar, commit: true)
            return calendar
        } catch {
            print("CalendarService: Failed to create calendar: \(error)")
            return nil
        }
    }

    // MARK: - Fetch Events

    func fetchEvents(from start: Date, to end: Date) -> [EKEvent] {
        let predicate = eventStore.predicateForEvents(withStart: start, end: end, calendars: nil)
        return eventStore.events(matching: predicate)
    }

    func fetchTodaySchedule() -> [CalendarBlock] {
        // Return saved weekly blocks filtered to today's day name
        let blocks: [CalendarBlock] = AppState.shared.load(forKey: Self.scheduleKey) ?? []
        let today = dayName(for: Date())
        return blocks.filter { $0.days.contains(today) }
            .sorted { $0.startTime < $1.startTime }
    }

    // MARK: - Write Schedule to EventKit

    func writeScheduleToCalendar(blocks: [CalendarBlock]) {
        guard let calendar = getOrCreateRawDogCalendar() else { return }

        // Clear existing RawDog events for the next week
        let now = Date()
        let weekOut = Calendar.current.date(byAdding: .day, value: 7, to: now) ?? now
        let predicate = eventStore.predicateForEvents(
            withStart: now,
            end: weekOut,
            calendars: [calendar]
        )
        for event in eventStore.events(matching: predicate) {
            try? eventStore.remove(event, span: .thisEvent)
        }

        // Write new events
        let cal = Calendar.current
        for block in blocks {
            for dayStr in block.days {
                guard let targetDate = nextDate(for: dayStr, from: now) else { continue }

                var startComponents = cal.dateComponents([.year, .month, .day], from: targetDate)
                startComponents.hour = block.startHour
                startComponents.minute = block.startMinute

                guard let startDate = cal.date(from: startComponents) else { continue }

                let event = EKEvent(eventStore: eventStore)
                event.title = block.title
                event.calendar = calendar
                event.startDate = startDate
                event.endDate = startDate.addingTimeInterval(3600) // 1 hour default
                event.notes = "Type: \(block.type.rawValue) | Restriction: \(block.restrictionLevel.rawValue)"

                // Recurring weekly
                let rule = EKRecurrenceRule(
                    recurrenceWith: .weekly,
                    interval: 1,
                    end: nil
                )
                event.addRecurrenceRule(rule)

                do {
                    try eventStore.save(event, span: .futureEvents)
                } catch {
                    print("CalendarService: Failed to save event '\(block.title)': \(error)")
                }
            }
        }
    }

    // MARK: - Save/Load Schedule

    func saveSchedule(_ blocks: [CalendarBlock]) {
        AppState.shared.save(blocks, forKey: Self.scheduleKey)
    }

    func loadSchedule() -> [CalendarBlock] {
        AppState.shared.load(forKey: Self.scheduleKey) ?? []
    }

    // MARK: - Query Helpers

    func currentBlock() -> CalendarBlock? {
        let now = Calendar.current.dateComponents([.hour, .minute], from: Date())
        let currentMinutes = (now.hour ?? 0) * 60 + (now.minute ?? 0)
        let today = dayName(for: Date())

        return fetchTodaySchedule().first { block in
            block.days.contains(today) && block.startHour * 60 + block.startMinute <= currentMinutes
        }
    }

    func isInFreeTime() -> Bool {
        currentBlock()?.type == .freeTime
    }

    func isInCommitmentBlock() -> Bool {
        currentBlock()?.type == .commitment
    }

    // MARK: - Helpers

    private func dayName(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date).lowercased()
    }

    private func nextDate(for dayName: String, from date: Date) -> Date? {
        let cal = Calendar.current
        let dayMap = [
            "sunday": 1, "monday": 2, "tuesday": 3, "wednesday": 4,
            "thursday": 5, "friday": 6, "saturday": 7,
        ]
        guard let targetWeekday = dayMap[dayName.lowercased()] else { return nil }

        let currentWeekday = cal.component(.weekday, from: date)
        var daysToAdd = targetWeekday - currentWeekday
        if daysToAdd < 0 { daysToAdd += 7 }

        return cal.date(byAdding: .day, value: daysToAdd, to: date)
    }
}
