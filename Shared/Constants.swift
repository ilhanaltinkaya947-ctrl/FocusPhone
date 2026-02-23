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

    // AI Backend (Cloudflare Worker proxy)
    static let aiServiceBaseURL = "https://focusphone-api.ilhanaltinkaya947.workers.dev/v1/chat"
    static let groqServiceBaseURL = "https://focusphone-api.ilhanaltinkaya947.workers.dev/v1/groq"
static let aiServiceToken = "fp_XXXXXXXX"

    static var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }
}
