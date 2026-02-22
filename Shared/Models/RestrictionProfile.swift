import Foundation

struct PersonalRestrictionProfile: Codable, Equatable {
    var activePresetIDs: [String]
    var timedWindowApps: [TimedWindowApp]
    var permanentBlockCategories: Data?  // Encoded FamilyActivitySelection
    var permanentBlockApps: Data?        // Encoded FamilyActivitySelection
    var blockYouTubeNativeApp: Bool
    var blockedWebsites: [String]
    var browserContentFilters: [String]
    var blockAppStore: Bool
    var blockAppDeletion: Bool
    var dailyExtensionCapMinutes: Int
    var onboardingSummary: String?

    init(
        activePresetIDs: [String] = [],
        timedWindowApps: [TimedWindowApp] = [],
        permanentBlockCategories: Data? = nil,
        permanentBlockApps: Data? = nil,
        blockYouTubeNativeApp: Bool = false,
        blockedWebsites: [String] = [],
        browserContentFilters: [String] = [],
        blockAppStore: Bool = true,
        blockAppDeletion: Bool = true,
        dailyExtensionCapMinutes: Int = 30,
        onboardingSummary: String? = nil
    ) {
        self.activePresetIDs = activePresetIDs
        self.timedWindowApps = timedWindowApps
        self.permanentBlockCategories = permanentBlockCategories
        self.permanentBlockApps = permanentBlockApps
        self.blockYouTubeNativeApp = blockYouTubeNativeApp
        self.blockedWebsites = blockedWebsites
        self.browserContentFilters = browserContentFilters
        self.blockAppStore = blockAppStore
        self.blockAppDeletion = blockAppDeletion
        self.dailyExtensionCapMinutes = dailyExtensionCapMinutes
        self.onboardingSummary = onboardingSummary
    }
}

struct TimedWindowApp: Codable, Identifiable, Equatable {
    var id: UUID
    var appName: String
    var appToken: Data?               // Encoded ApplicationToken
    var windowDurationMinutes: Int    // e.g. 5
    var cooldownMinutes: Int          // e.g. 120
    var isCurrentlyInWindow: Bool
    var windowStartTime: Date?
    var lastWindowEndTime: Date?

    init(
        id: UUID = UUID(),
        appName: String,
        appToken: Data? = nil,
        windowDurationMinutes: Int = 5,
        cooldownMinutes: Int = 120,
        isCurrentlyInWindow: Bool = false,
        windowStartTime: Date? = nil,
        lastWindowEndTime: Date? = nil
    ) {
        self.id = id
        self.appName = appName
        self.appToken = appToken
        self.windowDurationMinutes = windowDurationMinutes
        self.cooldownMinutes = cooldownMinutes
        self.isCurrentlyInWindow = isCurrentlyInWindow
        self.windowStartTime = windowStartTime
        self.lastWindowEndTime = lastWindowEndTime
    }
}
