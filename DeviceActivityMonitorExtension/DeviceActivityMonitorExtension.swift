import DeviceActivity
import ManagedSettings

class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)

        // Freedom window started — clear all blocks
        BlockingService.clearAllBlocks()
        AppState.shared.currentMode = .freedom
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)

        // Freedom window ended — re-apply blocks
        BlockingService.applyBlocksFromStorage()
        AppState.shared.currentMode = .detox
    }
}
