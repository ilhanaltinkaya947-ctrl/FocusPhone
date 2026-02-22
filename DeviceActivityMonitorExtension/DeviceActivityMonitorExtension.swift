import DeviceActivity
import Foundation
import ManagedSettings
import WidgetKit

class DeviceActivityMonitorExtension: DeviceActivityMonitor {

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)

        guard let appID = ScheduleService.appID(from: activity) else {
            logDiagnostic("intervalDidStart: could not parse appID from \(activity.rawValue)")
            return
        }

        // Timed window opened — unblock the app
        RestrictionEngine.onWindowOpen(appID: appID)
        WidgetCenter.shared.reloadAllTimelines()

        let appName = AppState.shared.timedWindowStates.first(where: { $0.id == appID })?.appName ?? "Unknown"
        logDiagnostic("intervalDidStart: window opened for \(appName), activity=\(activity.rawValue)")
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)

        guard let appID = ScheduleService.appID(from: activity) else {
            logDiagnostic("intervalDidEnd: could not parse appID from \(activity.rawValue)")
            return
        }

        // Timed window closed — re-block the app
        RestrictionEngine.onWindowClose(appID: appID)
        WidgetCenter.shared.reloadAllTimelines()

        let appName = AppState.shared.timedWindowStates.first(where: { $0.id == appID })?.appName ?? "Unknown"
        logDiagnostic("intervalDidEnd: window closed for \(appName), activity=\(activity.rawValue)")
    }

    // MARK: - Diagnostic Logging

    private func logDiagnostic(_ message: String) {
        guard let containerURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: Constants.appGroupID) else { return }

        let logURL = containerURL.appendingPathComponent("device_activity_log.txt")
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let line = "[\(timestamp)] \(message)\n"

        if let handle = try? FileHandle(forWritingTo: logURL) {
            handle.seekToEndOfFile()
            if let data = line.data(using: .utf8) {
                handle.write(data)
            }
            handle.closeFile()
        } else {
            try? line.write(to: logURL, atomically: true, encoding: .utf8)
        }
    }
}
