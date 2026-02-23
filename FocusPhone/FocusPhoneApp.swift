import SwiftUI
import FamilyControls
import UserNotifications

@main
struct FocusPhoneApp: App {
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
        guard url.scheme == "focusphone" else { return }
        switch url.host {
        case "dashboard":    selectedTab = 0
        case "browser":      selectedTab = 1
        case "commitments":  selectedTab = 2
        case "receipts":     selectedTab = 3
        case "settings":     selectedTab = 4
        case "extension":    selectedTab = 0
        case "verify":
            selectedTab = 2
            // The commitmentId is in the query: ?id=UUID
            // CommitmentListView will handle showing the verification sheet
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
    }
}

// MARK: - AppDelegate for Notification Handling

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if response.actionIdentifier == CommitmentNotificationService.verifyActionID {
            if let deepLink = response.notification.request.content.userInfo["deepLink"] as? String,
               let url = URL(string: deepLink) {
                UIApplication.shared.open(url)
            }
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
