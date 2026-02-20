import Foundation

final class AppState {
    static let shared = AppState()

    private let defaults = Constants.sharedDefaults

    // MARK: - Onboarding

    var isOnboardingCompleted: Bool {
        get { defaults.bool(forKey: Constants.onboardingCompletedKey) }
        set { defaults.set(newValue, forKey: Constants.onboardingCompletedKey) }
    }

    // MARK: - Active Mode

    var activeModeID: UUID? {
        get {
            guard let str = defaults.string(forKey: Constants.activeModeIDKey) else { return nil }
            return UUID(uuidString: str)
        }
        set {
            defaults.set(newValue?.uuidString, forKey: Constants.activeModeIDKey)
        }
    }

    var activeMode: Mode? {
        guard let id = activeModeID else { return nil }
        return mode(for: id)
    }

    var activeBlockEndTime: Date? {
        get { defaults.object(forKey: Constants.activeBlockEndTimeKey) as? Date }
        set { defaults.set(newValue, forKey: Constants.activeBlockEndTimeKey) }
    }

    // MARK: - Modes

    var modes: [Mode] {
        get { load(forKey: Constants.modesKey) ?? [] }
        set { save(newValue, forKey: Constants.modesKey) }
    }

    func mode(for id: UUID) -> Mode? {
        modes.first { $0.id == id }
    }

    // MARK: - TimeBlocks

    var timeBlocks: [TimeBlock] {
        get { load(forKey: Constants.timeBlocksKey) ?? [] }
        set { save(newValue, forKey: Constants.timeBlocksKey) }
    }

    func timeBlocks(for modeID: UUID) -> [TimeBlock] {
        timeBlocks.filter { $0.modeID == modeID }
    }

    func timeBlocks(forDay dayOfWeek: Int) -> [TimeBlock] {
        timeBlocks.filter { $0.dayOfWeek == dayOfWeek }
    }

    // MARK: - WeeklySchedules

    var weeklySchedules: [WeeklySchedule] {
        get { load(forKey: Constants.weeklySchedulesKey) ?? [] }
        set { save(newValue, forKey: Constants.weeklySchedulesKey) }
    }

    var activeSchedule: WeeklySchedule? {
        weeklySchedules.first { $0.isActive }
    }

    // MARK: - Mode Sessions

    var modeSessions: [ModeSession] {
        get { load(forKey: Constants.modeSessionsKey) ?? [] }
        set { save(newValue, forKey: Constants.modeSessionsKey) }
    }

    func startSession(for mode: Mode) {
        endCurrentSession()
        let session = ModeSession(
            modeID: mode.id,
            modeName: mode.name,
            modeColorHex: mode.colorHex
        )
        var sessions = modeSessions
        sessions.append(session)
        modeSessions = sessions
    }

    func endCurrentSession() {
        var sessions = modeSessions
        if let lastIndex = sessions.indices.last, sessions[lastIndex].endDate == nil {
            sessions[lastIndex].endDate = Date()
            modeSessions = sessions
        }
    }

