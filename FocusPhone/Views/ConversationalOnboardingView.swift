import SwiftUI
import FamilyControls

struct ConversationalOnboardingView: View {
    @ObservedObject var authVM: AuthViewModel
    @State private var currentPage = 0
    @State private var selections = OnboardingSelections()
    @State private var mascotScale: CGFloat = 0.5
    @State private var mascotOpacity: CGFloat = 0
    @Environment(\.scenePhase) private var scenePhase

    private let totalPages = 12 // 0-11

    var body: some View {
        ZStack {
            RawDog.Colors.background.ignoresSafeArea()

            // Particle background
            ParticleBackgroundView()

            VStack(spacing: 0) {
                // Progress bar (screens 1-10)
                if currentPage > 0 && currentPage < 11 {
                    topBar
                }

                TabView(selection: $currentPage) {
                    welcomePage.tag(0)           // Screen 1: Welcome
                    shockPage.tag(1)             // Screen 2: Shock moment
                    whatRawDogDoesPage.tag(2)    // Screen 3: What RawDog does
                    agePage.tag(3)               // Screen 4: Age selection
                    occupationPage.tag(4)        // Screen 5: Occupation
                    problemsPage.tag(5)          // Screen 6: Problems (multi-select)
                    goalsPage.tag(6)             // Screen 7: Goals (multi-select)
                    loadingPage.tag(7)           // Screen 8: Cinematic loading
                    goalsRevealPage.tag(8)       // Screen 9: Goals reveal
                    firstWinPage.tag(9)          // Screen 10: First win
                    permissionsPage.tag(10)      // Screen 11: Permissions
                    applyPage.tag(11)            // Screen 12: Apply
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.35), value: currentPage)
            }
        }
        .withResponsiveMetrics()
        .toolbar(.hidden, for: .tabBar)
        .preferredColorScheme(.dark)
        .onChange(of: scenePhase) {
            if scenePhase == .active {
                authVM.checkContentBlockerState()
            }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack(spacing: 12) {
            RawDog.OnboardingBackButton {
                withAnimation { currentPage -= 1 }
            }

            RawDog.ThinProgressBar(progress: progressFraction)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    private var progressFraction: CGFloat {
        CGFloat(currentPage) / CGFloat(totalPages - 1)
    }

    // MARK: - Screen 1: Welcome

    private var welcomePage: some View {
        VStack(spacing: 0) {
            Spacer()

            AnimatedMascot(state: .neutral, size: 160)
                .scaleEffect(mascotScale)
                .opacity(mascotOpacity)
                .onAppear {
                    withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                        mascotScale = 1.0
                        mascotOpacity = 1.0
                    }
                }

            Spacer().frame(height: RawDog.Spacing.xl)

            Text("RawDog")
                .font(RawDog.Typography.largeTitle)
                .foregroundStyle(RawDog.Colors.textPrimary)

            Text("Your phone. Disciplined.")
                .font(.title3)
                .foregroundStyle(RawDog.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.top, RawDog.Spacing.xs)

            Spacer()

            RawDog.OnboardingButton(title: "Get Started") {
                withAnimation { currentPage = 1 }
            }
            .padding(.bottom, 40)
        }
    }

    // MARK: - Screen 2: Shock Moment

    private var shockPage: some View {
        DataShockView(
            yearsToLose: selections.yearsPhoneWillSteal(),
            onContinue: {
                withAnimation { currentPage = 2 }
            }
        )
    }

    // MARK: - Screen 3: What RawDog Does

    private var whatRawDogDoesPage: some View {
        WhatRawDogDoesView {
            withAnimation { currentPage = 3 }
        }
    }

    // MARK: - Screen 4: Age

    private var agePage: some View {
        AgeSelectionView(selectedAge: $selections.age) {
            withAnimation { currentPage = 4 }
        }
    }

    // MARK: - Screen 5: Occupation

    private var occupationPage: some View {
        OccupationView(selectedOccupation: $selections.occupation) {
            withAnimation { currentPage = 5 }
        }
    }

    // MARK: - Screen 6: Problems

    private var problemsPage: some View {
        ProblemSelectionView(selectedProblems: $selections.problems) {
            withAnimation { currentPage = 6 }
        }
    }

    // MARK: - Screen 7: Goals

    private var goalsPage: some View {
        GoalSelectionView(selectedGoals: $selections.goals) {
            withAnimation { currentPage = 7 }
        }
    }

    // MARK: - Screen 8: Cinematic Loading

    private var loadingPage: some View {
        CinematicLoadingView {
            withAnimation { currentPage = 8 }
        }
    }

    // MARK: - Screen 9: Goals Reveal

    private var goalsRevealPage: some View {
        GoalsRevealView(selections: selections) {
            withAnimation { currentPage = 9 }
        }
    }

    // MARK: - Screen 10: First Win

    private var firstWinPage: some View {
        FirstWinView(
            selections: selections,
            firstCommitment: $selections.firstCommitment
        ) {
            withAnimation { currentPage = 10 }
        }
    }

    // MARK: - Screen 11: Permissions

    private var permissionsPage: some View {
        VStack(spacing: 0) {
            Spacer()

            Text("One More Thing")
                .font(RawDog.Typography.title)
                .foregroundStyle(RawDog.Colors.textPrimary)

            Text("RawDog needs a few permissions")
                .font(RawDog.Typography.subheadline)
                .foregroundStyle(RawDog.Colors.textSecondary)
                .padding(.top, 4)

            VStack(spacing: 12) {
                // Notifications
                permissionRow(
                    icon: "bell.fill",
                    title: "Notifications",
                    subtitle: "Daily accountability check-ins",
                    isGranted: true // We'll request on tap
                ) {
                    Task {
                        try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
                    }
                }

                // Screen Time
                permissionRow(
                    icon: "hourglass.badge.plus",
                    title: "Screen Time",
                    subtitle: "Block apps & enforce restrictions",
                    isGranted: authVM.authorizationStatus == .approved
                ) {
                    authVM.requestAuthorization()
                }

                // Safari Extension
                permissionRow(
                    icon: "safari",
                    title: "Safari Extension",
                    subtitle: "Block distracting websites",
                    isGranted: authVM.contentBlockerEnabled
                ) {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            }
            .padding(.horizontal, 32)
            .padding(.top, 32)

            Spacer()

            RawDog.OnboardingButton(
                title: "Continue",
                isEnabled: authVM.authorizationStatus == .approved
            ) {
                withAnimation { currentPage = 11 }
            }
            .padding(.bottom, 40)
        }
    }

    private func permissionRow(
        icon: String,
        title: String,
        subtitle: String,
        isGranted: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundStyle(RawDog.Colors.accentIce)
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(RawDog.Typography.headline)
                        .foregroundStyle(RawDog.Colors.textPrimary)
                    Text(subtitle)
                        .font(RawDog.Typography.caption)
                        .foregroundStyle(RawDog.Colors.textSecondary)
                }

                Spacer()

                if isGranted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(RawDog.Colors.approved)
                } else {
                    Text("Enable")
                        .font(RawDog.Typography.caption.weight(.semibold))
                        .foregroundStyle(RawDog.Colors.accentIce)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(RawDog.Colors.accentIce.opacity(0.15), in: Capsule())
                }
            }
            .padding(14)
            .background(RawDog.Colors.cardBackground, in: RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(RawDog.Colors.borderSubtle, lineWidth: 1)
            )
        }
    }

    // MARK: - Screen 12: Apply

    private var applyPage: some View {
        let profile = selections.toProfile()

        return VStack(spacing: 0) {
            Spacer()

            AnimatedMascot(state: .proud, size: 120)

            Text("Ready to Go")
                .font(RawDog.Typography.title)
                .foregroundStyle(RawDog.Colors.textPrimary)
                .padding(.top, RawDog.Spacing.lg)

            // Summary
            VStack(alignment: .leading, spacing: 10) {
                if !selections.problems.isEmpty {
                    summaryRow(icon: "lock.fill", text: "Blocking: \(selections.problems.count) categories")
                }
                if !profile.activePresetIDs.isEmpty {
                    summaryRow(icon: "shield.fill", text: "\(profile.activePresetIDs.count) restriction presets active")
                }
                if !profile.blockedWebsites.isEmpty {
                    summaryRow(icon: "globe", text: "\(profile.blockedWebsites.count) websites blocked")
                }
                if let commitment = selections.firstCommitment {
                    summaryRow(icon: "checkmark.circle.fill", text: "First commitment: \(commitment.title)")
                }
                summaryRow(icon: "clock.fill", text: "\(profile.dailyExtensionCapMinutes)m daily extension cap")
            }
            .padding(20)
            .background(RawDog.Colors.cardBackground, in: RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(RawDog.Colors.borderSubtle, lineWidth: 1)
            )
            .padding(.horizontal, 32)
            .padding(.top, RawDog.Spacing.lg)

            Spacer()

            RawDog.OnboardingButton(title: "Apply Restrictions") {
                applyAndFinish()
            }
            .padding(.bottom, 40)
        }
    }

    private func summaryRow(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(RawDog.Colors.accentIce)
                .frame(width: 20)
            Text(text)
                .font(RawDog.Typography.subheadline)
                .foregroundStyle(RawDog.Colors.textPrimary)
        }
    }

    // MARK: - Apply

    private func applyAndFinish() {
        let profile = selections.toProfile()

        // Activate restriction profile
        RestrictionEngine.activateProfile(profile)

        // Save first commitment if selected
        if let commitment = selections.firstCommitment {
            CommitmentStore.addCommitment(commitment)
            CommitmentNotificationService.scheduleNotifications(for: commitment)
        }

        // Save user memory
        var memory = UserMemoryStore.shared.memory
        if let occupation = selections.occupation {
            memory.occupation = occupation
        }
        memory.goals = selections.goals
        memory.memberSinceDate = Date()
        UserMemoryStore.shared.memory = memory

        // Mark onboarding complete
        AppState.shared.isOnboardingCompleted = true
    }
}
