import Foundation
import UserNotifications

// MARK: - Comeback Mechanic Service

final class ComebackMechanicService {
    static let shared = ComebackMechanicService()

    private static let lastActiveKey = "comebackLastActiveDate"
    private static let comebackScheduledKey = "comebackNotificationsScheduled"

    // MARK: - Persistence

    var lastActiveDate: Date? {
        get { Constants.sharedDefaults.object(forKey: Self.lastActiveKey) as? Date }
        set { Constants.sharedDefaults.set(newValue, forKey: Self.lastActiveKey) }
    }

    private var comebackScheduled: Bool {
        get { Constants.sharedDefaults.bool(forKey: Self.comebackScheduledKey) }
        set { Constants.sharedDefaults.set(newValue, forKey: Self.comebackScheduledKey) }
    }

    // MARK: - Touch (call on every app open or verification)

    func recordActivity() {
        lastActiveDate = Date()
        comebackScheduled = false

        // Cancel any pending comeback notifications
        let ids = [
            "rawdog_comeback_day3",
            "rawdog_comeback_day5",
            "rawdog_comeback_day7",
            "rawdog_comeback_day14",
        ]
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }

    // MARK: - Check & Schedule (call on app launch)

    func checkAndSchedule() {
        guard !comebackScheduled else { return }
        guard let lastActive = lastActiveDate else {
            // First launch — record now
            recordActivity()
            return
        }

        let daysSince = Calendar.current.dateComponents([.day], from: lastActive, to: Date()).day ?? 0

        // If user has been active recently (within 2 days), schedule future comebacks
        if daysSince <= 2 {
            scheduleComebackNotifications(from: lastActive)
            comebackScheduled = true
        }
        // If already past Day 3, fire immediate check
        else if daysSince >= 3 {
            // Schedule remaining milestones from now
            scheduleComebackNotifications(from: Date())
            comebackScheduled = true
        }
    }

    // MARK: - Schedule Comeback Notifications

    private func scheduleComebackNotifications(from baseDate: Date) {
        let calendar = Calendar.current

        // Day 3
        if let day3 = calendar.date(byAdding: .day, value: 3, to: baseDate), day3 > Date() {
            scheduleNotification(
                id: "rawdog_comeback_day3",
                at: day3,
                body: day3Message()
            )
        }

        // Day 5
        if let day5 = calendar.date(byAdding: .day, value: 5, to: baseDate), day5 > Date() {
            scheduleNotification(
                id: "rawdog_comeback_day5",
                at: day5,
                body: day5Message()
            )
        }

        // Day 7
        if let day7 = calendar.date(byAdding: .day, value: 7, to: baseDate), day7 > Date() {
            scheduleNotification(
                id: "rawdog_comeback_day7",
                at: day7,
                body: day7Message()
            )
        }

        // Day 14
        if let day14 = calendar.date(byAdding: .day, value: 14, to: baseDate), day14 > Date() {
            scheduleNotification(
                id: "rawdog_comeback_day14",
                at: day14,
                body: day14Message(),
                deepLink: "focusphone://dashboard"
            )
        }
    }

    private func scheduleNotification(id: String, at date: Date, body: String, deepLink: String? = nil) {
        let content = UNMutableNotificationContent()
        content.title = "RawDog"
        content.body = body
        content.sound = .default
        content.userInfo = ["type": "comeback"]

        if let link = deepLink {
            content.userInfo["deepLink"] = link
        }

        // Schedule for 10 AM on the target day
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = 10
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: id,
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Comeback Messages

    private func day3Message() -> String {
        let memory = UserMemoryStore.shared.memory
        let topStreak = memory.currentStreaks.max(by: { $0.value < $1.value })

        if let streak = topStreak, streak.value > 0 {
            return "3 days gone. Your \(streak.key) streak is still at \(streak.value). Come back before it's not. 🐕"
        }
        return "3 days. RawDog noticed you're gone. The commitments are still here. 🐕"
    }

    private func day5Message() -> String {
        let memory = UserMemoryStore.shared.memory
        let totalVerified = memory.totalVerifiedSessions

        if totalVerified > 10 {
            return "5 days. You had \(totalVerified) verified sessions. That version of you is still in there. 🐕"
        }
        return "5 days without checking in. Not judging. Just here. Open the app when you're ready. 🐕"
    }

    private func day7Message() -> String {
        return "One week. That's a long time to go quiet. You don't have to be perfect — just show up once. 🐕"
    }

    private func day14Message() -> String {
        return "14 days. Fresh start? RawDog can reset your plan. No judgment, just a new Day 1. Tap to begin. 🐕"
    }

    // MARK: - Re-engagement Check

    /// Returns true if user has been away 14+ days (should trigger re-onboarding)
    var shouldOfferReOnboarding: Bool {
        guard let lastActive = lastActiveDate else { return false }
        let daysSince = Calendar.current.dateComponents([.day], from: lastActive, to: Date()).day ?? 0
        return daysSince >= 14
    }

    /// Returns days since last active, nil if never set
    var daysSinceLastActive: Int? {
        guard let lastActive = lastActiveDate else { return nil }
        return Calendar.current.dateComponents([.day], from: lastActive, to: Date()).day
    }
}
