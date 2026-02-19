import SwiftUI

struct ContentView: View {
    @Binding var selectedTab: Int
    @StateObject private var authVM = AuthViewModel()
    @StateObject private var weeklyReviewVM = WeeklyReviewViewModel()
    @State private var showingWeeklyReview = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if AppState.shared.isOnboardingCompleted {
                MainTabView(selectedTab: $selectedTab)
            } else {
                OnboardingView(authVM: authVM)
            }
        }
        .onAppear {
            AppState.shared.seedDefaultsIfNeeded()
            ScheduleService.registerAllTimeBlocks()
        }
        .onChange(of: scenePhase) {
            if scenePhase == .active {
                BlockingService.applyBlocksForActiveMode()
                if weeklyReviewVM.shouldShowReview {
                    showingWeeklyReview = true
                }
            }
        }
        .sheet(isPresented: $showingWeeklyReview) {
            WeeklyReviewView(viewModel: weeklyReviewVM)
        }
    }
}
