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
        case "calendar": selectedTab = 0
        case "modes":    selectedTab = 1
        case "stats":    selectedTab = 2
        case "settings": selectedTab = 3
        default:         break
        }
    }
}
