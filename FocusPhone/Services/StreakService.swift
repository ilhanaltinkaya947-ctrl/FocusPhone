import Foundation
import UserNotifications

// MARK: - Streak Record

struct StreakRecord: Codable, Identifiable {
    let id: UUID
    let commitmentId: UUID
    var commitmentTitle: String
    var currentStreak: Int
    var bestStreak: Int
    var lastVerifiedDate: Date?
    var milestonesReached: [Int]

    init(commitmentId: UUID, commitmentTitle: String) {
        self.id = UUID()
        self.commitmentId = commitmentId
        self.commitmentTitle = commitmentTitle
        self.currentStreak = 0
        self.bestStreak = 0
        self.lastVerifiedDate = nil
        self.milestonesReached = []
    }
}

// MARK: - Overall Streak Summary

struct OverallStreakSummary: Codable {
    var totalDaysActive: Int = 0
    var totalHoursRecovered: Double = 0
    var longestOverallStreak: Int = 0
    var currentOverallStreak: Int = 0
    var totalVerifiedSessions: Int = 0
    var lastActiveDate: Date?
}

// MARK: - Streak Service

final class StreakService {
    static let shared = StreakService()

    private static let recordsKey = "streakRecords"
    private static let summaryKey = "overallStreakSummary"
    private static let lastMilestoneCheckKey = "streakLastMilestoneCheck"

    static let milestones = [3, 7, 14, 21, 30, 60, 90]

    // MARK: - Persistence

    var records: [StreakRecord] {
        get { AppState.shared.load(forKey: Self.recordsKey) ?? [] }
        set { AppState.shared.save(newValue, forKey: Self.recordsKey) }
    }

    var summary: OverallStreakSummary {
        get { AppState.shared.load(forKey: Self.summaryKey) ?? OverallStreakSummary() }
        set { AppState.shared.save(newValue, forKey: Self.summaryKey) }
    }

    // MARK: - Sync from CommitmentStore

    func syncAll() {
        let commitments = CommitmentStore.commitments.filter(\.isActive)
        var currentRecords = records

        for commitment in commitments {
            let stats = CommitmentStore.stats(for: commitment.id)

            if let idx = currentRecords.firstIndex(where: { $0.commitmentId == commitment.id }) {
                let oldStreak = currentRecords[idx].currentStreak
                currentRecords[idx].currentStreak = stats.currentStreak
                currentRecords[idx].bestStreak = max(currentRecords[idx].bestStreak, stats.bestStreak)
                currentRecords[idx].commitmentTitle = commitment.title

                if stats.currentStreak > 0 {
                    currentRecords[idx].lastVerifiedDate = Date()
                }

                // Check milestones
                checkMilestones(
                    oldStreak: oldStreak,
                    newStreak: stats.currentStreak,
                    record: &currentRecords[idx]
                )

                // Check streak broken
                if oldStreak > 0 && stats.currentStreak == 0 {
                    notifyStreakBroken(commitment: commitment, lostStreak: oldStreak)
                }
            } else {
                var newRecord = StreakRecord(
                    commitmentId: commitment.id,
                    commitmentTitle: commitment.title
                )
                newRecord.currentStreak = stats.currentStreak
                newRecord.bestStreak = stats.bestStreak
                if stats.currentStreak > 0 {
                    newRecord.lastVerifiedDate = Date()
                }
                currentRecords.append(newRecord)
            }
        }

        // Remove records for deleted commitments
        let activeIDs = Set(commitments.map(\.id))
        currentRecords.removeAll { !activeIDs.contains($0.commitmentId) }

        records = currentRecords
        updateOverallSummary()
    }

    // MARK: - On Verification (call after each log save)

    func onVerification(commitmentId: UUID) {
        let commitments = CommitmentStore.commitments
        guard let commitment = commitments.first(where: { $0.id == commitmentId }) else { return }
        let stats = CommitmentStore.stats(for: commitmentId)

        var currentRecords = records

        if let idx = currentRecords.firstIndex(where: { $0.commitmentId == commitmentId }) {
            let oldStreak = currentRecords[idx].currentStreak
            currentRecords[idx].currentStreak = stats.currentStreak
            currentRecords[idx].bestStreak = max(currentRecords[idx].bestStreak, stats.bestStreak)
            currentRecords[idx].lastVerifiedDate = Date()

            checkMilestones(
                oldStreak: oldStreak,
                newStreak: stats.currentStreak,
                record: &currentRecords[idx]
            )
        } else {
            var newRecord = StreakRecord(
                commitmentId: commitmentId,
                commitmentTitle: commitment.title
            )
            newRecord.currentStreak = stats.currentStreak
            newRecord.bestStreak = stats.bestStreak
            newRecord.lastVerifiedDate = Date()
            currentRecords.append(newRecord)
        }

        records = currentRecords
        updateOverallSummary()
    }

    // MARK: - On Failure/Skip

    func onStreakBroken(commitmentId: UUID) {
        let commitments = CommitmentStore.commitments
        guard let commitment = commitments.first(where: { $0.id == commitmentId }) else { return }

        var currentRecords = records
        if let idx = currentRecords.firstIndex(where: { $0.commitmentId == commitmentId }) {
            let lostStreak = currentRecords[idx].currentStreak
            if lostStreak > 0 {
                currentRecords[idx].currentStreak = 0
                records = currentRecords
                notifyStreakBroken(commitment: commitment, lostStreak: lostStreak)
            }
        }

        updateOverallSummary()
    }

