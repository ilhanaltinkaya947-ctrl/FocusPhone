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
            schedulePreReminder(
                center: center,
                id: "\(idPrefix)-pre",
                commitment: commitment,
                hour: hour,
                minute: minute,
                weekday: nil
            )
            scheduleVerificationPrompt(
                center: center,
                id: "\(idPrefix)-verify",
                commitment: commitment,
                hour: hour,
                minute: minute,
                weekday: nil
            )
            scheduleFailureFollowUp(
                center: center,
                id: "\(idPrefix)-fail",
                commitment: commitment,
                hour: hour,
                minute: minute,
                weekday: nil
            )
        } else {
            // Per-weekday triggers
            for weekday in commitment.scheduledDays {
                schedulePreReminder(
                    center: center,
                    id: "\(idPrefix)-pre-\(weekday)",
                    commitment: commitment,
                    hour: hour,
                    minute: minute,
                    weekday: weekday
                )
                scheduleVerificationPrompt(
                    center: center,
                    id: "\(idPrefix)-verify-\(weekday)",
                    commitment: commitment,
                    hour: hour,
                    minute: minute,
                    weekday: weekday
                )
                scheduleFailureFollowUp(
                    center: center,
                    id: "\(idPrefix)-fail-\(weekday)",
                    commitment: commitment,
                    hour: hour,
                    minute: minute,
                    weekday: weekday
                )
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

                // Pre-reminder (30 min before)
                let preId = "\(idPrefix)-w\(week.weekNumber)-\(day.dayName)-pre"
                let preContent = UNMutableNotificationContent()
                preContent.title = "RawDog"
                preContent.body = "\(day.task.title.uppercased()) IN 30. LET'S GO. \u{1F436}"
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
                verifyContent.body = "Did you finish \(day.task.title)? Send your proof. \u{1F436}"
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

    private static func schedulePreReminder(
        center: UNUserNotificationCenter,
        id: String,
        commitment: Commitment,
        hour: Int,
        minute: Int,
        weekday: Int?
    ) {
        let content = UNMutableNotificationContent()
        content.title = "RawDog"
        content.body = preReminderMessage(for: commitment)
        content.sound = .default

        var components = DateComponents()
        components.weekday = weekday

        // Subtract reminder minutes
        let totalMinutes = hour * 60 + minute - commitment.reminderMinutesBefore
        components.hour = ((totalMinutes % 1440) + 1440) % 1440 / 60
        components.minute = ((totalMinutes % 1440) + 1440) % 1440 % 60

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(request)
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
        content.body = "Are you there? Send your proof. \u{1F436}"
        content.sound = .default
        content.categoryIdentifier = verificationCategoryID
        content.userInfo = [
            "commitmentId": commitment.id.uuidString,
            "deepLink": "focusphone://verify?id=\(commitment.id.uuidString)"
        ]

        var components = DateComponents()
        components.weekday = weekday

        // 30 minutes after scheduled time
        let totalMinutes = hour * 60 + minute + 30
        components.hour = (totalMinutes % 1440) / 60
        components.minute = (totalMinutes % 1440) % 60

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(request)
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
        content.body = "No check-in. What happened? RawDog is still watching."
        content.sound = .default

        var components = DateComponents()
        components.weekday = weekday

        // 90 minutes after scheduled time
        let totalMinutes = hour * 60 + minute + 90
        components.hour = (totalMinutes % 1440) / 60
        components.minute = (totalMinutes % 1440) % 60

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(request)
    }

    private static func preReminderMessage(for commitment: Commitment) -> String {
        let mins = commitment.reminderMinutesBefore
        switch commitment.category {
        case .gym:
            return "GYM IN \(mins) MINUTES. LET'S GOOOOOO \u{1F436}"
        case .study:
            return "STUDY SESSION IN \(mins) MIN. CLEAR YOUR DESK."
        case .work:
            return "DEEP WORK STARTS IN \(mins). CLOSE THE TABS."
        case .outdoor:
            return "GET OUTSIDE IN \(mins). NO EXCUSES."
        case .custom:
            return "\(commitment.title.uppercased()) IN \(mins). LET'S GO. \u{1F436}"
        }
    }
}
