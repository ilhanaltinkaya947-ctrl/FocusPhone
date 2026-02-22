import SwiftUI
import FamilyControls

struct ConversationalOnboardingView: View {
    @ObservedObject var authVM: AuthViewModel
    @StateObject private var chatVM = OnboardingChatViewModel()
    @State private var currentPage = 0
    @State private var iconScale: CGFloat = 0.5
    @State private var iconOpacity: CGFloat = 0
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        VStack(spacing: 0) {
            // Back button
            if currentPage > 0 && currentPage < 4 {
                HStack {
                    Button {
                        withAnimation { currentPage -= 1 }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.primary)
                            .padding(10)
                            .background(Color(.systemGray5), in: Circle())
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
                    .fill(index <= currentPage ? Color.blue : Color(.systemGray4))
                    .frame(width: index == currentPage ? 24 : 8, height: 8)
                    .animation(.spring(response: 0.35), value: currentPage)
            }
        }
    }

    // MARK: - Page 0: Welcome

    private var welcomePage: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.08))
                    .frame(width: 180, height: 180)
                Circle()
                    .fill(Color.blue.opacity(0.05))
                    .frame(width: 240, height: 240)
                Image(systemName: "lock.iphone")
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

            Text("Make your phone dumb\nin exactly the right ways")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 4)

            Text("Block the apps and content that\nwaste your time. Keep the rest.")
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

    // MARK: - Page 1: Screen Time Permission

    private var screenTimePage: some View {
        VStack(spacing: 0) {
            Spacer()

            stepBadge("1 of 2", color: .orange)

            permissionIcon("hourglass.badge.plus", color: .orange)
                .padding(.top, 16)

            Text("Screen Time Access")
                .font(.title2.bold())
                .padding(.top, 24)

            Text("FocusPhone needs Screen Time access\nto block apps and enforce restrictions.")
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

    // MARK: - Page 2: Safari Content Blocker

    private var safariPage: some View {
        VStack(spacing: 0) {
            Spacer()

            stepBadge("2 of 2", color: .blue)

            permissionIcon("safari", color: .blue)
                .padding(.top, 16)

            Text("Safari Content Blocker")
                .font(.title2.bold())
                .padding(.top, 24)

            Text("Enable the content blocker to block\ndistracting websites in Safari.")
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
                        .font(.caption.weight(.medium))
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
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                }
                onboardingButton(
                    authVM.contentBlockerEnabled ? "Continue" : "Skip for Now",
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
                            .foregroundStyle(chatVM.speechService.isListening ? .red : .blue)
                    }

                    TextField("Type your response...", text: $chatVM.inputText, axis: .vertical)
                        .lineLimit(1...4)
                        .textFieldStyle(.roundedBorder)

                    Button {
                        chatVM.sendMessage()
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.blue)
                    }
                    .disabled(chatVM.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || chatVM.isLoading)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
            }

            if chatVM.conversationStage == .profileReady {
                onboardingButton("Review Your Profile") {
                    withAnimation { currentPage = 4 }
                }
                .padding(.vertical, 12)
            }

            if let error = chatVM.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
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
                    Text("Generating profile...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Chat Bubble

    private func chatBubble(_ message: ChatMessage) -> some View {
        HStack {
            if message.role == .user { Spacer() }

            Text(message.content)
                .font(.subheadline)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    message.role == .user
                        ? Color.blue
                        : Color(.systemGray5)
                )
                .foregroundStyle(message.role == .user ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 16))

            if message.role == .assistant { Spacer() }
        }
        .padding(.horizontal, 16)
    }

    private var typingIndicator: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color(.systemGray3))
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
        .background(Color(.systemGray5), in: RoundedRectangle(cornerRadius: 16))
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
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            action()
        } label: {
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
}
