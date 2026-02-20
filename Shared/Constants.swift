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
    static let dailyIntentionsKey = "dailyIntentions"
    static let dailyStatsKey = "dailyStats"
    static let hasUpdatedColorsV2Key = "hasUpdatedColorsV2"
    static let contentBlockerRulesFileName = "contentBlockerRules.json"
    static let userProfileKey = "userProfile"
    static let aiResponseCacheKey = "aiResponseCache"
    static let weeklyReviewDayKey = "weeklyReviewDay"
    static let lastWeeklyReviewKey = "lastWeeklyReview"
    static let aiEnabledKey = "aiEnabled"
    static let commitmentLevelKey = "commitmentLevel"
    static let contentFilterPresetsKey = "contentFilterPresets"

    // AI Backend
    static let aiServiceBaseURL = "https://focusphone-api.workers.dev/v1/chat"
    static let aiServiceToken = "fp_XXXXXXXX"

    static var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }
}
