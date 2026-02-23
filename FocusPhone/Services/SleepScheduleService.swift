import Foundation
import DeviceActivity
import UserNotifications

// SleepSchedule and SimpleTime are defined in Shared/Models/SleepModels.swift

// MARK: - Sleep Schedule Service

final class SleepScheduleService {
    static let shared = SleepScheduleService()

    private static let scheduleKey = "sleepSchedule"
    private static let morningMessageKey = "cachedMorningMessage"

    private let center = DeviceActivityCenter()

    // MARK: - Persistence

    var schedule: SleepSchedule? {
        get { AppState.shared.load(forKey: Self.scheduleKey) }
        set { AppState.shared.save(newValue, forKey: Self.scheduleKey) }
    }

    var cachedMorningMessage: String? {
        get { Constants.sharedDefaults.string(forKey: Self.morningMessageKey) }
        set { Constants.sharedDefaults.set(newValue, forKey: Self.morningMessageKey) }
    }

    // MARK: - Activate Sleep Mode

    func activateSleepMode(schedule: SleepSchedule) {
        self.schedule = schedule

        // Register sleep restriction with DeviceActivity
        registerSleepRestriction(schedule: schedule)

        // Register morning routine restriction
        registerMorningRestriction(schedule: schedule)

        // Set alarms via AlarmService
        AlarmService.shared.setWakeUpAlarm(time: schedule.wakeTime.dateComponents)
        AlarmService.shared.setSleepReminder(time: schedule.bedtime.dateComponents)

        // Schedule wind-down notification
        scheduleWindDownNotification(schedule: schedule)
    }

    func deactivateSleepMode() {
        center.stopMonitoring([DeviceActivityName("SleepRestriction")])
        center.stopMonitoring([DeviceActivityName("MorningRestriction")])
        AlarmService.shared.cancelAlarm(type: .wakeUp)
        AlarmService.shared.cancelAlarm(type: .sleepReminder)
        AlarmService.shared.cancelAlarm(type: .sleepTime)
        schedule = nil
    }

    // MARK: - DeviceActivity Registration

    private func registerSleepRestriction(schedule: SleepSchedule) {
        let sleepStart = schedule.bedtime.dateComponents
        let sleepEnd = schedule.wakeTime.dateComponents

        let activitySchedule = DeviceActivitySchedule(
            intervalStart: sleepStart,
            intervalEnd: sleepEnd,
            repeats: true
        )

        do {
            try center.startMonitoring(
                DeviceActivityName("SleepRestriction"),
                during: activitySchedule
            )
        } catch {
            print("SleepScheduleService: Failed to register sleep restriction: \(error)")
        }
    }

    private func registerMorningRestriction(schedule: SleepSchedule) {
        let morningStart = schedule.wakeTime.dateComponents
        let morningEnd = schedule.morningRoutineEndTime.dateComponents

        let activitySchedule = DeviceActivitySchedule(
            intervalStart: morningStart,
            intervalEnd: morningEnd,
            repeats: true
        )

        do {
            try center.startMonitoring(
                DeviceActivityName("MorningRestriction"),
                during: activitySchedule
            )
        } catch {
            print("SleepScheduleService: Failed to register morning restriction: \(error)")
        }
    }

    // MARK: - Wind-Down Notification

    private func scheduleWindDownNotification(schedule: SleepSchedule) {
        let windDown = schedule.windDownTime

        let content = UNMutableNotificationContent()
        content.title = "RawDog"
        content.body = "wind-down starts now. social apps going dark. 🐕"
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: windDown.dateComponents,
            repeats: true
        )
        let request = UNNotificationRequest(
            identifier: "rawdog_wind_down",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Nightly Groq Pre-generation

    func scheduleNightlyGroqCall() {
        guard let schedule = schedule else { return }

        // 30 min before sleep — generate tomorrow's morning message
        let preGenTime = SimpleTime(totalMinutes: schedule.bedtime.totalMinutes - 30)

        let content = UNMutableNotificationContent()
        content.title = "RawDog"
        content.body = "preparing tomorrow's message..."
        content.sound = nil // Silent — triggers background work
        content.categoryIdentifier = "NIGHTLY_PREGEN"

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: preGenTime.dateComponents,
            repeats: true
        )
        let request = UNNotificationRequest(
            identifier: "rawdog_nightly_pregen",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    /// Call this from notification handler or app foreground near sleep time
    func preGenerateMorningMessage() async {
        do {
            let message = try await GroqService.shared.generateWeeklyMorningMessage()
            cachedMorningMessage = message

            // Schedule as tomorrow morning notification
            if let schedule = schedule {
                let content = UNMutableNotificationContent()
                content.title = "RawDog"
                content.body = message
                content.sound = .default

                let trigger = UNCalendarNotificationTrigger(
                    dateMatching: schedule.wakeTime.dateComponents,
                    repeats: false
                )
                let request = UNNotificationRequest(
                    identifier: "rawdog_morning_message",
                    content: content,
                    trigger: trigger
                )
                try await UNUserNotificationCenter.current().add(request)
            }
        } catch {
            print("SleepScheduleService: Morning message pre-gen failed: \(error)")
        }
    }

    // MARK: - Daily Summary

    func scheduleDailySummary() {
        guard let schedule = schedule else { return }

        // At wind-down time, send daily summary
        let content = UNMutableNotificationContent()
        content.title = "RawDog"
        let usage = AppState.shared.todayUsage
        content.body = NotificationCopy.dailySummary(
            done: usage.timedWindowsOpened,
            total: AppState.shared.timedWindowStates.count,
            streak: 0
        )
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: schedule.windDownTime.dateComponents,
            repeats: true
        )
        let request = UNNotificationRequest(
            identifier: "rawdog_daily_summary",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Query Helpers

    func isInSleepMode() -> Bool {
        guard let schedule = schedule else { return false }
        let now = Calendar.current.dateComponents([.hour, .minute], from: Date())
        let currentMinutes = (now.hour ?? 0) * 60 + (now.minute ?? 0)
        let bedMinutes = schedule.bedtime.totalMinutes
        let wakeMinutes = schedule.wakeTime.totalMinutes

        // Handle overnight wrap (e.g. 22:30 → 06:00)
        if bedMinutes > wakeMinutes {
            return currentMinutes >= bedMinutes || currentMinutes < wakeMinutes
        } else {
            return currentMinutes >= bedMinutes && currentMinutes < wakeMinutes
        }
    }

    func isInMorningRoutine() -> Bool {
        guard let schedule = schedule else { return false }
        let now = Calendar.current.dateComponents([.hour, .minute], from: Date())
        let currentMinutes = (now.hour ?? 0) * 60 + (now.minute ?? 0)
        let wakeMinutes = schedule.wakeTime.totalMinutes
        let endMinutes = schedule.morningRoutineEndTime.totalMinutes

        return currentMinutes >= wakeMinutes && currentMinutes < endMinutes
    }

    func isInWindDown() -> Bool {
        guard let schedule = schedule else { return false }
        let now = Calendar.current.dateComponents([.hour, .minute], from: Date())
        let currentMinutes = (now.hour ?? 0) * 60 + (now.minute ?? 0)
        let windDownMinutes = schedule.windDownTime.totalMinutes
        let bedMinutes = schedule.bedtime.totalMinutes

        return currentMinutes >= windDownMinutes && currentMinutes < bedMinutes
    }
}
