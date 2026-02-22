import SwiftUI

struct MainDashboardView: View {
    @Binding var selectedTab: Int

    var body: some View {
        TabView(selection: $selectedTab) {
            RestrictionDashboardView()
                .tabItem {
                    Label("RawDog", systemImage: "shield.fill")
                }
                .tag(0)

            ControlledBrowserView()
                .tabItem {
                    Label("Browser", systemImage: "globe")
                }
                .tag(1)

            CommitmentListView()
                .tabItem {
                    Label("Commit", systemImage: "checkmark.circle.fill")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
        .tint(RawDog.Colors.accent)
        .preferredColorScheme(.dark)
    }
}