    // MARK: - Milestone System

    private func checkMilestones(oldStreak: Int, newStreak: Int, record: inout StreakRecord) {
        for milestone in Self.milestones {
            if newStreak >= milestone && oldStreak < milestone && !record.milestonesReached.contains(milestone) {
                record.milestonesReached.append(milestone)
                notifyMilestone(days: milestone, title: record.commitmentTitle)
            }
        }
    }

    private func notifyMilestone(days: Int, title: String) {
        let content = UNMutableNotificationContent()
        content.title = "RawDog"
        content.body = milestoneMessage(days: days, title: title)
        content.sound = .default
        content.userInfo = ["type": "streak_milestone", "days": days]

        let request = UNNotificationRequest(
            identifier: "rawdog_milestone_\(title)_\(days)",
            content: content,
            trigger: nil // immediate
        )
        UNUserNotificationCenter.current().add(request)
    }

    private func milestoneMessage(days: Int, title: String) -> String {
        switch days {
        case 3:
            return "\(days) days of \(title). Most people quit by now. You didn't. 🐕"
        case 7:
            return "7 days of \(title). One full week. That's not luck, that's you. 💪"
        case 14:
            return "14 days. \(title) is becoming a habit. Your brain is literally rewiring. 🧠"
        case 21:
            return "21 days of \(title). Three weeks. This is who you are now. 🔥"
        case 30:
            return "30 DAYS. \(title). One full month. RawDog is genuinely proud. 🐕💪"
        case 60:
            return "60 days of \(title). Two months. You're in the top 1% of people who actually stick with it. 🏆"
        case 90:
            return "90 DAYS. \(title). This isn't a streak anymore — it's your life. Absolute legend. 👑"
        default:
            return "\(days) days of \(title). Keep stacking. 🐕"
        }
    }

    // MARK: - Streak Broken Notification

    private func notifyStreakBroken(commitment: Commitment, lostStreak: Int) {
        let content = UNMutableNotificationContent()
        content.title = "RawDog"
        content.body = streakBrokenMessage(title: commitment.title, lostStreak: lostStreak)
        content.sound = .default
        content.userInfo = [
            "type": "streak_broken",
            "commitmentId": commitment.id.uuidString,
            "deepLink": "rawdog://commitments",
        ]

        let request = UNNotificationRequest(
            identifier: "rawdog_streak_broken_\(commitment.id.uuidString)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    private func streakBrokenMessage(title: String, lostStreak: Int) -> String {
        if lostStreak >= 14 {
            return "\(title) streak broken at \(lostStreak) days. That hurts. But \(lostStreak) days happened. Start the next one. 🐕"
        } else if lostStreak >= 7 {
            return "\(title) streak ended at \(lostStreak) days. You know what it feels like to build it. Do it again. 💪"
        } else if lostStreak >= 3 {
            return "\(title) — \(lostStreak) day streak gone. Tomorrow: day 1. No shame, just restart. 🐕"
        }
        return "\(title) missed. New streak starts tomorrow. 🐕"
    }

    // MARK: - Overall Summary

    private func updateOverallSummary() {
        let allRecords = records
        let allLogs = CommitmentStore.logs

        var s = summary

        // Total verified sessions
        s.totalVerifiedSessions = allLogs.filter { $0.status == .verified }.count

        // Total hours recovered (30 min per session)
        s.totalHoursRecovered = Double(s.totalVerifiedSessions) * 0.5

        // Longest streak across all commitments
        s.longestOverallStreak = allRecords.map(\.bestStreak).max() ?? 0

        // Current best streak
        s.currentOverallStreak = allRecords.map(\.currentStreak).max() ?? 0

        // Total active days (days with at least one verification)
        let calendar = Calendar.current
        let verifiedDates = Set(allLogs.filter { $0.status == .verified }.map { calendar.startOfDay(for: $0.date) })
        s.totalDaysActive = verifiedDates.count

        // Last active date
        s.lastActiveDate = allLogs.filter { $0.status == .verified }.map(\.date).max()

        summary = s

        // Update UserMemory
        var memory = UserMemoryStore.shared.memory
        memory.longestStreak = s.longestOverallStreak
        memory.totalVerifiedSessions = s.totalVerifiedSessions
        UserMemoryStore.shared.memory = memory
    }

    // MARK: - Query Helpers

    func streak(for commitmentId: UUID) -> Int {
        records.first(where: { $0.commitmentId == commitmentId })?.currentStreak ?? 0
    }

    func bestStreak(for commitmentId: UUID) -> Int {
        records.first(where: { $0.commitmentId == commitmentId })?.bestStreak ?? 0
    }

    func activeMilestones(for commitmentId: UUID) -> [Int] {
        records.first(where: { $0.commitmentId == commitmentId })?.milestonesReached ?? []
    }

    func nextMilestone(for commitmentId: UUID) -> Int? {
        let current = streak(for: commitmentId)
        return Self.milestones.first { $0 > current }
    }

    func daysUntilNextMilestone(for commitmentId: UUID) -> Int? {
        guard let next = nextMilestone(for: commitmentId) else { return nil }
        let current = streak(for: commitmentId)
        return next - current
    }

    /// Days since user last had any verified session
    var daysSinceLastActive: Int? {
        guard let lastDate = summary.lastActiveDate else { return nil }
        return Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day
    }
}
