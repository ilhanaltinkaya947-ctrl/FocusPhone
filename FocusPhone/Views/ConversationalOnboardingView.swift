import SwiftUI
import FamilyControls

struct ConversationalOnboardingView: View {
    @ObservedObject var authVM: AuthViewModel
    @StateObject private var chatVM = OnboardingChatViewModel()
    @State private var currentPage = 0
    @State private var mascotScale: CGFloat = 0.5
    @State private var mascotOpacity: CGFloat = 0
    @Environment(\.scenePhase) private var scenePhase

    private let totalPages = 11 // 0-10

    var body: some View {
        ZStack {
            RawDog.Colors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar: back + progress (pages 1-7)
                if currentPage > 0 {
                    topBar
                }

                TabView(selection: $currentPage) {
                    welcomePage.tag(0)
                    dataShockPage.tag(1)
                    screenTimePage.tag(2)
                    safariPage.tag(3)
                    goalPage.tag(4)
                    profileSelectionPage.tag(5)
                    commitmentPage.tag(6)
                    strictnessPage.tag(7)
                    sleepSetupPage.tag(8)
                    chatPage.tag(9)
                    profileReviewPage.tag(10)
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
            if currentPage < 9 {
                Button {
                    withAnimation { currentPage -= 1 }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(RawDog.Colors.textPrimary)
                        .frame(width: 36, height: 36)
                        .background(RawDog.Colors.surfaceElevated, in: Circle())
                }
            }

            // Thin progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(RawDog.Colors.surfaceElevated)
                        .frame(height: 3)

                    Capsule()
                        .fill(RawDog.Colors.accent)
                        .frame(width: geo.size.width * progressFraction, height: 3)
                        .animation(.spring(response: 0.4), value: currentPage)
                }
            }
            .frame(height: 3)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    private var progressFraction: CGFloat {
        CGFloat(currentPage) / CGFloat(totalPages)
    }

    // MARK: - Page 0: Welcome

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

            Text("Block the apps and content that\nwaste your time. Keep the rest.")
                .font(RawDog.Typography.caption)
                .foregroundStyle(RawDog.Colors.textSecondary.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.top, 12)
                .padding(.horizontal, 40)

            Spacer()

            RawDog.PillButton(title: "Get Started") {
                withAnimation { currentPage = 1 }
            }
            .padding(.bottom, 40)
        }
    }

    // MARK: - Page 1: Data Shock

    private var dataShockPage: some View {
        DataShockView(
            onReactionSelected: { reaction in
                chatVM.onboardingAnswers.dataShockReaction = reaction
            },
            onContinue: {
                withAnimation { currentPage = 2 }
            }
        )
    }

    // MARK: - Page 2: Screen Time Permission

    private var screenTimePage: some View {
        VStack(spacing: 0) {
            Spacer()

            stepBadge("1 of 2")

            permissionIcon("hourglass.badge.plus")
                .padding(.top, RawDog.Spacing.md)

            Text("Screen Time Access")
                .font(RawDog.Typography.title2)
                .foregroundStyle(RawDog.Colors.textPrimary)
                .padding(.top, RawDog.Spacing.lg)

            Text("RawDog needs Screen Time access\nto block apps and enforce restrictions.")
                .font(RawDog.Typography.subheadline)
                .foregroundStyle(RawDog.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.top, RawDog.Spacing.sm)
                .padding(.horizontal, 40)

            Spacer().frame(height: RawDog.Spacing.lg)

            if authVM.authorizationStatus == .approved {
                RawDog.StatusBadge(text: "Permission Granted", icon: "checkmark.circle.fill", color: RawDog.Colors.approved)
            } else if authVM.authorizationStatus == .denied {
                RawDog.StatusBadge(text: "Permission Denied", icon: "xmark.circle.fill", color: RawDog.Colors.destructive)
                Text("Please enable Screen Time in Settings.")
                    .font(RawDog.Typography.caption)
                    .foregroundStyle(RawDog.Colors.textSecondary)
                    .padding(.top, RawDog.Spacing.xs)
            }

            Spacer()

            Group {
                if authVM.authorizationStatus == .approved {
                    RawDog.PillButton(title: "Continue") {
                        withAnimation { currentPage = 3 }
                    }
                } else {
                    RawDog.PillButton(title: "Allow Screen Time") {
                        authVM.requestAuthorization()
                    }
                }
            }
            .padding(.bottom, 40)
        }
        .onChange(of: authVM.authorizationStatus) {
            if authVM.authorizationStatus == .approved {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    withAnimation { currentPage = 3 }
                }
            }
        }
    }

    // MARK: - Page 3: Safari Content Blocker

    private var safariPage: some View {
        VStack(spacing: 0) {
            Spacer()

            stepBadge("2 of 2")

            permissionIcon("safari")
                .padding(.top, RawDog.Spacing.md)

            Text("Safari Content Blocker")
                .font(RawDog.Typography.title2)
                .foregroundStyle(RawDog.Colors.textPrimary)
                .padding(.top, RawDog.Spacing.lg)

            Text("Enable the content blocker to block\ndistracting websites in Safari.")
                .font(RawDog.Typography.subheadline)
                .foregroundStyle(RawDog.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.top, RawDog.Spacing.sm)
                .padding(.horizontal, 40)

            Spacer().frame(height: RawDog.Spacing.lg)

            if authVM.contentBlockerEnabled {
                RawDog.StatusBadge(text: "Content Blocker Enabled", icon: "checkmark.circle.fill", color: RawDog.Colors.approved)
            } else {
                VStack(spacing: 4) {
                    Text("Settings > Safari > Extensions")
                        .font(RawDog.Typography.caption.weight(.medium))
                        .foregroundStyle(RawDog.Colors.textPrimary)
                    Text("Enable FocusPhone")
                        .font(RawDog.Typography.caption)
                        .foregroundStyle(RawDog.Colors.textSecondary)
                }
                .padding(12)
                .background(RawDog.Colors.surfaceElevated, in: RoundedRectangle(cornerRadius: 10))
            }

            Spacer()

            VStack(spacing: 12) {
                if !authVM.contentBlockerEnabled {
                    RawDog.PillButton(title: "Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                }
                RawDog.PillButton(
                    title: authVM.contentBlockerEnabled ? "Continue" : "Skip for Now",
                    style: authVM.contentBlockerEnabled ? .primary : .secondary
                ) {
                    withAnimation { currentPage = 4 }
                }
            }
            .padding(.bottom, 40)
        }
    }

    // MARK: - Page 4: Goal Selection

    private var goalPage: some View {
        GoalSelectionView(
            onGoalSelected: { goalID in
                chatVM.onboardingAnswers.selectedGoalID = goalID
            },
            onContinue: {
                withAnimation { currentPage = 5 }
            }
        )
    }

    // MARK: - Page 5: Profile Selection

    private var profileSelectionPage: some View {
        ProfileSelectionView(
            onProfilesSelected: { profileIDs in
                chatVM.onboardingAnswers.selectedProfileIDs = profileIDs
            },
            onContinue: {
                withAnimation { currentPage = 6 }
            }
        )
    }

    // MARK: - Page 6: Commitment

    private var commitmentPage: some View {
        CommitmentPickerView(
            onCommitmentSet: { days in
                chatVM.onboardingAnswers.commitmentDays = days
            },
            onContinue: {
                withAnimation { currentPage = 7 }
            }
        )
    }

    // MARK: - Page 7: Strictness

    private var strictnessPage: some View {
        StrictnessPickerView(
            onStrictnessSelected: { level in
                chatVM.onboardingAnswers.strictnessLevel = level
            },
            onContinue: {
                withAnimation { currentPage = 8 }
            }
        )
    }

    // MARK: - Page 8: Sleep Setup

    private var sleepSetupPage: some View {
        SleepSetupView(
            onSleepSet: { wake, bed in
                chatVM.onboardingAnswers.wakeTime = wake
                chatVM.onboardingAnswers.bedTime = bed
            },
            onContinue: {
                chatVM.startConversation()
                withAnimation { currentPage = 9 }
            }
        )
    }

    // MARK: - Page 7: Chat

    private var chatPage: some View {
        ZStack {
            VStack(spacing: 0) {
                // Chat header with animated mascot
                HStack(spacing: 10) {
                    AnimatedMascot(state: chatVM.mascotState, size: 28)
                    Text("RawDog")
                        .font(RawDog.Typography.headline)
                        .foregroundStyle(RawDog.Colors.textPrimary)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)

                Divider()
                    .overlay(RawDog.Colors.surfaceElevated)

                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 6) {
                            ForEach(chatVM.messages) { message in
                                VStack(alignment: .leading, spacing: 8) {
                                    chatBubble(message)
                                        .transition(
                                            .asymmetric(
                                                insertion: .opacity
                                                    .combined(with: .move(edge: .bottom))
                                                    .combined(with: .scale(scale: 0.95)),
                                                removal: .opacity
                                            )
                                        )

                                    // Chips below assistant message
                                    if message.role == .assistant,
                                       let chips = message.suggestionChips,
                                       message.id == chatVM.messages.last(where: { $0.role == .assistant })?.id {
                                        SuggestionChipsView(chips: chips) { chip in
                                            chatVM.inputText = chip
                                            chatVM.sendMessage()
                                        }
                                    }
                                }
                                .id(message.id)
                            }

                            if chatVM.isLoading {
                                HStack {
                                    typingIndicator
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .id("loading")
                            }
                        }
                        .padding(.vertical, 12)
                    }
                    .onChange(of: chatVM.messages.count) {
                        withAnimation {
                            if let lastID = chatVM.messages.last?.id {
                                proxy.scrollTo(lastID, anchor: .bottom)
                            } else {
                                proxy.scrollTo("loading", anchor: .bottom)
                            }
                        }
                    }
                }

                // Input / Actions
                if chatVM.conversationStage == .chatting {
                    chatInputBar
                }

                if chatVM.conversationStage == .profileReady {
                    RawDog.PillButton(title: "Review Your Profile") {
                        withAnimation { currentPage = 10 }
                    }
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                }

                if let error = chatVM.errorMessage {
                    Text(error)
                        .font(RawDog.Typography.caption)
                        .foregroundStyle(RawDog.Colors.destructive)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 4)
                }
            }

            // Voice overlay
            if chatVM.isVoiceMode {
                VoiceChatOverlay(
                    speechService: chatVM.speechService,
                    onSend: { text in
                        chatVM.sendVoiceMessage(text)
                    },
                    onCancel: {
                        chatVM.exitVoiceMode()
                    }
                )
                .transition(.opacity)
            }
        }
        .onChange(of: chatVM.inputText) {
            if !chatVM.inputText.isEmpty && !chatVM.isVoiceMode {
                chatVM.mascotState = .listening
            }
        }
    }

    // MARK: - Chat Input Bar

    private var chatInputBar: some View {
        HStack(spacing: 10) {
            // Mic button — opens full voice overlay
            Button {
                chatVM.enterVoiceMode()
            } label: {
                Image(systemName: "mic")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(RawDog.Colors.textSecondary)
                    .frame(width: 36, height: 36)
            }

            // Text field
            TextField("Type your response...", text: $chatVM.inputText, axis: .vertical)
                .lineLimit(1...4)
                .font(RawDog.Typography.subheadline)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(RawDog.Colors.surfaceElevated, in: RoundedRectangle(cornerRadius: 20))
                .foregroundStyle(RawDog.Colors.textPrimary)

            // Send button
            Button {
                chatVM.sendMessage()
            } label: {
                Image(systemName: "arrow.up")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(RawDog.Colors.background)
                    .frame(width: 32, height: 32)
                    .background(
                        canSend ? RawDog.Colors.accent : RawDog.Colors.surfaceElevated,
                        in: Circle()
                    )
            }
            .disabled(!canSend)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(RawDog.Colors.surface)
    }

    private var canSend: Bool {
        !chatVM.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !chatVM.isLoading
    }

    // MARK: - Page 8: Profile Review

    private var profileReviewPage: some View {
        Group {
            if let profile = chatVM.generatedProfile {
                ProfileReviewView(
                    profile: profile,
                    onAccept: {
                        chatVM.applyProfile()
                    },
                    onBack: {
                        withAnimation { currentPage = 9 }
                    }
                )
            } else {
                VStack {
                    ProgressView()
                        .tint(RawDog.Colors.accent)
                    Text("Generating profile...")
                        .font(RawDog.Typography.subheadline)
                        .foregroundStyle(RawDog.Colors.textSecondary)
                }
            }
        }
    }

    // MARK: - Chat Bubble

    private func chatBubble(_ message: ChatMessage) -> some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.role == .user { Spacer(minLength: 60) }

            if message.role == .assistant {
                AnimatedMascot(state: chatVM.mascotState, size: 26)
                    .padding(.bottom, 2)
            }

            Text(message.content)
                .font(RawDog.Typography.subheadline)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .foregroundStyle(
                    message.role == .user ? RawDog.Colors.background : RawDog.Colors.textPrimary
                )
                .background(
                    message.role == .user
                        ? RawDog.Colors.accent
                        : Color(hex: "1A1A1A")
                )
                .clipShape(
                    RoundedRectangle(cornerRadius: 18)
                )

            if message.role == .assistant { Spacer(minLength: 60) }
        }
        .padding(.horizontal, 12)
    }

    private var typingIndicator: some View {
        HStack(spacing: 5) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(RawDog.Colors.textSecondary.opacity(0.6))
                    .frame(width: 7, height: 7)
                    .scaleEffect(1.0)
                    .animation(
                        .easeInOut(duration: 0.6)
                        .repeatForever()
                        .delay(Double(index) * 0.2),
                        value: chatVM.isLoading
                    )
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color(hex: "1A1A1A"), in: RoundedRectangle(cornerRadius: 18))
    }

    // MARK: - Reusable Components

    private func permissionIcon(_ systemName: String) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 56, weight: .light))
            .foregroundStyle(RawDog.Colors.accent)
            .frame(width: 100, height: 100)
            .background(RawDog.Colors.accent.opacity(0.1), in: Circle())
    }

    private func stepBadge(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.caption2.bold())
            .foregroundStyle(RawDog.Colors.accent)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(RawDog.Colors.accent.opacity(0.12), in: Capsule())
    }
}
