import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            CalendarTab()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }

            ModeListTab()
                .tabItem {
                    Label("Modes", systemImage: "square.stack.fill")
                }

            StatsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
    }
}
