import SwiftUI

struct ContentView: View {
    @Binding var selectedTab: Int
    @StateObject private var authVM = AuthViewModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if AppState.shared.isOnboardingCompleted {
                MainDashboardView(selectedTab: $selectedTab)
            } else {
                ConversationalOnboardingView(authVM: authVM)
            }
        }
        .onAppear {
            AppState.shared.migrateIfNeeded()
            if AppState.shared.isRestrictionActive {
                RestrictionEngine.reapplyActiveProfile()
            }
        }
        .onChange(of: scenePhase) {
            if scenePhase == .active, AppState.shared.isRestrictionActive {
                RestrictionEngine.reapplyActiveProfile()
            }
        }
    }
}
