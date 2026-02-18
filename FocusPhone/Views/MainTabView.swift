import SwiftUI

struct MainTabView: View {
    @Binding var selectedTab: Int

    var body: some View {
        TabView(selection: $selectedTab) {
            CalendarTab()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }
                .tag(0)

            ModeListTab()
                .tabItem {
                    Label("Modes", systemImage: "square.stack.fill")
                }
                .tag(1)

            StatsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.fill")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
    }
}
