import SwiftUI
import SafariServices

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var contentBlockerEnabled = false
    @Published var totalModes = 0
    @Published var totalTimeBlocks = 0

    func loadData() {
        totalModes = AppState.shared.modes.count
        totalTimeBlocks = AppState.shared.timeBlocks.count
        checkContentBlockerState()
    }

    func checkContentBlockerState() {
        SFContentBlockerManager.getStateOfContentBlocker(
            withIdentifier: Constants.contentBlockerBundleID
        ) { state, error in
            DispatchQueue.main.async {
                self.contentBlockerEnabled = state?.isEnabled ?? false
            }
        }
    }

    func resetAllData() {
        let defaults = Constants.sharedDefaults
        defaults.removeObject(forKey: Constants.modesKey)
        defaults.removeObject(forKey: Constants.timeBlocksKey)
        defaults.removeObject(forKey: Constants.weeklySchedulesKey)
        defaults.removeObject(forKey: Constants.activeModeIDKey)
        defaults.removeObject(forKey: Constants.hasSeededDefaultsKey)
        defaults.removeObject(forKey: Constants.modeSessionsKey)
        ScheduleService.stopAllSchedules()
        BlockingService.clearAllBlocks()
        AppState.shared.seedDefaultsIfNeeded()
        loadData()
    }

    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
}
