import Foundation
import UserNotifications

// MARK: - Daily Check-In

struct DailyCheckIn: Codable, Identifiable {
    let id: UUID
    let date: Date
    var morningMessageSent: Bool
    var middayCheckInSent: Bool
    var eveningReflectionSent: Bool
    var userResponded: Bool
    var responseNote: String?

    init(date: Date = Date()) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.morningMessageSent = false
        self.middayCheckInSent = false
        self.eveningReflectionSent = false
        self.userResponded = false
        self.responseNote = nil
    }
}

// MARK: - Retention Config

struct RetentionConfig: Codable, Equatable {
    var morningEnabled: Bool = true
    var middayEnabled: Bool = true
    var eveningEnabled: Bool = true
    var weeklyEnabled: Bool = true

    var morningTime: SimpleTime = SimpleTime(hour: 8, minute: 0)
    var middayTime: SimpleTime = SimpleTime(hour: 13, minute: 0)
    var eveningTime: SimpleTime = SimpleTime(hour: 21, minute: 0)
    var weeklyDay: Int = 2 // Monday
    var weeklyTime: SimpleTime = SimpleTime(hour: 10, minute: 0)

    var maxNotificationsPerDay: Int = 4
    var minIntervalMinutes: Int = 60
}

// MARK: - Cached Retention Message

struct CachedRetentionMessage: Codable, Identifiable {
    let id: UUID
    let type: RetentionMessageType
    let body: String
    let generatedAt: Date
    let dayOfWeek: Int // 1-7, so we can batch a week
    var delivered: Bool = false

    init(type: RetentionMessageType, body: String, dayOfWeek: Int = 0) {
        self.id = UUID()
        self.type = type
        self.body = body
        self.generatedAt = Date()
        self.dayOfWeek = dayOfWeek
    }
}

enum RetentionMessageType: String, Codable {
    case morning
    case midday
    case evening
    case weekly
    case habitStack
}

// MARK: - Retention Stats

struct WeeklyRetentionStats: Codable {
    var commitmentsCompleted: Int = 0
    var totalScheduled: Int = 0
    var hoursReclaimed: Double = 0
    var longestStreakThisWeek: Int = 0
    var bestDay: String?
    var weekStartDate: Date = Date()
    var verifiedPhotoCount: Int = 0

    var completionPercentage: Int {
        guard totalScheduled > 0 else { return 0 }
        return Int(Double(commitmentsCompleted) / Double(totalScheduled) * 100)
    }
}

struct MonthlyRetentionStats: Codable {
    var commitmentsCompleted: Int = 0
    var totalScheduled: Int = 0
    var hoursReclaimed: Double = 0
    var bestDay: String?
    var bestWeekCommitments: Int = 0
    var bestWeekStartDate: Date?
    var verifiedPhotoCount: Int = 0
    var longestStreak: Int = 0
    var monthStartDate: Date = Date()

    var completionPercentage: Int {
        guard totalScheduled > 0 else { return 0 }
        return Int(Double(commitmentsCompleted) / Double(totalScheduled) * 100)
    }
}

// MARK: - Retention Service

final class RetentionService {
    static let shared = RetentionService()

    private static let configKey = "retentionConfig"
    private static let cachedMessagesKey = "retentionCachedMessages"
    private static let weeklyStatsKey = "retentionWeeklyStats"
    private static let monthlyStatsKey = "retentionMonthlyStats"
    private static let lastPregenDateKey = "retentionLastPregenDate"
    private static let checkInsKey = "retentionCheckIns"

    // MARK: - Persistence

    var config: RetentionConfig {
        get { AppState.shared.load(forKey: Self.configKey) ?? RetentionConfig() }
        set { AppState.shared.save(newValue, forKey: Self.configKey) }
    }

    var cachedMessages: [CachedRetentionMessage] {
        get { AppState.shared.load(forKey: Self.cachedMessagesKey) ?? [] }
        set { AppState.shared.save(newValue, forKey: Self.cachedMessagesKey) }
    }

