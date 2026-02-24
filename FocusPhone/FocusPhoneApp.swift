import SwiftUI
import FamilyControls
import UserNotifications

@main
struct RawDogApp: App {
    @State private var selectedTab = 0
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView(selectedTab: $selectedTab)
                .onOpenURL { url in
                    handleDeepLink(url)
                }
                .onAppear {
                    setupCommitmentNotifications()
                }
        }
    }

    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "rawdog" else { return }
        switch url.host {
        case "dashboard":    selectedTab = 0
        case "commitments":  selectedTab = 1
        case "receipts":     selectedTab = 2
        case "settings":     selectedTab = 3
        case "extension":    selectedTab = 0
        case "verify":
            selectedTab = 1
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let idString = components.queryItems?.first(where: { $0.name == "id" })?.value,
               let commitmentId = UUID(uuidString: idString) {
                NotificationCenter.default.post(
                    name: .commitmentVerificationRequested,
                    object: nil,
                    userInfo: ["commitmentId": commitmentId]
                )
            }
        default: break
        }
    }

    private func setupCommitmentNotifications() {
        CommitmentNotificationService.registerCategories()
        CommitmentNotificationService.rescheduleAll()
        CommitmentNotificationService.scheduleDailySummary()
        CommitmentNotificationService.scheduleStreakAtRiskNotifications()
        CommitmentNotificationService.scheduleWeeklyMondayMessage()

        // Retention system
        RetentionService.shared.setup()
        StreakService.shared.syncAll()
        ComebackMechanicService.shared.recordActivity()
        ComebackMechanicService.shared.checkAndSchedule()

        // Habit stacking (runs weekly after 2 weeks of data)
        Task {
            await HabitStackingService.shared.analyzeIfNeeded()
        }
    }
}

// MARK: - AppDelegate for Notification Handling

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        RawDog.configureTabBarAppearance()
        return true
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        // Track notification open for intelligence
        if let type = userInfo["type"] as? String {
            NotificationIntelligenceService.shared.recordOpened(type: type)
        }

        if response.actionIdentifier == CommitmentNotificationService.verifyActionID {
            if let deepLink = userInfo["deepLink"] as? String,
               let url = URL(string: deepLink) {
                UIApplication.shared.open(url)
            }
        }

        // Handle comeback deep links
        if let deepLink = userInfo["deepLink"] as? String,
           let url = URL(string: deepLink) {
            UIApplication.shared.open(url)
        }

        completionHandler()
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}

// MARK: - Notification Name

extension Notification.Name {
    static let commitmentVerificationRequested = Notification.Name("commitmentVerificationRequested")
}
