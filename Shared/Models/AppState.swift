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

    // MARK: - Seeding

    var hasSeededDefaults: Bool {
        get { defaults.bool(forKey: Constants.hasSeededDefaultsKey) }
        set { defaults.set(newValue, forKey: Constants.hasSeededDefaultsKey) }
    }

    func seedDefaultsIfNeeded() {
        guard !hasSeededDefaults else { return }
        modes = DefaultModes.allDefaults()
        weeklySchedules = [WeeklySchedule(name: "My Schedule", blockIDs: [], isActive: true)]
        timeBlocks = []
        hasSeededDefaults = true
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
