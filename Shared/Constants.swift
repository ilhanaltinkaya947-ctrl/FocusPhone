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
    static let restrictionProfileKey = "restrictionProfile"
    static let extensionRequestsKey = "extensionRequests"
    static let dailyUsageKey = "dailyUsage"
    static let isRestrictionActiveKey = "isRestrictionActive"
    static let timedWindowStatesKey = "timedWindowStates"
    static let contentFilterPresetsKey = "contentFilterPresets"
    static let contentBlockerRulesFileName = "contentBlockerRules.json"
    static let sleepScheduleKey = "sleepSchedule"
    static let hourlyUsageKey = "hourlyUsageData"
    static let weeklyCalendarBlocksKey = "weeklyCalendarBlocks"
    static let activeEnhancedProfilesKey = "activeEnhancedProfiles"
    static let retentionConfigKey = "retentionConfig"
    static let retentionCachedMessagesKey = "retentionCachedMessages"
    static let retentionWeeklyStatsKey = "retentionWeeklyStats"
    static let retentionMonthlyStatsKey = "retentionMonthlyStats"

    // AI Backend (Cloudflare Worker proxy → Groq)
    static let aiServiceBaseURL = "https://rawdog-api.ilhanaltinkaya947.workers.dev"
    static let groqServiceBaseURL = "https://rawdog-api.ilhanaltinkaya947.workers.dev"
    static let aiServiceToken = "fp_97e6c19ad4e5aab3bc821074f82c213836121b5d"

    static var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }
}
