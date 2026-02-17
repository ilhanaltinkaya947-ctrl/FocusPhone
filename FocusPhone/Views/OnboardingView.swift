import SwiftUI
import FamilyControls

struct OnboardingView: View {
    @ObservedObject var blockingVM: AppBlockingViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                Text("FocusPhone")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Take back control of your screen time.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Spacer()

                if blockingVM.authorizationStatus == .notDetermined {
                    Button {
                        blockingVM.requestAuthorization()
                    } label: {
                        Text("Get Started")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal, 32)
                } else if blockingVM.authorizationStatus == .approved {
                    Button {
                        AppState.shared.isOnboardingCompleted = true
                        blockingVM.objectWillChange.send()
                    } label: {
                        Text("Continue")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal, 32)
                } else {
                    Text("Screen Time permission is required.")
                        .foregroundStyle(.red)
                }

                Spacer()
            }
            .navigationBarHidden(true)
        }
    }
}
