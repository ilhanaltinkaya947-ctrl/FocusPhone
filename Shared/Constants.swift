import Foundation

enum Constants {
    static let appGroupID = "group.com.focusphone.shared"
    static let mainAppBundleID = "com.focusphone.app"
    static let deviceActivityMonitorBundleID = "com.focusphone.app.DeviceActivityMonitor"
    static let shieldConfigurationBundleID = "com.focusphone.app.ShieldConfiguration"
    static let contentBlockerBundleID = "com.focusphone.app.ContentBlocker"
    static let widgetBundleID = "com.focusphone.app.Widget"

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
