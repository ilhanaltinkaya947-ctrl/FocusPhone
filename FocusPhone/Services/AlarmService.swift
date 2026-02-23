import Foundation
import EventKit
import UserNotifications

// MARK: - Alarm Types

enum AlarmType: String, Codable {
    case wakeUp = "rawdog_wake_up"
    case sleepReminder = "rawdog_sleep_reminder"
    case sleepTime = "rawdog_sleep_time"

    static func commitment(id: UUID) -> String {
        "rawdog_commitment_\(id.uuidString)"
    }
}

// MARK: - Alarm Service

final class AlarmService {
    static let shared = AlarmService()

    private let eventStore = EKEventStore()
    private let notificationCenter = UNUserNotificationCenter.current()
    private let calendarName = "RawDog"

    // MARK: - Permissions

    func requestCalendarAccess() async -> Bool {
        do {
            return try await eventStore.requestFullAccessToEvents()
        } catch {
            print("AlarmService: Calendar access error: \(error)")
            return false
        }
    }

    func requestNotificationAccess() async -> Bool {
        do {
            return try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            print("AlarmService: Notification access error: \(error)")
            return false
        }
    }

    // MARK: - Wake Up Alarm

    func setWakeUpAlarm(time: DateComponents, label: String = "Wake Up") {
        // 1. Calendar event — repeating daily alarm
        createRepeatingCalendarEvent(
            title: "🌅 \(label)",
            time: time,
            identifier: AlarmType.wakeUp.rawValue
        )

        // 2. Notification at wake time
        scheduleRepeatingNotification(
            identifier: AlarmType.wakeUp.rawValue,
            title: "RawDog",
            body: "rise and grind. no phone for the first 30. 🐕",
            time: time,
            categoryIdentifier: "WAKE_UP"
        )

        // Register the "I'm up" action
        registerWakeUpCategory()
    }

    // MARK: - Sleep Reminders

    func setSleepReminder(time: DateComponents) {
        // 15 min before sleep: wind-down
        var reminderTime = time
        if let hour = time.hour, let minute = time.minute {
            let totalMinutes = hour * 60 + minute - 15
            reminderTime.hour = (totalMinutes / 60 + 24) % 24
            reminderTime.minute = (totalMinutes % 60 + 60) % 60
        }

        scheduleRepeatingNotification(
            identifier: AlarmType.sleepReminder.rawValue,
            title: "RawDog",
            body: "wind down. phone goes down in 15. 🐕",
            time: reminderTime,
            categoryIdentifier: "SLEEP_REMINDER"
        )

        // At sleep time: hard stop
        scheduleRepeatingNotification(
            identifier: AlarmType.sleepTime.rawValue,
            title: "RawDog",
            body: "bed. now. 🐕",
            time: time,
            categoryIdentifier: "SLEEP_TIME"
        )
    }

    // MARK: - Commitment Alarm

    func setCommitmentAlarm(id: UUID, title: String, time: DateComponents) {
        let identifier = AlarmType.commitment(id: id)

        scheduleRepeatingNotification(
            identifier: identifier,
            title: "RawDog",
            body: "\(title) time. no excuses. 🐕",
            time: time,
            categoryIdentifier: "COMMITMENT"
        )
    }

    // MARK: - Cancel

    func cancelAlarm(type: AlarmType) {
        // Remove notification
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [type.rawValue])

        // Remove calendar event
        removeCalendarEvent(identifier: type.rawValue)
    }

    func cancelCommitmentAlarm(id: UUID) {
        let identifier = AlarmType.commitment(id: id)
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    func cancelAll() {
        for type in [AlarmType.wakeUp, .sleepReminder, .sleepTime] {
            cancelAlarm(type: type)
        }
    }

    // MARK: - Calendar Helpers

    private func getRawDogCalendar() -> EKCalendar? {
        // Find existing RawDog calendar
        if let existing = eventStore.calendars(for: .event).first(where: { $0.title == calendarName }) {
            return existing
        }

        // Create new one
        let calendar = EKCalendar(for: .event, eventStore: eventStore)
        calendar.title = calendarName
        calendar.cgColor = CGColor(red: 0.91, green: 0.96, blue: 1.0, alpha: 1.0) // ice blue

        // Use iCloud source if available, fallback to local
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
            print("AlarmService: Failed to create calendar: \(error)")
            return nil
        }
    }

    private func createRepeatingCalendarEvent(title: String, time: DateComponents, identifier: String) {
        guard let calendar = getRawDogCalendar() else { return }

        // Remove existing event with same identifier first
        removeCalendarEvent(identifier: identifier)

        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.calendar = calendar
        event.notes = "RawDog Alarm: \(identifier)"

        // Set start date from time components
        var startComponents = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        startComponents.hour = time.hour
        startComponents.minute = time.minute
        if let date = Calendar.current.date(from: startComponents) {
            event.startDate = date
            event.endDate = date.addingTimeInterval(60) // 1 min duration
        }

        // Add alarm at event time
        event.addAlarm(EKAlarm(relativeOffset: 0))

        // Repeat daily
        let rule = EKRecurrenceRule(
            recurrenceWith: .daily,
            interval: 1,
            end: nil
        )
        event.addRecurrenceRule(rule)

        do {
            try eventStore.save(event, span: .futureEvents)
        } catch {
            print("AlarmService: Failed to save event: \(error)")
        }
    }

    private func removeCalendarEvent(identifier: String) {
        let predicate = eventStore.predicateForEvents(
            withStart: Date().addingTimeInterval(-86400),
            end: Date().addingTimeInterval(86400 * 365),
            calendars: eventStore.calendars(for: .event).filter { $0.title == calendarName }
        )

        for event in eventStore.events(matching: predicate) {
            if event.notes?.contains(identifier) == true {
                do {
                    try eventStore.remove(event, span: .futureEvents)
                } catch {
                    print("AlarmService: Failed to remove event: \(error)")
                }
            }
        }
    }

    // MARK: - Notification Helpers

    private func scheduleRepeatingNotification(
        identifier: String,
        title: String,
        body: String,
        time: DateComponents,
        categoryIdentifier: String
    ) {
        // Remove existing first
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = categoryIdentifier

        var triggerComponents = DateComponents()
        triggerComponents.hour = time.hour
        triggerComponents.minute = time.minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        notificationCenter.add(request) { error in
            if let error {
                print("AlarmService: Failed to schedule notification: \(error)")
            }
        }
    }

    private func registerWakeUpCategory() {
        let imUpAction = UNNotificationAction(
            identifier: "IM_UP",
            title: "I'm up 🐕",
            options: [.foreground]
        )
        let category = UNNotificationCategory(
            identifier: "WAKE_UP",
            actions: [imUpAction],
            intentIdentifiers: [],
            options: []
        )
        notificationCenter.setNotificationCategories([category])
    }
}
