import Foundation
import DeviceActivity

final class ScheduleService {
    static let center = DeviceActivityCenter()

    struct RegistrationResult {
        let registered: Int
        let failed: [(TimeBlock, Error)]
    }

    /// Registers all timed window slots as DeviceActivity monitors.
    @discardableResult
    static func registerTimedWindows(slots: [TimeBlock]) -> RegistrationResult {
        center.stopMonitoring()

        var registeredCount = 0
        var failures: [(TimeBlock, Error)] = []

        for (index, slot) in slots.enumerated() {
            let activityName = DeviceActivityName(
                rawValue: "window_\(slot.appID.uuidString)_\(index)"
            )

            let start = DateComponents(
                hour: slot.startHour,
                minute: slot.startMinute,
                weekday: slot.dayOfWeek
            )
            let end = DateComponents(
                hour: slot.endHour,
                minute: slot.endMinute,
                weekday: slot.dayOfWeek
            )

            let schedule = DeviceActivitySchedule(
                intervalStart: start,
                intervalEnd: end,
                repeats: slot.isRecurring
            )

            do {
                try center.startMonitoring(activityName, during: schedule)
                registeredCount += 1
            } catch {
                print("Failed to monitor \(activityName.rawValue): \(error)")
                failures.append((slot, error))
            }
        }

        return RegistrationResult(registered: registeredCount, failed: failures)
    }

    /// Registers timed windows from the active restriction profile.
    @discardableResult
    static func registerFromActiveProfile() -> RegistrationResult {
        guard let profile = AppState.shared.restrictionProfile else {
            return RegistrationResult(registered: 0, failed: [])
        }
        let slots = TimedWindowService.generateAllSlots(for: profile)
        return registerTimedWindows(slots: slots)
    }

    static func stopAllSchedules() {
        center.stopMonitoring()
    }

    /// Extracts the app UUID from a DeviceActivity name like "window_UUID_slotIndex".
    static func appID(from activityName: DeviceActivityName) -> UUID? {
        let raw = activityName.rawValue
        guard raw.hasPrefix("window_"), raw.count > 43 else { return nil }
        let startIndex = raw.index(raw.startIndex, offsetBy: 7) // "window_".count
        let endIndex = raw.index(startIndex, offsetBy: 36)
        return UUID(uuidString: String(raw[startIndex..<endIndex]))
    }

    /// Extracts the slot index from a DeviceActivity name.
    static func slotIndex(from activityName: DeviceActivityName) -> Int? {
        let raw = activityName.rawValue
        guard let lastUnderscore = raw.lastIndex(of: "_") else { return nil }
        let indexStr = raw[raw.index(after: lastUnderscore)...]
        return Int(indexStr)
    }
}
