import SwiftUI

struct ContentView: View {
    @StateObject private var blockingVM = AppBlockingViewModel()

    var body: some View {
        Group {
            if AppState.shared.isOnboardingCompleted {
                DashboardView(blockingVM: blockingVM)
            } else {
                OnboardingView(blockingVM: blockingVM)
            }
        }
    }
}
