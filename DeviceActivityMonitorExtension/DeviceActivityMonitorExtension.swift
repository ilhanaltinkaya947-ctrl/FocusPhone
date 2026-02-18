import DeviceActivity
import Foundation
import ManagedSettings
import WidgetKit

class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)

        guard let modeID = ScheduleService.modeID(from: activity),
              let mode = AppState.shared.mode(for: modeID) else {
            return
        }

        AppState.shared.activeModeID = modeID
        AppState.shared.startSession(for: mode)
        BlockingService.applyBlocks(for: mode)
        WidgetCenter.shared.reloadAllTimelines()

        // Store block end time so the shield can show remaining time
        let now = Date()
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: now)
        let currentMinutes = calendar.component(.hour, from: now) * 60 + calendar.component(.minute, from: now)
        if let block = AppState.shared.timeBlocks(forDay: weekday)
            .first(where: { $0.modeID == modeID && $0.startHour * 60 + $0.startMinute <= currentMinutes && $0.endHour * 60 + $0.endMinute > currentMinutes }),
           let endTime = calendar.date(bySettingHour: block.endHour, minute: block.endMinute, second: 0, of: now) {
            AppState.shared.activeBlockEndTime = endTime
        }
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)

        let now = Date()
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: now)
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        let currentMinutes = hour * 60 + minute

        let activeBlocks = AppState.shared.timeBlocks(forDay: weekday)
        let currentBlock = activeBlocks.first { block in
            let start = block.startHour * 60 + block.startMinute
            let end = block.endHour * 60 + block.endMinute
            return currentMinutes >= start && currentMinutes < end
        }

        if let currentBlock = currentBlock,
           let mode = AppState.shared.mode(for: currentBlock.modeID) {
            AppState.shared.activeModeID = currentBlock.modeID
            AppState.shared.startSession(for: mode)
            BlockingService.applyBlocks(for: mode)
        } else {
            AppState.shared.endCurrentSession()
            AppState.shared.activeModeID = nil
            AppState.shared.activeBlockEndTime = nil
            BlockingService.clearAllBlocks()
        }
        WidgetCenter.shared.reloadAllTimelines()
    }
}
