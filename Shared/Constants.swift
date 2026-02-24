import Foundation

enum Constants {
    static let appGroupID = "group.com.ilhan.rawdog"
    static let mainAppBundleID = "com.ilhan.rawdog"
    static let deviceActivityMonitorBundleID = "com.ilhan.rawdog.dam"
    static let shieldConfigurationBundleID = "com.ilhan.rawdog.shield"
    static let contentBlockerBundleID = "com.ilhan.rawdog.contentblocker"
    static let widgetBundleID = "com.ilhan.rawdog.wgt"

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
