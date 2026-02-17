import Foundation

enum Constants {
    static let appGroupID = "group.com.axon.focusphone"
    static let mainAppBundleID = "com.axon.focus-phone"
    static let deviceActivityMonitorBundleID = "com.axon.focus-phone.dam"
    static let shieldConfigurationBundleID = "com.axon.focus-phone.shield"
    static let contentBlockerBundleID = "com.axon.focus-phone.contentblocker"
    static let widgetBundleID = "com.axon.focus-phone.wgt"

    // UserDefaults keys (stored in App Group)
    static let selectedProfileKey = "selectedProfile"
    static let freedomWindowsKey = "freedomWindows"
    static let currentModeKey = "currentMode"
    static let onboardingCompletedKey = "onboardingCompleted"
    static let selectedCategoriesKey = "selectedCategories"

    static var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }
}
