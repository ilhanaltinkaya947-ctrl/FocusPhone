import DeviceActivity
import Foundation
import ManagedSettings

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
            BlockingService.clearAllBlocks()
        }
    }
}
