import Foundation
import UserNotifications

enum NotificationService {

    static func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, error in
            if let error {
                print("NotificationService: Permission error: \(error)")
            }
        }
    }

    /// Schedule a notification when a timed window is about to expire (60s before).
    static func scheduleWindowExpiring(appName: String, in seconds: TimeInterval) {
        let warningTime = max(0, seconds - 60)
        guard warningTime > 0 else { return }

        let content = UNMutableNotificationContent()
        content.title = "Window Closing Soon"
        content.body = "\(appName) window closes in 1 minute."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: warningTime, repeats: false)
        let request = UNNotificationRequest(
            identifier: "window_expiring_\(appName)",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    /// Schedule a notification when a timed window opens.
    static func scheduleWindowOpening(appName: String, at date: Date) {
        let interval = date.timeIntervalSinceNow
        guard interval > 0 else { return }

        let content = UNMutableNotificationContent()
        content.title = "Window Open"
        content.body = "\(appName) is now available for a limited time."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(
            identifier: "window_opening_\(appName)",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    /// Notify when daily extension cap is reached.
    static func notifyDailyCapReached() {
        let content = UNMutableNotificationContent()
        content.title = "Daily Cap Reached"
        content.body = "You've used all your extension time for today. Stay strong."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "daily_cap_reached",
            content: content,
            trigger: nil // immediate
        )
        UNUserNotificationCenter.current().add(request)
    }

    static func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
