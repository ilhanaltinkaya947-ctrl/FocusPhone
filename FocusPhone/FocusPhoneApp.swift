import SwiftUI
import FamilyControls

@main
struct FocusPhoneApp: App {
    @State private var selectedTab = 0

    var body: some Scene {
        WindowGroup {
            ContentView(selectedTab: $selectedTab)
                .onOpenURL { url in
                    handleDeepLink(url)
                }
        }
    }

    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "focusphone" else { return }
        switch url.host {
        case "dashboard": selectedTab = 0
        case "browser":   selectedTab = 1
        case "settings":  selectedTab = 2
        case "extension": selectedTab = 0 // opens dashboard where extension request lives
        default:          break
        }
    }
}