    var weeklyStats: WeeklyRetentionStats {
        get { AppState.shared.load(forKey: Self.weeklyStatsKey) ?? WeeklyRetentionStats() }
        set { AppState.shared.save(newValue, forKey: Self.weeklyStatsKey) }
    }

    var monthlyStats: MonthlyRetentionStats {
        get { AppState.shared.load(forKey: Self.monthlyStatsKey) ?? MonthlyRetentionStats() }
        set { AppState.shared.save(newValue, forKey: Self.monthlyStatsKey) }
    }

    var checkIns: [DailyCheckIn] {
        get { AppState.shared.load(forKey: Self.checkInsKey) ?? [] }
        set { AppState.shared.save(newValue, forKey: Self.checkInsKey) }
    }

    // MARK: - Setup (called on app launch)

    func setup() {
        refreshStatsIfNeeded()
        ensureTodayCheckIn()
        scheduleAllNotifications()

        // Sunday night batch pre-generation for the whole week
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        let lastPregen = Constants.sharedDefaults.object(forKey: Self.lastPregenDateKey) as? Date
        let needsWeeklyPregen = lastPregen == nil || !calendar.isDate(lastPregen!, equalTo: Date(), toGranularity: .weekOfYear)

        // Pre-gen on Sunday evening (weekday 1) or if never done this week
        if weekday == 1 || needsWeeklyPregen {
            Task {
                await preGenerateWeekMessages()
            }
        }

        // Daily fallback: if no cached message for today, generate just today's
        let todayMessages = cachedMessages.filter { calendar.isDateInToday($0.generatedAt) }
        if todayMessages.isEmpty {
            Task {
                await preGenerateTodayMessages()
            }
        }
    }

    // MARK: - Daily Check-In Management

    private func ensureTodayCheckIn() {
        let calendar = Calendar.current
        let hasToday = checkIns.contains { calendar.isDateInToday($0.date) }
        if !hasToday {
            var list = checkIns
            list.append(DailyCheckIn())
            // Keep last 30 days
            let cutoff = calendar.date(byAdding: .day, value: -30, to: Date()) ?? Date()
            list.removeAll { $0.date < cutoff }
            checkIns = list
        }
    }

    func markCheckIn(type: RetentionMessageType, responded: Bool = false, note: String? = nil) {
        let calendar = Calendar.current
        var list = checkIns
        guard let idx = list.firstIndex(where: { calendar.isDateInToday($0.date) }) else { return }

        switch type {
        case .morning: list[idx].morningMessageSent = true
        case .midday: list[idx].middayCheckInSent = true
        case .evening: list[idx].eveningReflectionSent = true
        default: break
        }

        if responded {
            list[idx].userResponded = true
            list[idx].responseNote = note
        }

        checkIns = list
    }

    // MARK: - Notification Scheduling

    func scheduleAllNotifications() {
        let identifiers = [
            "rawdog_retention_morning",
            "rawdog_retention_midday",
            "rawdog_retention_evening",
            "rawdog_retention_weekly",
        ]
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)

        let cfg = config

