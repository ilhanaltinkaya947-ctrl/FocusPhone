import Foundation
import DeviceActivity

final class ScheduleService {
    static let center = DeviceActivityCenter()

    static func registerAllTimeBlocks() {
        center.stopMonitoring()

        let blocks = AppState.shared.timeBlocks

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
            } catch {
                print("Failed to monitor \(activityName.rawValue): \(error)")
            }
        }
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
