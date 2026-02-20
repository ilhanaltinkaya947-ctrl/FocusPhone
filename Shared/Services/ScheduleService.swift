import Foundation
import DeviceActivity

final class ScheduleService {
    static let center = DeviceActivityCenter()

    struct RegistrationResult {
        let registered: Int
        let failed: [(TimeBlock, Error)]
    }

    @discardableResult
    static func registerAllTimeBlocks() -> RegistrationResult {
        center.stopMonitoring()

        let blocks = AppState.shared.timeBlocks
        var registeredCount = 0
        var failures: [(TimeBlock, Error)] = []

        for block in blocks {
            let activityName = DeviceActivityName(
                rawValue: "mode_\(block.modeID.uuidString)_\(block.id.uuidString)"
            )

            let start = DateComponents(
                hour: block.startHour,
                minute: block.startMinute,
                weekday: block.dayOfWeek
            )
            let end = DateComponents(
                hour: block.endHour,
                minute: block.endMinute,
                weekday: block.dayOfWeek
            )

            let schedule = DeviceActivitySchedule(
                intervalStart: start,
                intervalEnd: end,
                repeats: block.isRecurring
            )

            do {
                try center.startMonitoring(activityName, during: schedule)
                registeredCount += 1
            } catch {
                print("Failed to monitor \(activityName.rawValue): \(error)")
                failures.append((block, error))
            }
        }

        return RegistrationResult(registered: registeredCount, failed: failures)
    }

    /// Cross-references registered DeviceActivity activities with stored TimeBlocks
    static func verifyRegistrations() -> (matched: Int, unmatched: Int) {
        let registeredActivities = center.activities
        let blocks = AppState.shared.timeBlocks

        var matched = 0
        var unmatched = 0

        for block in blocks {
            let expectedName = DeviceActivityName(
                rawValue: "mode_\(block.modeID.uuidString)_\(block.id.uuidString)"
            )
            if registeredActivities.contains(expectedName) {
                matched += 1
            } else {
                unmatched += 1
            }
        }

        return (matched: matched, unmatched: unmatched)
    }

    static func stopAllSchedules() {
        center.stopMonitoring()
    }

    static func modeID(from activityName: DeviceActivityName) -> UUID? {
        let raw = activityName.rawValue
        guard raw.hasPrefix("mode_"), raw.count > 41 else { return nil }
        let startIndex = raw.index(raw.startIndex, offsetBy: 5)
        let endIndex = raw.index(startIndex, offsetBy: 36)
        return UUID(uuidString: String(raw[startIndex..<endIndex]))
    }
}