        if cfg.morningEnabled {
            scheduleMorningNotification(time: effectiveMorningTime())
        }
        if cfg.middayEnabled {
            scheduleMiddayNotification(time: cfg.middayTime)
        }
        if cfg.eveningEnabled {
            scheduleEveningNotification(time: effectiveEveningTime())
        }
        if cfg.weeklyEnabled {
            scheduleWeeklyNotification(day: cfg.weeklyDay, time: cfg.weeklyTime)
        }
    }

    // MARK: - Effective Times (respect sleep schedule)

    private func effectiveMorningTime() -> SimpleTime {
        if let sleep = AppState.shared.sleepSchedule {
            // Wake time + 5 minutes
            return SimpleTime(totalMinutes: sleep.wakeTime.totalMinutes + 5)
        }
        return config.morningTime
    }

    private func effectiveEveningTime() -> SimpleTime {
        if let sleep = AppState.shared.sleepSchedule {
            let windDown = sleep.windDownTime
            if config.eveningTime.totalMinutes > windDown.totalMinutes {
                return SimpleTime(totalMinutes: windDown.totalMinutes - 5)
            }
        }
        return config.eveningTime
    }

    // MARK: - Schedule Individual Notifications

    private func scheduleMorningNotification(time: SimpleTime) {
        let body = morningMessage()

        let content = UNMutableNotificationContent()
        content.title = "RawDog"
        content.body = body
        content.sound = .default
        content.userInfo = ["type": "retention_morning"]

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: time.dateComponents,
            repeats: true
        )
        let request = UNNotificationRequest(
            identifier: "rawdog_retention_morning",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    private func scheduleMiddayNotification(time: SimpleTime) {
        let body = middayMessage()

        let content = UNMutableNotificationContent()
        content.title = "RawDog"
        content.body = body
        content.sound = .default
        content.userInfo = ["type": "retention_midday"]

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: time.dateComponents,
            repeats: true
        )
        let request = UNNotificationRequest(
            identifier: "rawdog_retention_midday",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    private func scheduleEveningNotification(time: SimpleTime) {
        let body = eveningMessage()

        let content = UNMutableNotificationContent()
        content.title = "RawDog"
        content.body = body
        content.sound = .default
        content.userInfo = ["type": "retention_evening"]

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: time.dateComponents,
            repeats: true
        )
        let request = UNNotificationRequest(
            identifier: "rawdog_retention_evening",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    private func scheduleWeeklyNotification(day: Int, time: SimpleTime) {
        let cached = cachedMessage(for: .weekly)
        let body = cached?.body ?? weeklyFallbackMessage()

        let content = UNMutableNotificationContent()
        content.title = "RawDog — Weekly Receipt"
        content.body = body
        content.sound = .default
        content.userInfo = ["type": "retention_weekly"]

        var dateComponents = time.dateComponents
        dateComponents.weekday = day

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )
        let request = UNNotificationRequest(
            identifier: "rawdog_retention_weekly",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Message Builders (cached → fallback)

    /// Morning: "[First commitment] in [X] minutes. You've done this [streak] days straight. Don't be the person who stops here."
    func morningMessage() -> String {
        if let cached = cachedMessage(for: .morning) {
            return cached.body
        }
        return morningFallback()
    }

    /// Midday: "Halfway through. [Commitment] still pending. You've got time."
    func middayMessage() -> String {
        if let cached = cachedMessage(for: .midday) {
            return cached.body
        }
        return middayFallback()
    }

    /// Evening: conditional on completion
    func eveningMessage() -> String {
        if let cached = cachedMessage(for: .evening) {
            return cached.body
        }
        return eveningFallback()
    }

    // MARK: - Fallback Messages (data-driven, no API)

    private func morningFallback() -> String {
        let commitments = CommitmentStore.commitments.filter(\.isActive)
        guard let first = firstUpcomingCommitment(from: commitments) else {
            return "New day. Time to prove something. 🐕"
        }

        let stat = CommitmentStore.stats(for: first.id)
        let minutesUntil = minutesUntilCommitment(first)

        if stat.currentStreak > 0 {
            return "\(first.title) in \(minutesUntil) minutes. You've done this \(stat.currentStreak) days straight. Don't be the person who stops here."
        }
        return "\(first.title) in \(minutesUntil) minutes. Day 1 starts now. 🐕"
    }

    private func middayFallback() -> String {
        let done = todayCompletedCount()
        let total = todayScheduledCount()

        if done == total && total > 0 {
            return "Everything done before noon. RawDog's impressed. Rare."
        }

        let pending = pendingCommitments()
        if let next = pending.first {
            return "Halfway through. \(next.title) still pending. You've got time."
        }

        if total > 0 {
            return "\(done)/\(total) done. Afternoon's not over. 🐕"
        }
        return "No commitments today. Rest day earned or excuse? 🐕"
    }

    private func eveningFallback() -> String {
        let done = todayCompletedCount()
        let total = todayScheduledCount()
        let memory = UserMemoryStore.shared.memory
        let topStreak = memory.currentStreaks.max(by: { $0.value < $1.value })

        if done == total && total > 0 {
            // All done
            if let streak = topStreak {
                return "Clean sweep. \(streak.key) streak: \(streak.value) days. Tomorrow we go again."
            }
            return "Everything done. That's the standard. Sleep well. 🐕"
        } else if done > 0 {
            // Partial
            return "\(done)/\(total) today. Not perfect, not zero. \(total - done) left on the table."
        } else if total > 0 {
            // Nothing done
            return "Zero today. It happens. Tomorrow's not optional. 🐕"
        }
        return "Rest day. Recharge. Tomorrow counts. 🌙"
    }

    private func weeklyFallbackMessage() -> String {
        let stats = calculateWeeklyStats()
        return "This week: \(stats.commitmentsCompleted)/\(stats.totalScheduled) commitments. \(String(format: "%.1f", stats.hoursReclaimed))h reclaimed. 📊"
    }

    // MARK: - Cached Message Lookup

    private func cachedMessage(for type: RetentionMessageType) -> CachedRetentionMessage? {
        let calendar = Calendar.current
        let todayWeekday = calendar.component(.weekday, from: Date())
        return cachedMessages.first {
            $0.type == type &&
            !$0.delivered &&
            ($0.dayOfWeek == todayWeekday || calendar.isDateInToday($0.generatedAt))
        }
    }

    // MARK: - Sunday Night Batch Pre-Generation

    func preGenerateWeekMessages() async {
        let memory = UserMemoryStore.shared.memory
        let statsContext = buildStatsContext()
        let patterns = detectPatterns()

        let systemPrompt = """
        You are RawDog, a disciplined Shiba Inu accountability coach. \
        Direct, warm, honest. Never preachy. Never generic. \
        Reference their actual data and patterns. Use contractions. \
        Short sentences. Max 2 sentences per message.

        \(memory.toContextString())

        RECENT PATTERNS:
        \(patterns.joined(separator: "\n"))

        STATS:
        \(statsContext)
        """

        var newMessages: [CachedRetentionMessage] = []
        let dayNames = ["", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

        // Generate 7 days of morning/midday/evening messages
        for weekday in 1...7 {
            let dayName = dayNames[weekday]

            // Morning
            if config.morningEnabled {
                let prompt = buildMorningPrompt(memory: memory, dayName: dayName)
                if let msg = await generateMessage(system: systemPrompt, prompt: prompt, type: .morning, dayOfWeek: weekday) {
                    newMessages.append(msg)
                }
            }

            // Midday
            if config.middayEnabled {
                let prompt = buildMiddayPrompt(memory: memory, dayName: dayName)
                if let msg = await generateMessage(system: systemPrompt, prompt: prompt, type: .midday, dayOfWeek: weekday) {
                    newMessages.append(msg)
                }
            }

            // Evening
            if config.eveningEnabled {
                let prompt = buildEveningPrompt(memory: memory, dayName: dayName)
                if let msg = await generateMessage(system: systemPrompt, prompt: prompt, type: .evening, dayOfWeek: weekday) {
                    newMessages.append(msg)
                }
            }
        }

        // Weekly summary (for Monday)
        if config.weeklyEnabled {
            let prompt = buildWeeklyPrompt(memory: memory)
            if let msg = await generateMessage(system: systemPrompt, prompt: prompt, type: .weekly, dayOfWeek: config.weeklyDay) {
                newMessages.append(msg)
            }
        }

        if !newMessages.isEmpty {
            // Replace this week's messages, keep last 2 weeks for history
            let calendar = Calendar.current
            let twoWeeksAgo = calendar.date(byAdding: .weekOfYear, value: -2, to: Date()) ?? Date()
            var existing = cachedMessages.filter { $0.generatedAt >= twoWeeksAgo }
            // Remove this week's undelivered batch
            existing.removeAll { !$0.delivered && $0.generatedAt >= (calendar.date(byAdding: .day, value: -1, to: Date()) ?? Date()) }
            existing.append(contentsOf: newMessages)
            cachedMessages = existing

            Constants.sharedDefaults.set(Date(), forKey: Self.lastPregenDateKey)
            scheduleAllNotifications()
        }
    }

    /// Fallback: generate just today's messages if Sunday batch missed
    func preGenerateTodayMessages() async {
        let memory = UserMemoryStore.shared.memory
        let statsContext = buildStatsContext()

        let systemPrompt = """
        You are RawDog, a disciplined Shiba Inu accountability coach. \
        Direct, warm, honest. Never preachy. Never generic. \
        Reference their actual data. Use contractions. Short sentences. Max 2 sentences.

        \(memory.toContextString())

        TODAY'S DATA:
        \(statsContext)
        """

        let calendar = Calendar.current
        let todayWeekday = calendar.component(.weekday, from: Date())
        let dayNames = ["", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        let dayName = dayNames[todayWeekday]

        var newMessages: [CachedRetentionMessage] = []

        if config.morningEnabled {
            if let msg = await generateMessage(
                system: systemPrompt,
                prompt: buildMorningPrompt(memory: memory, dayName: dayName),
                type: .morning,
                dayOfWeek: todayWeekday
            ) {
                newMessages.append(msg)
            }
        }

        if config.middayEnabled {
            if let msg = await generateMessage(
                system: systemPrompt,
                prompt: buildMiddayPrompt(memory: memory, dayName: dayName),
                type: .midday,
                dayOfWeek: todayWeekday
            ) {
                newMessages.append(msg)
            }
        }

        if config.eveningEnabled {
            if let msg = await generateMessage(
                system: systemPrompt,
                prompt: buildEveningPrompt(memory: memory, dayName: dayName),
                type: .evening,
                dayOfWeek: todayWeekday
            ) {
                newMessages.append(msg)
            }
        }

        if !newMessages.isEmpty {
            var existing = cachedMessages
            existing.append(contentsOf: newMessages)
            cachedMessages = existing
            scheduleAllNotifications()
        }
    }

    private func generateMessage(system: String, prompt: String, type: RetentionMessageType, dayOfWeek: Int) async -> CachedRetentionMessage? {
        do {
            let body = try await GroqService.shared.callRetention(system: system, user: prompt, maxTokens: 150)
            return CachedRetentionMessage(type: type, body: body, dayOfWeek: dayOfWeek)
        } catch {
            print("RetentionService: Failed to generate \(type.rawValue) message: \(error)")
            return nil
        }
    }

    // MARK: - Prompt Builders

    private func buildMorningPrompt(memory: UserMemory, dayName: String) -> String {
        let streakInfo = memory.currentStreaks.map { "\($0.key): \($0.value) days" }.joined(separator: ", ")
        let commitments = CommitmentStore.commitments.filter(\.isActive)
        let firstCommitment = commitments.sorted(by: { $0.scheduledHour < $1.scheduledHour }).first

        var prompt = """
        Write a morning notification for \(dayName).
        Format: "[First commitment] in [X] minutes. You've done this [streak] days straight. Don't be the person who stops here."
        """

        if let first = firstCommitment {
            let stat = CommitmentStore.stats(for: first.id)
            prompt += "\nFirst commitment: \(first.title) (streak: \(stat.currentStreak) days)"
        }

        if !streakInfo.isEmpty {
            prompt += "\nAll streaks: \(streakInfo)"
        }

        if memory.peakPerformanceDays.contains(dayName) {
            prompt += "\n\(dayName) is one of their best days — amp it up."
        }
        if memory.consistentlySkippedDays.contains(dayName) {
            prompt += "\n\(dayName) is historically weak — gentle pushback, not guilt."
        }

        prompt += "\nMax 2 sentences. Reference real data. One line, no fluff."
        return prompt
    }

    private func buildMiddayPrompt(memory: UserMemory, dayName: String) -> String {
        let done = todayCompletedCount()
        let total = todayScheduledCount()

        var prompt = "Write a midday check-in notification for \(dayName)."

        if done == total && total > 0 {
            prompt += "\nAll \(total) done — quick acknowledgment."
        } else if done > 0 {
            prompt += "\n\(done)/\(total) done. Format: \"Halfway through. [Pending commitment] still pending. You've got time.\""
        } else if total > 0 {
            prompt += "\n0/\(total) done. Not a guilt trip, just: \"Hey. [Commitment] is waiting.\""
        } else {
            prompt += "\nNo commitments scheduled — friendly check-in only."
        }

        prompt += "\nMax 1-2 sentences. Only send if something is pending."
        return prompt
    }

    private func buildEveningPrompt(memory: UserMemory, dayName: String) -> String {
        let done = todayCompletedCount()
        let total = todayScheduledCount()
        let topStreak = memory.currentStreaks.max(by: { $0.value < $1.value })

        var prompt = "Write an evening reflection notification for \(dayName)."
        prompt += "\nToday's score: \(done)/\(total)."

        if done == total && total > 0 {
            prompt += "\nPerfect day. Format: \"Clean sweep. [Top streak] streak: [N] days. Tomorrow we go again.\""
        } else if done > 0 {
            prompt += "\nPartial. Format: \"\(done)/\(total) today. Not perfect, not zero. [N] left on the table.\""
        } else if total > 0 {
            prompt += "\nZero. Format: \"Zero today. It happens. Tomorrow's not optional.\""
        }

        if let streak = topStreak {
            prompt += "\nTop streak: \(streak.key) at \(streak.value) days."
        }

        prompt += "\nMax 2 sentences. Honest but forward-looking."
        return prompt
    }

    private func buildWeeklyPrompt(memory: UserMemory) -> String {
        let stats = calculateWeeklyStats()

        var prompt = """
        Write a weekly receipt notification.
        This week: \(stats.commitmentsCompleted)/\(stats.totalScheduled) commitments.
        Hours reclaimed: \(String(format: "%.1f", stats.hoursReclaimed)).
        """

        if let bestDay = stats.bestDay {
            prompt += "\nBest day: \(bestDay)."
        }
        if stats.verifiedPhotoCount > 0 {
            prompt += "\n\(stats.verifiedPhotoCount) photo-verified sessions."
        }

        prompt += "\nFrame as progress. What did they gain? Max 3 sentences."
        return prompt
    }

    // MARK: - Gamification Stats

    func calculateWeeklyStats() -> WeeklyRetentionStats {
        let calendar = Calendar.current
        let now = Date()

        var weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? now
        if calendar.component(.weekday, from: weekStart) == 1 {
            weekStart = calendar.date(byAdding: .day, value: -6, to: weekStart) ?? weekStart
        }

        let commitments = CommitmentStore.commitments.filter(\.isActive)
        let allLogs = CommitmentStore.logs
        let weekLogs = allLogs.filter { $0.date >= weekStart && $0.date <= now }
        let verified = weekLogs.filter { $0.status == .verified }
        let photos = weekLogs.compactMap(\.photoFilename).count

        var totalScheduled = 0
        for commitment in commitments {
            for dayOffset in 0..<7 {
                guard let day = calendar.date(byAdding: .day, value: dayOffset, to: weekStart),
                      day <= now else { continue }
                let weekday = calendar.component(.weekday, from: day)
                if commitment.scheduledDays.contains(weekday) {
                    totalScheduled += 1
                }
            }
        }

        let dayNames = ["", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        var dayCompletions: [Int: Int] = [:]
        for log in verified {
            let wd = calendar.component(.weekday, from: log.date)
            dayCompletions[wd, default: 0] += 1
        }
        let bestDayNum = dayCompletions.max(by: { $0.value < $1.value })?.key
        let bestDay = bestDayNum.flatMap { $0 < dayNames.count ? dayNames[$0] : nil }

        let hoursReclaimed = Double(verified.count) * 0.5
        let longestStreak = commitments.map { CommitmentStore.stats(for: $0.id).currentStreak }.max() ?? 0

        let stats = WeeklyRetentionStats(
            commitmentsCompleted: verified.count,
            totalScheduled: totalScheduled,
            hoursReclaimed: hoursReclaimed,
            longestStreakThisWeek: longestStreak,
            bestDay: bestDay,
            weekStartDate: weekStart,
            verifiedPhotoCount: photos
        )

        weeklyStats = stats
        return stats
    }

    func calculateMonthlyStats() -> MonthlyRetentionStats {
        let calendar = Calendar.current
        let now = Date()
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now

        let commitments = CommitmentStore.commitments.filter(\.isActive)
        let allLogs = CommitmentStore.logs
        let monthLogs = allLogs.filter { $0.date >= monthStart && $0.date <= now }
        let verified = monthLogs.filter { $0.status == .verified }
        let photos = monthLogs.compactMap(\.photoFilename).count

        var totalScheduled = 0
        var dayDate = monthStart
        while dayDate <= now {
            let weekday = calendar.component(.weekday, from: dayDate)
            for commitment in commitments {
                if commitment.scheduledDays.contains(weekday) {
                    totalScheduled += 1
                }
            }
            dayDate = calendar.date(byAdding: .day, value: 1, to: dayDate) ?? now
        }

        let dayNames = ["", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        var dayCompletions: [Int: Int] = [:]
        for log in verified {
            let wd = calendar.component(.weekday, from: log.date)
            dayCompletions[wd, default: 0] += 1
        }
        let bestDayNum = dayCompletions.max(by: { $0.value < $1.value })?.key
        let bestDay = bestDayNum.flatMap { $0 < dayNames.count ? dayNames[$0] : nil }

        var bestWeekCount = 0
        var bestWeekStart: Date?
        var checkDate = monthStart
        while checkDate <= now {
            let weekEnd = calendar.date(byAdding: .day, value: 7, to: checkDate) ?? now
            let weekVerified = verified.filter { $0.date >= checkDate && $0.date < weekEnd }.count
            if weekVerified > bestWeekCount {
                bestWeekCount = weekVerified
                bestWeekStart = checkDate
            }
            checkDate = calendar.date(byAdding: .day, value: 1, to: checkDate) ?? now
        }

        let longestStreak = commitments.map { CommitmentStore.stats(for: $0.id).bestStreak }.max() ?? 0

        let stats = MonthlyRetentionStats(
            commitmentsCompleted: verified.count,
            totalScheduled: totalScheduled,
            hoursReclaimed: Double(verified.count) * 0.5,
            bestDay: bestDay,
            bestWeekCommitments: bestWeekCount,
            bestWeekStartDate: bestWeekStart,
            verifiedPhotoCount: photos,
            longestStreak: longestStreak,
            monthStartDate: monthStart
        )

        monthlyStats = stats
        return stats
    }

    // MARK: - Pattern Detection

    func detectPatterns() -> [String] {
        let memory = UserMemoryStore.shared.memory
        var patterns: [String] = []

        if !memory.peakPerformanceDays.isEmpty {
            patterns.append("Crushes it on \(memory.peakPerformanceDays.joined(separator: " and "))")
        }
        if !memory.consistentlySkippedDays.isEmpty {
            patterns.append("\(memory.consistentlySkippedDays.joined(separator: " and ")) are tough days")
        }

        let commitments = CommitmentStore.commitments.filter(\.isActive)
        for commitment in commitments {
            let stat = CommitmentStore.stats(for: commitment.id)
            if stat.currentStreak >= 7 {
                patterns.append("\(commitment.title): \(stat.currentStreak)-day streak")
            }
            if stat.trend == .improving {
                patterns.append("\(commitment.title) trending up — \(Int(stat.completionRate * 100))%")
            } else if stat.trend == .declining && stat.currentStreak == 0 {
                patterns.append("\(commitment.title) needs attention — streak broken")
            }
        }

        return patterns
    }

    // MARK: - Stats Refresh

    private func refreshStatsIfNeeded() {
        let calendar = Calendar.current
        let lastWeekly = weeklyStats.weekStartDate
        let lastMonthly = monthlyStats.monthStartDate

        if !calendar.isDate(lastWeekly, equalTo: Date(), toGranularity: .weekOfYear) {
            _ = calculateWeeklyStats()
        }
        if !calendar.isDate(lastMonthly, equalTo: Date(), toGranularity: .month) {
            _ = calculateMonthlyStats()
        }
    }

    // MARK: - Helpers

    func todayCompletedCount() -> Int {
        CommitmentStore.logs.filter {
            Calendar.current.isDateInToday($0.date) && $0.status == .verified
        }.count
    }

    func todayScheduledCount() -> Int {
        let weekday = Calendar.current.component(.weekday, from: Date())
        return CommitmentStore.commitments.filter {
            $0.isActive && $0.scheduledDays.contains(weekday)
        }.count
    }

    private func pendingCommitments() -> [Commitment] {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        let todayLogs = CommitmentStore.logs.filter { calendar.isDateInToday($0.date) }
        let verifiedIDs = Set(todayLogs.filter { $0.status == .verified }.map(\.commitmentId))

        return CommitmentStore.commitments.filter {
            $0.isActive && $0.scheduledDays.contains(weekday) && !verifiedIDs.contains($0.id)
        }
    }

    private func firstUpcomingCommitment(from commitments: [Commitment]) -> Commitment? {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        let now = calendar.dateComponents([.hour, .minute], from: Date())
        let currentMinutes = (now.hour ?? 0) * 60 + (now.minute ?? 0)

        return commitments
            .filter { $0.isActive && $0.scheduledDays.contains(weekday) }
            .sorted { $0.scheduledHour * 60 + $0.scheduledMinute < $1.scheduledHour * 60 + $1.scheduledMinute }
            .first { ($0.scheduledHour * 60 + $0.scheduledMinute) > currentMinutes }
            ?? commitments.filter { $0.isActive && $0.scheduledDays.contains(weekday) }
                .sorted { $0.scheduledHour * 60 + $0.scheduledMinute < $1.scheduledHour * 60 + $1.scheduledMinute }
                .first
    }

    private func minutesUntilCommitment(_ commitment: Commitment) -> Int {
        let calendar = Calendar.current
        let now = calendar.dateComponents([.hour, .minute], from: Date())
        let currentMinutes = (now.hour ?? 0) * 60 + (now.minute ?? 0)
        let commitmentMinutes = commitment.scheduledHour * 60 + commitment.scheduledMinute
        let diff = commitmentMinutes - currentMinutes
        return diff > 0 ? diff : (diff + 1440) // wrap around midnight
    }

    private func buildStatsContext() -> String {
        let done = todayCompletedCount()
        let total = todayScheduledCount()
        let memory = UserMemoryStore.shared.memory
        let weekly = weeklyStats

        var ctx = "Today: \(done)/\(total) commitments done.\n"

        if !memory.currentStreaks.isEmpty {
            ctx += "Streaks: \(memory.currentStreaks.map { "\($0.key): \($0.value)d" }.joined(separator: ", "))\n"
        }

        ctx += "This week: \(weekly.commitmentsCompleted)/\(weekly.totalScheduled), "
        ctx += "\(String(format: "%.1f", weekly.hoursReclaimed))h reclaimed.\n"

        if let best = weekly.bestDay {
            ctx += "Best day this week: \(best).\n"
        }

        return ctx
    }
}

// MARK: - GroqService Extension for Retention

extension GroqService {

    func callRetention(system: String, user: String, maxTokens: Int = 150) async throws -> String {
        guard let url = URL(string: Constants.groqServiceBaseURL) else {
            throw GroqError.noResponse
        }

        let body: [String: Any] = [
            "model": "llama-3.1-8b-instant",
            "max_tokens": maxTokens,
            "messages": [
                ["role": "system", "content": system],
                ["role": "user", "content": user],
            ],
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            throw GroqError.parseError
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(Constants.aiServiceToken)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 15

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw GroqError.noResponse
        }

        let groqResponse = try JSONDecoder().decode(GroqResponse.self, from: data)
        guard let content = groqResponse.choices.first?.message.content else {
            throw GroqError.noResponse
        }

        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
