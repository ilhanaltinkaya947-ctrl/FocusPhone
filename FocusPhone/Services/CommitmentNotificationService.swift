import Foundation
import UserNotifications

enum CommitmentNotificationService {

    static let verificationCategoryID = "COMMITMENT_VERIFICATION"
    static let verifyActionID = "VERIFY_NOW"

    // MARK: - Register Categories

    static func registerCategories() {
        let verifyAction = UNNotificationAction(
            identifier: verifyActionID,
            title: "Verify Now",
            options: [.foreground]
        )

        let category = UNNotificationCategory(
            identifier: verificationCategoryID,
            actions: [verifyAction],
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    // MARK: - Schedule Notifications

    static func scheduleNotifications(for commitment: Commitment) {
        guard commitment.isActive else { return }

        let center = UNUserNotificationCenter.current()
        let hour = commitment.scheduledHour
        let minute = commitment.scheduledMinute
        let idPrefix = commitment.id.uuidString

        if commitment.isDailyCommitment {
            // Single repeating trigger (no weekday component)
            schedulePreReminder30(center: center, id: "\(idPrefix)-pre30", commitment: commitment, hour: hour, minute: minute, weekday: nil)
            schedulePreReminder10(center: center, id: "\(idPrefix)-pre10", commitment: commitment, hour: hour, minute: minute, weekday: nil)
            scheduleVerificationPrompt(center: center, id: "\(idPrefix)-verify", commitment: commitment, hour: hour, minute: minute, weekday: nil)
            scheduleFailureFollowUp(center: center, id: "\(idPrefix)-fail", commitment: commitment, hour: hour, minute: minute, weekday: nil)
        } else {
            // Per-weekday triggers
            for weekday in commitment.scheduledDays {
                schedulePreReminder30(center: center, id: "\(idPrefix)-pre30-\(weekday)", commitment: commitment, hour: hour, minute: minute, weekday: weekday)
                schedulePreReminder10(center: center, id: "\(idPrefix)-pre10-\(weekday)", commitment: commitment, hour: hour, minute: minute, weekday: weekday)
                scheduleVerificationPrompt(center: center, id: "\(idPrefix)-verify-\(weekday)", commitment: commitment, hour: hour, minute: minute, weekday: weekday)
                scheduleFailureFollowUp(center: center, id: "\(idPrefix)-fail-\(weekday)", commitment: commitment, hour: hour, minute: minute, weekday: weekday)
            }
        }
    }

    // MARK: - Cancel Notifications

    static func cancelNotifications(for commitmentId: UUID) {
        let center = UNUserNotificationCenter.current()
        let prefix = commitmentId.uuidString

        center.getPendingNotificationRequests { requests in
            let matching = requests
                .filter { $0.identifier.hasPrefix(prefix) }
                .map { $0.identifier }
            center.removePendingNotificationRequests(withIdentifiers: matching)
        }
    }

    static func cancelFailureFollowUp(for commitmentId: UUID) {
        let center = UNUserNotificationCenter.current()
        let prefix = commitmentId.uuidString

        center.getPendingNotificationRequests { requests in
            let matching = requests
                .filter { $0.identifier.hasPrefix(prefix) && $0.identifier.contains("-fail") }
                .map { $0.identifier }
            center.removePendingNotificationRequests(withIdentifiers: matching)
        }
    }

    static func rescheduleAll() {
        let center = UNUserNotificationCenter.current()

        // Remove all commitment-related notifications
        center.getPendingNotificationRequests { requests in
            let commitmentIds = CommitmentStore.commitments.map { $0.id.uuidString }
            let matching = requests
                .filter { req in commitmentIds.contains(where: { req.identifier.hasPrefix($0) }) }
                .map { $0.identifier }
            center.removePendingNotificationRequests(withIdentifiers: matching)

            // Re-schedule all active
            for commitment in CommitmentStore.commitments where commitment.isActive {
                scheduleNotifications(for: commitment)
            }
        }
    }

    // MARK: - Streak Notifications

    static func scheduleStreakMilestone(for commitment: Commitment, streak: Int) {
        let content = UNMutableNotificationContent()
        content.title = "RawDog"
        content.body = NotificationCopy.message(for: commitment.category, type: .streakMilestone(streak), title: commitment.title)
        content.sound = .default

        // Fire 5 seconds from now
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(
            identifier: "streak-\(commitment.id.uuidString)-\(streak)",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    static func scheduleStreakAtRisk(for commitment: Commitment) {
        let content = UNMutableNotificationContent()
        content.title = "RawDog"
        content.body = NotificationCopy.message(for: commitment.category, type: .streakAtRisk, title: commitment.title)
        content.sound = .default

        // Fire at 8pm today
        var components = DateComponents()
        components.hour = 20
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let id = "streak-risk-\(commitment.id.uuidString)"

        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [id])
        center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }

    /// Check all active commitments and schedule streak-at-risk for any unverified today
    static func scheduleStreakAtRiskNotifications() {
        let calendar = Calendar.current
        let now = Date()
        guard calendar.component(.hour, from: now) < 20 else { return } // Only before 8pm

        for commitment in CommitmentStore.commitments where commitment.isActive {
            let todayLog = CommitmentStore.todayLog(for: commitment.id)
            let stats = CommitmentStore.stats(for: commitment.id)

            // Only if they have a streak and haven't verified today
            if stats.currentStreak > 0 && todayLog?.status != .verified {
                scheduleStreakAtRisk(for: commitment)
            }
        }
    }

    // MARK: - Daily Summary (9pm)

    static func scheduleDailySummary() {
        let center = UNUserNotificationCenter.current()
        let id = "daily-summary"

        center.removePendingNotificationRequests(withIdentifiers: [id])

        let activeCommitments = CommitmentStore.commitments.filter { $0.isActive }
        guard !activeCommitments.isEmpty else { return }

        let calendar = Calendar.current
        let todayWeekday = calendar.component(.weekday, from: Date())
        let todayCommitments = activeCommitments.filter { $0.scheduledDays.contains(todayWeekday) }
        guard !todayCommitments.isEmpty else { return }

        let done = todayCommitments.filter { CommitmentStore.todayLog(for: $0.id)?.status == .verified }.count
        let total = todayCommitments.count

        // Min streak across today's commitments (approximates "clean sweep" streak)
        let streak = todayCommitments.map { CommitmentStore.stats(for: $0.id).currentStreak }.min() ?? 0

        let content = UNMutableNotificationContent()
        content.title = "RawDog"
        content.body = NotificationCopy.dailySummary(done: done, total: total, streak: streak)
        content.sound = .default

        var components = DateComponents()
        components.hour = 21
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }

    // MARK: - Weekly Monday AI Message

    static func scheduleWeeklyMondayMessage() {
        Task {
            do {
                let message = try await GroqService.shared.generateWeeklyMorningMessage()

                let content = UNMutableNotificationContent()
                content.title = "RawDog"
                content.body = message
                content.sound = .default

                // Next Monday at 8am
                var components = DateComponents()
                components.weekday = 2 // Monday
                components.hour = 8
                components.minute = 0

                let id = "weekly-monday"
                let center = UNUserNotificationCenter.current()
                center.removePendingNotificationRequests(withIdentifiers: [id])

                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                try await center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
            } catch {
                // Silently fail — will retry next app launch
            }
        }
    }

    // MARK: - Journey Schedule Integration

    static func scheduleJourneyNotifications(for journey: Journey) {
        let center = UNUserNotificationCenter.current()
        let idPrefix = "journey-\(journey.id.uuidString)"

        // Cancel any previous journey notifications
        center.getPendingNotificationRequests { requests in
            let matching = requests
                .filter { $0.identifier.hasPrefix("journey-") }
                .map { $0.identifier }
            center.removePendingNotificationRequests(withIdentifiers: matching)
        }

        let dayNameToWeekday: [String: Int] = [
            "sunday": 1, "monday": 2, "tuesday": 3, "wednesday": 4,
            "thursday": 5, "friday": 6, "saturday": 7
        ]

        for week in journey.weeks {
            for day in week.days {
                guard let weekday = dayNameToWeekday[day.dayName.lowercased()] else { continue }

                let timeParts = day.task.scheduledTime.split(separator: ":")
                guard timeParts.count == 2,
                      let hour = Int(timeParts[0]),
                      let minute = Int(timeParts[1]) else { continue }

                let taskTitle = day.task.title

                // Pre-reminder (30 min before)
                let preId = "\(idPrefix)-w\(week.weekNumber)-\(day.dayName)-pre"
                let preContent = UNMutableNotificationContent()
                preContent.title = "RawDog"
                preContent.body = NotificationCopy.message(for: .custom, type: .preReminder30, title: taskTitle)
                preContent.sound = .default

                var preComponents = DateComponents()
                preComponents.weekday = weekday
                let preTotalMinutes = hour * 60 + minute - 30
                preComponents.hour = ((preTotalMinutes % 1440) + 1440) % 1440 / 60
                preComponents.minute = ((preTotalMinutes % 1440) + 1440) % 1440 % 60

                let preTrigger = UNCalendarNotificationTrigger(dateMatching: preComponents, repeats: true)
                center.add(UNNotificationRequest(identifier: preId, content: preContent, trigger: preTrigger))

                // Verification prompt (30 min after)
                let verifyId = "\(idPrefix)-w\(week.weekNumber)-\(day.dayName)-verify"
                let verifyContent = UNMutableNotificationContent()
                verifyContent.title = "RawDog"
                verifyContent.body = NotificationCopy.message(for: .custom, type: .verificationPrompt, title: taskTitle)
                verifyContent.sound = .default
                verifyContent.categoryIdentifier = verificationCategoryID

                var verifyComponents = DateComponents()
                verifyComponents.weekday = weekday
                let verifyTotalMinutes = hour * 60 + minute + 30
                verifyComponents.hour = (verifyTotalMinutes % 1440) / 60
                verifyComponents.minute = (verifyTotalMinutes % 1440) % 60

                let verifyTrigger = UNCalendarNotificationTrigger(dateMatching: verifyComponents, repeats: true)
                center.add(UNNotificationRequest(identifier: verifyId, content: verifyContent, trigger: verifyTrigger))
            }
        }
    }

    static func cancelJourneyNotifications() {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { requests in
            let matching = requests
                .filter { $0.identifier.hasPrefix("journey-") }
                .map { $0.identifier }
            center.removePendingNotificationRequests(withIdentifiers: matching)
        }
    }

    // MARK: - Private Helpers

    private static func schedulePreReminder30(
        center: UNUserNotificationCenter,
        id: String,
        commitment: Commitment,
        hour: Int,
        minute: Int,
        weekday: Int?
    ) {
        let content = UNMutableNotificationContent()
        content.title = "RawDog"
        content.body = NotificationCopy.message(for: commitment.category, type: .preReminder30, title: commitment.title)
        content.sound = .default

        var components = DateComponents()
        components.weekday = weekday

        let totalMinutes = hour * 60 + minute - 30
        components.hour = ((totalMinutes % 1440) + 1440) % 1440 / 60
        components.minute = ((totalMinutes % 1440) + 1440) % 1440 % 60

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }

    private static func schedulePreReminder10(
        center: UNUserNotificationCenter,
        id: String,
        commitment: Commitment,
        hour: Int,
        minute: Int,
        weekday: Int?
    ) {
        let content = UNMutableNotificationContent()
        content.title = "RawDog"
        content.body = NotificationCopy.message(for: commitment.category, type: .preReminder10, title: commitment.title)
        content.sound = .default

        var components = DateComponents()
        components.weekday = weekday

        let totalMinutes = hour * 60 + minute - 10
        components.hour = ((totalMinutes % 1440) + 1440) % 1440 / 60
        components.minute = ((totalMinutes % 1440) + 1440) % 1440 % 60

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }

    private static func scheduleVerificationPrompt(
        center: UNUserNotificationCenter,
        id: String,
        commitment: Commitment,
        hour: Int,
        minute: Int,
        weekday: Int?
    ) {
        let content = UNMutableNotificationContent()
        content.title = "RawDog"
        content.body = NotificationCopy.message(for: commitment.category, type: .verificationPrompt, title: commitment.title)
        content.sound = .default
        content.categoryIdentifier = verificationCategoryID
        content.userInfo = [
            "commitmentId": commitment.id.uuidString,
            "deepLink": "rawdog://verify?id=\(commitment.id.uuidString)"
        ]

        var components = DateComponents()
        components.weekday = weekday

        // 30 minutes after scheduled time
        let totalMinutes = hour * 60 + minute + 30
        components.hour = (totalMinutes % 1440) / 60
        components.minute = (totalMinutes % 1440) % 60

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }

    private static func scheduleFailureFollowUp(
        center: UNUserNotificationCenter,
        id: String,
        commitment: Commitment,
        hour: Int,
        minute: Int,
        weekday: Int?
    ) {
        let content = UNMutableNotificationContent()
        content.title = "RawDog"
        content.body = NotificationCopy.message(for: commitment.category, type: .noVerificationFollowup, title: commitment.title)
        content.sound = .default

        var components = DateComponents()
        components.weekday = weekday

        // 90 minutes after scheduled time
        let totalMinutes = hour * 60 + minute + 90
        components.hour = (totalMinutes % 1440) / 60
        components.minute = (totalMinutes % 1440) % 60

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }
}
