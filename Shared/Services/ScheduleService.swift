import Foundation
import DeviceActivity

final class ScheduleService {
    static let center = DeviceActivityCenter()

    static func registerSchedules(for windows: [FreedomWindow]) {
        // Stop all existing monitoring first
        center.stopMonitoring()

        for window in windows where window.isEnabled {
            for day in window.days {
                let activityName = DeviceActivityName(
                    rawValue: "freedom_\(window.id.uuidString)_\(day.rawValue)"
                )

                let start = DateComponents(
                    hour: window.startHour,
                    minute: window.startMinute,
                    weekday: day.rawValue
                )
                let end = DateComponents(
                    hour: window.endHour,
                    minute: window.endMinute,
                    weekday: day.rawValue
                )

                let schedule = DeviceActivitySchedule(
                    intervalStart: start,
                    intervalEnd: end,
                    repeats: true
                )

                do {
                    try center.startMonitoring(activityName, during: schedule)
                } catch {
                    print("Failed to start monitoring \(activityName.rawValue): \(error)")
                }
            }
        }
    }

    static func stopAllSchedules() {
        center.stopMonitoring()
    }
}
