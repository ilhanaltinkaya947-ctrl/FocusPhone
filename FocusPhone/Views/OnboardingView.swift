import SwiftUI
import FamilyControls

struct OnboardingView: View {
    @ObservedObject var authVM: AuthViewModel
    @State private var currentPage = 0
    @State private var iconScale: CGFloat = 0.5
    @State private var iconOpacity: CGFloat = 0
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
            .animation(.easeInOut(duration: 0.35), value: currentPage)

            // Progress bar
            progressIndicator
                .padding(.bottom, 40)
        }
        .onChange(of: scenePhase) {
            if scenePhase == .active {
                authVM.checkContentBlockerState()
            }
        }
    }

    // MARK: - Progress Indicator

    private var progressIndicator: some View {
        HStack(spacing: 6) {
            ForEach(0..<4, id: \.self) { index in
                Capsule()
                    .fill(index <= currentPage ? Color.blue : Color(.systemGray4))
                    .frame(width: index == currentPage ? 24 : 8, height: 8)
                    .animation(.spring(response: 0.35), value: currentPage)
            }
        }
    }

    // MARK: - Page 1: Welcome

    private var welcomePage: some View {
        VStack(spacing: 0) {
            Spacer()

            // Animated icon cluster
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.08))
                    .frame(width: 180, height: 180)
                Circle()
                    .fill(Color.blue.opacity(0.05))
                    .frame(width: 240, height: 240)
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 72, weight: .light))
                    .foregroundStyle(.blue)
                    .scaleEffect(iconScale)
                    .opacity(iconOpacity)
            }
            .onAppear {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                    iconScale = 1.0
                    iconOpacity = 1.0
                }
            }

            Spacer().frame(height: 40)

            Text("FocusPhone")
                .font(.system(size: 34, weight: .bold, design: .rounded))

            Text("The calendar that\ncontrols your phone")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 4)

            Text("Schedule modes throughout your day.\nEach mode controls which apps\nand websites are available.")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.top, 12)
                .padding(.horizontal, 40)

            Spacer()

            onboardingButton("Get Started") {
                withAnimation { currentPage = 1 }
            }
        }
    }

    // MARK: - Page 2: Screen Time Permission

    private var screenTimePage: some View {
        VStack(spacing: 0) {
            Spacer()

            stepBadge("1 of 2", color: .orange)

            permissionIcon("hourglass.badge.plus", color: .orange)
                .padding(.top, 16)

            Text("Screen Time Access")
                .font(.title2.bold())
                .padding(.top, 24)

            Text("FocusPhone needs Screen Time access\nto block apps and set restrictions\nduring your scheduled modes.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 8)
                .padding(.horizontal, 40)

            Spacer().frame(height: 24)

            if authVM.authorizationStatus == .approved {
                statusBadge(text: "Permission Granted", icon: "checkmark.circle.fill", color: .green)
            } else if authVM.authorizationStatus == .denied {
                statusBadge(text: "Permission Denied", icon: "xmark.circle.fill", color: .red)
                Text("Please enable Screen Time in Settings.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }

            Spacer()

            if authVM.authorizationStatus == .approved {
                onboardingButton("Continue") {
                    withAnimation { currentPage = 2 }
                }
            } else {
                onboardingButton("Allow Screen Time", color: .orange) {
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
        VStack(spacing: 0) {
            Spacer()

            stepBadge("2 of 2", color: .blue)

            permissionIcon("safari", color: .blue)
                .padding(.top, 16)

            Text("Safari Content Blocker")
                .font(.title2.bold())
                .padding(.top, 24)

            Text("Enable the content blocker to block\ndistracting websites during focus modes.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 8)
                .padding(.horizontal, 40)

            Spacer().frame(height: 24)

            if authVM.contentBlockerEnabled {
                statusBadge(text: "Content Blocker Enabled", icon: "checkmark.circle.fill", color: .green)
            } else {
                VStack(spacing: 4) {
                    Text("Settings > Safari > Extensions")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    Text("Enable FocusPhone")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(12)
                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 10))
            }

            Spacer()

            VStack(spacing: 12) {
                if !authVM.contentBlockerEnabled {
                    onboardingButton("Open Settings") {
                        openSafariSettings()
                    }
                }
                onboardingButton(
                    authVM.contentBlockerEnabled ? "Continue" : "Skip for Now",
                    style: authVM.contentBlockerEnabled ? .primary : .secondary
                ) {
                    withAnimation { currentPage = 3 }
                }
            }
        }
    }

    // MARK: - Page 4: All Set

    private var allSetPage: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.08))
                    .frame(width: 180, height: 180)
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 72, weight: .light))
                    .foregroundStyle(.green)
            }

            Text("You're All Set!")
                .font(.title2.bold())
                .padding(.top, 24)

            Text("Your default modes are ready.\nStart by adding time blocks\nto your calendar.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 8)
                .padding(.horizontal, 40)

            Spacer()

            onboardingButton("Start Using FocusPhone", color: .green) {
                AppState.shared.isOnboardingCompleted = true
                authVM.objectWillChange.send()
            }
        }
    }

    // MARK: - Reusable Components

    private func permissionIcon(_ systemName: String, color: Color) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 56, weight: .light))
            .foregroundStyle(color)
            .frame(width: 100, height: 100)
            .background(color.opacity(0.1), in: Circle())
    }

    private func stepBadge(_ text: String, color: Color) -> some View {
        Text(text.uppercased())
            .font(.caption2.bold())
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.12), in: Capsule())
    }

    private func statusBadge(text: String, icon: String, color: Color) -> some View {
        Label(text, systemImage: icon)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(color)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(color.opacity(0.1), in: Capsule())
    }

    private enum ButtonStyle {
        case primary, secondary
    }

    private func onboardingButton(_ title: String, style: ButtonStyle = .primary, color: Color = .blue, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(style == .primary ? color : Color.clear)
                .foregroundStyle(style == .primary ? .white : color)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(style == .secondary ? color : Color.clear, lineWidth: 2)
                )
        }
        .padding(.horizontal, 32)
    }

    private func openSafariSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}
