import SwiftUI
import SafariServices

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var contentBlockerEnabled = false

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
        defaults.removeObject(forKey: Constants.restrictionProfileKey)
        defaults.removeObject(forKey: Constants.extensionRequestsKey)
        defaults.removeObject(forKey: Constants.dailyUsageKey)
        defaults.removeObject(forKey: Constants.isRestrictionActiveKey)
        defaults.removeObject(forKey: Constants.timedWindowStatesKey)
        defaults.removeObject(forKey: Constants.contentFilterPresetsKey)
        defaults.removeObject(forKey: Constants.onboardingCompletedKey)
        ScheduleService.stopAllSchedules()
        BlockingService.clearAllBlocks()
        NotificationService.cancelAll()
    }

    func emergencyDisable() {
        RestrictionEngine.deactivateAll()
    }

    func rerunOnboarding() {
        RestrictionEngine.deactivateAll()
        AppState.shared.restrictionProfile = nil
        AppState.shared.isOnboardingCompleted = false
    }

    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
}
