import SwiftUI

struct ContentView: View {
    @StateObject private var authVM = AuthViewModel()

    var body: some View {
        Group {
            if AppState.shared.isOnboardingCompleted {
                MainTabView()
            } else {
                OnboardingView(authVM: authVM)
            }
        }
        .onAppear {
            AppState.shared.seedDefaultsIfNeeded()
        }
    }
}