    func sessionsToday() -> [ModeSession] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        return modeSessions.filter { $0.startDate >= startOfDay }
    }

    func sessionsForWeek() -> [ModeSession] {
        let calendar = Calendar.current
        guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) else { return [] }
        return modeSessions.filter { $0.startDate >= weekAgo }
    }

    // MARK: - Daily Intentions

    var dailyIntentions: [DailyIntention] {
        get { load(forKey: Constants.dailyIntentionsKey) ?? [] }
        set { save(newValue, forKey: Constants.dailyIntentionsKey) }
    }

    func intention(for date: Date) -> DailyIntention? {
        let calendar = Calendar.current
        return dailyIntentions.first { calendar.isDate($0.date, inSameDayAs: date) }
    }

    func setIntention(_ text: String, for date: Date) {
        let startOfDay = Calendar.current.startOfDay(for: date)
        var intentions = dailyIntentions
        if let index = intentions.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: startOfDay) }) {
            intentions[index].text = text
        } else {
            intentions.append(DailyIntention(date: startOfDay, text: text))
        }
        dailyIntentions = intentions
    }

    // MARK: - Daily Stats

    var dailyStats: [DailyStats] {
        get { load(forKey: Constants.dailyStatsKey) ?? [] }
        set { save(newValue, forKey: Constants.dailyStatsKey) }
    }

    func stats(for date: Date) -> DailyStats? {
        dailyStats.first { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }

    // MARK: - AI Settings

    var userProfile: UserProfile? {
        get { load(forKey: Constants.userProfileKey) }
        set { save(newValue, forKey: Constants.userProfileKey) }
    }

    var aiEnabled: Bool {
        get { defaults.bool(forKey: Constants.aiEnabledKey) }
        set { defaults.set(newValue, forKey: Constants.aiEnabledKey) }
    }

    var weeklyReviewDay: Int {
        get {
            let val = defaults.integer(forKey: Constants.weeklyReviewDayKey)
            return val == 0 ? 1 : val // Default Sunday=1
        }
        set { defaults.set(newValue, forKey: Constants.weeklyReviewDayKey) }
    }

    var lastWeeklyReview: Date? {
        get { defaults.object(forKey: Constants.lastWeeklyReviewKey) as? Date }
        set { defaults.set(newValue, forKey: Constants.lastWeeklyReviewKey) }
    }

    var commitmentLevel: String {
        get { defaults.string(forKey: Constants.commitmentLevelKey) ?? "flexible" }
        set { defaults.set(newValue, forKey: Constants.commitmentLevelKey) }
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

    // MARK: - Seeding & Migration

    var hasSeededDefaults: Bool {
        get { defaults.bool(forKey: Constants.hasSeededDefaultsKey) }
        set { defaults.set(newValue, forKey: Constants.hasSeededDefaultsKey) }
    }

    func seedDefaultsIfNeeded() {
        if !hasSeededDefaults {
            modes = DefaultModes.allDefaults()
            weeklySchedules = [WeeklySchedule(name: "My Schedule", blockIDs: [], isActive: true)]
            timeBlocks = []
            aiEnabled = true
            hasSeededDefaults = true
        }
        migrateColorsIfNeeded()
        migrateAIEnabledIfNeeded()
    }

    /// Existing users who upgrade get AI enabled automatically
    private func migrateAIEnabledIfNeeded() {
        let migrationKey = "hasEnabledAIByDefault"
        guard !defaults.bool(forKey: migrationKey) else { return }
        aiEnabled = true
        defaults.set(true, forKey: migrationKey)
    }

    private func migrateColorsIfNeeded() {
        guard !defaults.bool(forKey: Constants.hasUpdatedColorsV2Key) else { return }
        let oldToNew: [String: String] = [
            "#F5A623": "#E8DCC8",
            "#4A90D9": "#A8C5A0",
            "#7ED321": "#F0C9A6",
            "#E74C3C": "#A0B8D0",
            "#9B59B6": "#8EBAB8",
            "#8E8E93": "#C4B5D4",
            "#34C759": "#E8B8B8",
            "#1C1C1E": "#3A3A4A",
        ]
        var updatedModes = modes
        for i in updatedModes.indices where updatedModes[i].isSystem {
            if let newHex = oldToNew[updatedModes[i].colorHex] {
                updatedModes[i].colorHex = newHex
            }
        }
        modes = updatedModes
        defaults.set(true, forKey: Constants.hasUpdatedColorsV2Key)
    }

    // MARK: - JSON Helpers

    private func save<T: Encodable>(_ value: T, forKey key: String) {
        if let data = try? JSONEncoder().encode(value) {
            defaults.set(data, forKey: key)
        }
    }

    private func load<T: Decodable>(forKey key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
}
