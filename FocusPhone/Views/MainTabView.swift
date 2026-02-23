import SwiftUI

struct MainDashboardView: View {
    @Binding var selectedTab: Int

    var body: some View {
        TabView(selection: $selectedTab) {
            ScheduleView()
                .tabItem {
                    Label("RawDog", systemImage: "house.fill")
                }
                .tag(0)

            CommitmentListView()
                .tabItem {
                    Label("Commit", systemImage: "checkmark.circle.fill")
                }
                .tag(1)

            HabitsDashboardView()
                .tabItem {
                    Label("Receipts", systemImage: "chart.bar.fill")
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
