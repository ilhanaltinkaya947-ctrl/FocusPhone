import Foundation

// MARK: - User Memory (the personalization layer)

struct UserMemory: Codable {
    // Identity
    var name: String = ""
    var goals: [String] = []
    var occupation: String = ""
    var dailyAvailableMinutes: Int = 60

    // Behavioral patterns (built from verification data)
    var peakPerformanceDays: [String] = []
    var consistentlySkippedDays: [String] = []
    var averageVerificationTime: [String: String] = [:]
    var bestPerformanceWeek: String = ""
    var currentStreaks: [String: Int] = [:]
    var completionRates: [String: Double] = [:]

    // Personality insights (AI-generated, updated weekly)
    var motivationStyle: String = ""
    var challengeLevel: String = "moderate"
    var primaryBlockers: [String] = []

    // Schedule preferences learned over time
    var preferredFocusBlocks: [String] = []
    var avoidTimeSlots: [String] = []
    var lastScheduleGeneratedAt: Date?
    var scheduleAdjustmentHistory: [String] = []

    // Mentor conversation context
    var lastCheckInDate: Date?
    var lastCheckInSummary: String = ""
    var openLoops: [String] = []
    var lifeMilestones: [String] = []

    // Raw stats summary for AI context
    var totalVerifiedSessions: Int = 0
    var longestStreak: Int = 0
    var memberSinceDate: Date = Date()

    func toContextString() -> String {
        var context = "USER PROFILE:\n"
        if !name.isEmpty { context += "Name: \(name)\n" }
        if !goals.isEmpty { context += "Goals: \(goals.joined(separator: ", "))\n" }
        if !occupation.isEmpty { context += "Occupation: \(occupation)\n" }
        context += "Member since: \(memberSinceDate.formatted(.dateTime.month().year()))\n"
        context += "Total verified sessions: \(totalVerifiedSessions)\n"
        context += "Longest streak ever: \(longestStreak) days\n\n"

        if !currentStreaks.isEmpty {
            context += "CURRENT STREAKS:\n"
            for (commitment, streak) in currentStreaks {
                context += "  \(commitment): \(streak) days\n"
            }
            context += "\n"
        }

        if !completionRates.isEmpty {
            context += "COMPLETION RATES (last 30 days):\n"
            for (commitment, rate) in completionRates {
                context += "  \(commitment): \(Int(rate * 100))%\n"
            }
            context += "\n"
        }

        if !peakPerformanceDays.isEmpty {
            context += "Best days: \(peakPerformanceDays.joined(separator: ", "))\n"
        }
        if !consistentlySkippedDays.isEmpty {
            context += "Consistently skips: \(consistentlySkippedDays.joined(separator: ", "))\n"
        }
        if !preferredFocusBlocks.isEmpty {
            context += "Peak focus windows: \(preferredFocusBlocks.joined(separator: ", "))\n"
        }
        if !primaryBlockers.isEmpty {
            context += "Known blockers: \(primaryBlockers.joined(separator: ", "))\n"
        }
        if !motivationStyle.isEmpty {
            context += "Motivation style: \(motivationStyle)\n"
        }
        if !lastCheckInSummary.isEmpty {
            context += "\nLAST CHECK-IN SUMMARY:\n\(lastCheckInSummary)\n"
        }
        if !openLoops.isEmpty {
            context += "\nFOLLOW-UPS:\n"
            for loop in openLoops {
                context += "  - \(loop)\n"
            }
        }

        return context
    }
}

// MARK: - User Memory Store

class UserMemoryStore {
    static let shared = UserMemoryStore()
    private let key = "rawdog_user_memory"

    var memory: UserMemory {
        get {
            AppState.shared.load(forKey: key) ?? UserMemory()
        }
        set {
            AppState.shared.save(newValue, forKey: key)
        }
    }

    func updateFromCommitmentLog(_ logs: [CommitmentLog], stats: [String: HabitStats]) {
        var m = memory

        for (commitment, stat) in stats {
            m.currentStreaks[commitment] = stat.currentStreak
            m.completionRates[commitment] = stat.completionRate
            m.totalVerifiedSessions = stat.totalVerified
            if stat.bestStreak > m.longestStreak {
                m.longestStreak = stat.bestStreak
            }
        }

        // Find skipped days pattern
        let calendar = Calendar.current
        let failedLogs = logs.filter { $0.status == .failed }
        var dayFailCounts: [Int: Int] = [:]
        for log in failedLogs {
            let weekday = calendar.component(.weekday, from: log.date)
            dayFailCounts[weekday, default: 0] += 1
        }

        let dayNames = ["", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        m.consistentlySkippedDays = dayFailCounts
            .filter { $0.value >= 3 }
            .map { dayNames[$0.key] }

        memory = m
    }

    func updateFromAIInsights(
        motivationStyle: String? = nil,
        blockers: [String]? = nil,
        checkInSummary: String? = nil,
        openLoops: [String]? = nil,
        milestone: String? = nil
    ) {
        var m = memory
        if let style = motivationStyle { m.motivationStyle = style }
        if let b = blockers { m.primaryBlockers = b }
        if let summary = checkInSummary {
            m.lastCheckInSummary = summary
            m.lastCheckInDate = Date()
        }
        if let loops = openLoops { m.openLoops = loops }
        if let win = milestone { m.lifeMilestones.append(win) }
        memory = m
    }
}
