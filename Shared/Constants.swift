import Foundation

enum Constants {
    static let appGroupID = "group.com.axon.focusphone"
    static let mainAppBundleID = "com.axon.focus-phone"
    static let deviceActivityMonitorBundleID = "com.axon.focus-phone.dam"
    static let shieldConfigurationBundleID = "com.axon.focus-phone.shield"
    static let contentBlockerBundleID = "com.axon.focus-phone.contentblocker"
    static let widgetBundleID = "com.axon.focus-phone.wgt"

    // UserDefaults keys
    static let onboardingCompletedKey = "onboardingCompleted"
    static let modesKey = "modes"
    static let timeBlocksKey = "timeBlocks"
    static let weeklySchedulesKey = "weeklySchedules"
    static let activeModeIDKey = "activeModeID"
    static let hasSeededDefaultsKey = "hasSeededDefaults"
    static let modeSessionsKey = "modeSessions"
    static let activeBlockEndTimeKey = "activeBlockEndTime"
    static let contentBlockerRulesFileName = "contentBlockerRules.json"

    static var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }
}
