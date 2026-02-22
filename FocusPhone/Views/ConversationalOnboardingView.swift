import SwiftUI
import FamilyControls

struct ConversationalOnboardingView: View {
    @ObservedObject var authVM: AuthViewModel
    @StateObject private var chatVM = OnboardingChatViewModel()
    @State private var currentPage = 0
    @State private var mascotScale: CGFloat = 0.5
    @State private var mascotOpacity: CGFloat = 0
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            RawDog.Colors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Back button
                if currentPage > 0 && currentPage < 4 {
                    HStack {
                        Button {
                            withAnimation { currentPage -= 1 }
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(RawDog.Colors.textPrimary)
                                .padding(10)
                                .background(RawDog.Colors.surfaceElevated, in: Circle())
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }

                TabView(selection: $currentPage) {
                    welcomePage.tag(0)
                    screenTimePage.tag(1)
                    safariPage.tag(2)
                    chatPage.tag(3)
                    profileReviewPage.tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.35), value: currentPage)

                // Progress
                progressIndicator
                    .padding(.bottom, 40)
            }
        }
        .preferredColorScheme(.dark)
        .onChange(of: scenePhase) {
            if scenePhase == .active {
                authVM.checkContentBlockerState()
            }
        }
    }

    // MARK: - Progress

    private var progressIndicator: some View {
        HStack(spacing: 6) {
            ForEach(0..<5, id: \.self) { index in
                Capsule()
                    .fill(index <= currentPage ? RawDog.Colors.accent : RawDog.Colors.surfaceElevated)
                    .frame(width: index == currentPage ? 24 : 8, height: 8)
                    .animation(.spring(response: 0.35), value: currentPage)
            }
        }
    }

    // MARK: - Page 0: Welcome

    private var welcomePage: some View {
        VStack(spacing: 0) {
            Spacer()

            RawDogMascot(state: .neutral, size: 160)
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
        }
    }

    // MARK: - Page 1: Screen Time Permission

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

            if authVM.authorizationStatus == .approved {
                RawDog.PillButton(title: "Continue") {
                    withAnimation { currentPage = 2 }
                }
            } else {
                RawDog.PillButton(title: "Allow Screen Time") {
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

    // MARK: - Page 2: Safari Content Blocker

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
                    withAnimation { currentPage = 3 }
                    chatVM.startConversation()
                }
            }
        }
    }

    // MARK: - Page 3: Chat

    private var chatPage: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(chatVM.messages) { message in
                            chatBubble(message)
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
                    .padding(.vertical, 16)
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

            if chatVM.conversationStage == .chatting {
                // Input bar
                HStack(spacing: 8) {
                    Button {
                        chatVM.toggleVoiceInput()
                    } label: {
                        Image(systemName: chatVM.speechService.isListening ? "mic.fill" : "mic")
                            .font(.title3)
                            .foregroundStyle(chatVM.speechService.isListening ? RawDog.Colors.destructive : RawDog.Colors.accent)
                    }

                    TextField("Type your response...", text: $chatVM.inputText, axis: .vertical)
                        .lineLimit(1...4)
                        .textFieldStyle(.roundedBorder)

                    Button {
                        chatVM.sendMessage()
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundStyle(RawDog.Colors.accent)
                    }
                    .disabled(chatVM.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || chatVM.isLoading)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(RawDog.Colors.surface)
            }

            if chatVM.conversationStage == .profileReady {
                RawDog.PillButton(title: "Review Your Profile") {
                    withAnimation { currentPage = 4 }
                }
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
        .onAppear {
            // Sync voice transcription to input
            chatVM.speechService.$transcribedText
                .receive(on: DispatchQueue.main)
                .assign(to: &chatVM.$inputText)
        }
    }

    // MARK: - Page 4: Profile Review

    private var profileReviewPage: some View {
        Group {
            if let profile = chatVM.generatedProfile {
                ProfileReviewView(
                    profile: profile,
                    onAccept: {
                        chatVM.applyProfile()
                    },
                    onBack: {
                        withAnimation { currentPage = 3 }
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
        HStack {
            if message.role == .user { Spacer() }

            if message.role == .assistant {
                RawDogMascot(state: .neutral, size: 32)
                    .padding(.bottom, 4)
            }

            Text(message.content)
                .font(RawDog.Typography.subheadline)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    message.role == .user
                        ? RawDog.Colors.accent
                        : RawDog.Colors.surfaceElevated
                )
                .foregroundStyle(message.role == .user ? RawDog.Colors.background : RawDog.Colors.textPrimary)
                .clipShape(RoundedRectangle(cornerRadius: RawDog.Radius.card))

            if message.role == .assistant { Spacer() }
        }
        .padding(.horizontal, 16)
    }

    private var typingIndicator: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(RawDog.Colors.textSecondary)
                    .frame(width: 8, height: 8)
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
        .padding(.vertical, 10)
        .background(RawDog.Colors.surfaceElevated, in: RoundedRectangle(cornerRadius: RawDog.Radius.card))
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
