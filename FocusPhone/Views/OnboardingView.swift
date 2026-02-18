import SwiftUI
import FamilyControls

struct OnboardingView: View {
    @ObservedObject var authVM: AuthViewModel
    @State private var currentPage = 0
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                welcomePage.tag(0)
                screenTimePage.tag(1)
                safariPage.tag(2)
                allSetPage.tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentPage)

            // Page indicator dots
            HStack(spacing: 8) {
                ForEach(0..<4, id: \.self) { index in
                    Circle()
                        .fill(index == currentPage ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.bottom, 32)
        }
        .onChange(of: scenePhase) {
            if scenePhase == .active {
                authVM.checkContentBlockerState()
            }
        }
    }

    // MARK: - Page 1: Welcome

    private var welcomePage: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 72))
                .foregroundStyle(.blue)

            Text("FocusPhone")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("The calendar that controls your phone")
                .font(.title3)
                .foregroundStyle(.secondary)

            Text("Schedule modes throughout your day. Each mode controls which apps and websites are available.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()

            onboardingButton("Get Started") {
                withAnimation { currentPage = 1 }
            }
        }
    }

    // MARK: - Page 2: Screen Time Permission

    private var screenTimePage: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "hourglass.badge.plus")
                .font(.system(size: 72))
                .foregroundStyle(.orange)

            Text("Screen Time Access")
                .font(.title)
                .fontWeight(.bold)

            Text("FocusPhone needs Screen Time access to block apps and set restrictions during your scheduled modes.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            if authVM.authorizationStatus == .approved {
                Label("Permission Granted", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.headline)
            } else if authVM.authorizationStatus == .denied {
                Text("Permission denied. Please enable Screen Time in Settings.")
                    .foregroundStyle(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Spacer()

            if authVM.authorizationStatus == .approved {
                onboardingButton("Continue") {
                    withAnimation { currentPage = 2 }
                }
            } else {
                onboardingButton("Allow Screen Time") {
                    authVM.requestAuthorization()
                }
            }
        }
        .onChange(of: authVM.authorizationStatus) {
            if authVM.authorizationStatus == .approved {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    withAnimation { currentPage = 2 }
                }
            }
        }
    }

    // MARK: - Page 3: Safari Content Blocker

    private var safariPage: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "safari")
                .font(.system(size: 72))
                .foregroundStyle(.blue)

            Text("Safari Content Blocker")
                .font(.title)
                .fontWeight(.bold)

            Text("Enable the content blocker to block distracting websites during focus modes.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            if authVM.contentBlockerEnabled {
                Label("Content Blocker Enabled", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.headline)
            } else {
                VStack(spacing: 8) {
                    Text("Go to Settings > Safari > Extensions")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("and enable FocusPhone")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(spacing: 12) {
                if !authVM.contentBlockerEnabled {
                    onboardingButton("Open Settings") {
                        openSafariSettings()
                    }
                }

                onboardingButton(authVM.contentBlockerEnabled ? "Continue" : "Skip for Now",
                                 style: authVM.contentBlockerEnabled ? .primary : .secondary) {
                    withAnimation { currentPage = 3 }
                }
            }
        }
    }

    // MARK: - Page 4: All Set

    private var allSetPage: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 72))
                .foregroundStyle(.green)

            Text("You're All Set!")
                .font(.title)
                .fontWeight(.bold)

            Text("Your default modes are ready. Start by adding time blocks to your calendar.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()

            onboardingButton("Start Using FocusPhone") {
                AppState.shared.isOnboardingCompleted = true
                authVM.objectWillChange.send()
            }
        }
    }

    // MARK: - Helpers

    private enum ButtonStyle {
        case primary, secondary
    }

    private func onboardingButton(_ title: String, style: ButtonStyle = .primary, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(style == .primary ? Color.blue : Color.clear)
                .foregroundStyle(style == .primary ? .white : .blue)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(style == .secondary ? Color.blue : Color.clear, lineWidth: 2)
                )
        }
        .padding(.horizontal, 32)
    }

    private func openSafariSettings() {
        // Open the app's settings page — user navigates to Safari > Extensions from there
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}
