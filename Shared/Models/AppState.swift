import Foundation

final class AppState {
    static let shared = AppState()

    private let defaults = Constants.sharedDefaults

    // MARK: - Onboarding

    var isOnboardingCompleted: Bool {
        get { defaults.bool(forKey: Constants.onboardingCompletedKey) }
        set { defaults.set(newValue, forKey: Constants.onboardingCompletedKey) }
    }

    // MARK: - Restriction Profile

    var restrictionProfile: PersonalRestrictionProfile? {
        get { load(forKey: Constants.restrictionProfileKey) }
        set { save(newValue, forKey: Constants.restrictionProfileKey) }
    }

    var isRestrictionActive: Bool {
        get { defaults.bool(forKey: Constants.isRestrictionActiveKey) }
        set { defaults.set(newValue, forKey: Constants.isRestrictionActiveKey) }
    }

    // MARK: - Timed Window States

    var timedWindowStates: [TimedWindowApp] {
        get { load(forKey: Constants.timedWindowStatesKey) ?? [] }
        set { save(newValue, forKey: Constants.timedWindowStatesKey) }
    }

    func updateTimedWindowState(appID: UUID, isInWindow: Bool, windowStart: Date? = nil, windowEnd: Date? = nil) {
        var states = timedWindowStates
        if let index = states.firstIndex(where: { $0.id == appID }) {
            states[index].isCurrentlyInWindow = isInWindow
            if let start = windowStart {
                states[index].windowStartTime = start
            }
            if let end = windowEnd {
                states[index].lastWindowEndTime = end
            }
            timedWindowStates = states
        }
    }

    // MARK: - Extension Requests

    var extensionRequests: [ExtensionRequest] {
        get { load(forKey: Constants.extensionRequestsKey) ?? [] }
        set { save(newValue, forKey: Constants.extensionRequestsKey) }
    }

    func logExtensionRequest(_ request: ExtensionRequest) {
        var requests = extensionRequests
        requests.append(request)
        extensionRequests = requests
        updateDailyUsage { usage in
            usage.extensionRequestsMade += 1
            if request.wasApproved {
                usage.extensionRequestsApproved += 1
                usage.extensionMinutesUsed += request.grantedMinutes ?? request.requestedMinutes
            }
        }
    }

    // MARK: - Daily Usage

    var dailyUsage: [DailyUsage] {
        get { load(forKey: Constants.dailyUsageKey) ?? [] }
        set { save(newValue, forKey: Constants.dailyUsageKey) }
    }

    var todayUsage: DailyUsage {
        let calendar = Calendar.current
        return dailyUsage.first { calendar.isDateInToday($0.date) }
            ?? DailyUsage(date: calendar.startOfDay(for: Date()))
    }

    var dailyExtensionMinutesUsed: Int {
        todayUsage.extensionMinutesUsed
    }

    func updateDailyUsage(_ mutate: (inout DailyUsage) -> Void) {
        let calendar = Calendar.current
        var allUsage = dailyUsage
        if let index = allUsage.firstIndex(where: { calendar.isDateInToday($0.date) }) {
            mutate(&allUsage[index])
        } else {
            var newUsage = DailyUsage(date: calendar.startOfDay(for: Date()))
            mutate(&newUsage)
            allUsage.append(newUsage)
        }
        // Keep only last 30 days
        let cutoff = calendar.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        allUsage.removeAll { $0.date < cutoff }
        dailyUsage = allUsage
    }

    func incrementTimedWindowsOpened() {
        updateDailyUsage { usage in
            usage.timedWindowsOpened += 1
        }
    }

    // MARK: - Sleep Schedule

    var sleepSchedule: SleepSchedule? {
        get { load(forKey: Constants.sleepScheduleKey) }
        set { save(newValue, forKey: Constants.sleepScheduleKey) }
    }

    // MARK: - Active Enhanced Profiles

    var activeEnhancedProfileIDs: [String] {
        get { load(forKey: Constants.activeEnhancedProfilesKey) ?? [] }
        set { save(newValue, forKey: Constants.activeEnhancedProfilesKey) }
    }

    // MARK: - Content Filter Presets

    var enabledContentFilterPresets: Set<String> {
        get {
            guard let array: [String] = load(forKey: Constants.contentFilterPresetsKey) else { return [] }
            return Set(array)
        }
        set {
            save(Array(newValue), forKey: Constants.contentFilterPresetsKey)
        }
    }

    // MARK: - Migration from old data model

    func migrateIfNeeded() {
        let migrationKey = "hasMigratedToRestrictionProfile"
        guard !defaults.bool(forKey: migrationKey) else { return }

        // Clear old keys if they exist
        let oldKeys = [
            "modes", "timeBlocks", "weeklySchedules", "activeModeID",
            "hasSeededDefaults", "modeSessions", "activeBlockEndTime",
            "dailyIntentions", "dailyStats", "hasUpdatedColorsV2",
            "userProfile", "aiResponseCache", "weeklyReviewDay",
            "lastWeeklyReview", "aiEnabled", "commitmentLevel",
        ]
        for key in oldKeys {
            defaults.removeObject(forKey: key)
        }

        // Force re-onboarding for existing users
        isOnboardingCompleted = false
        defaults.set(true, forKey: migrationKey)
    }

    // MARK: - JSON Helpers

    func save<T: Encodable>(_ value: T, forKey key: String) {
        if let data = try? JSONEncoder().encode(value) {
            defaults.set(data, forKey: key)
        }
    }

    func load<T: Decodable>(forKey key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
}
