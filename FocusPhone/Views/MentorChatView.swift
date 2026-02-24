import SwiftUI

// MARK: - Mentor Chat Message

struct MentorMessage: Codable, Identifiable {
    let id: UUID
    let role: MentorRole
    let content: String
    let timestamp: Date

    init(role: MentorRole, content: String) {
        self.id = UUID()
        self.role = role
        self.content = content
        self.timestamp = Date()
    }
}

enum MentorRole: String, Codable {
    case user
    case rawdog
}

// MARK: - Mentor Chat ViewModel

@MainActor
class MentorChatViewModel: ObservableObject {
    @Published var messages: [MentorMessage] = []
    @Published var inputText = ""
    @Published var isLoading = false
    @Published var preWarmedGreeting: String?

    private static let messagesKey = "mentorChatMessages"
    private static let greetingKey = "mentorPreWarmedGreeting"
    private let maxMessages = 50

    init() {
        loadMessages()
    }

    // MARK: - Persistence

    private func loadMessages() {
        if let loaded: [MentorMessage] = AppState.shared.load(forKey: Self.messagesKey) {
            messages = loaded.suffix(maxMessages)
        }
    }

    private func saveMessages() {
        let toSave = Array(messages.suffix(maxMessages))
        AppState.shared.save(toSave, forKey: Self.messagesKey)
    }

    // MARK: - Pre-warm (call on app open)

    func preWarm() {
        preWarmedGreeting = Constants.sharedDefaults.string(forKey: Self.greetingKey)

        Task {
            do {
                let memory = UserMemoryStore.shared.memory
                let done = RetentionService.shared.todayCompletedCount()
                let total = RetentionService.shared.todayScheduledCount()
                let topStreak = memory.currentStreaks.max(by: { $0.value < $1.value })

                var context = "Today: \(done)/\(total) done."
                if let s = topStreak {
                    context += " Top streak: \(s.key) at \(s.value) days."
                }

                let system = mentorSystemPrompt(memory: memory)
                let prompt = "Generate a brief greeting for when the user opens the chat. Reference today's data: \(context). One sentence, casual."

                let greeting = try await GroqService.shared.callRetention(system: system, user: prompt, maxTokens: 60)
                preWarmedGreeting = greeting
                Constants.sharedDefaults.set(greeting, forKey: Self.greetingKey)
            } catch {
                if preWarmedGreeting == nil {
                    preWarmedGreeting = "What's on your mind?"
                }
            }
        }
    }

    // MARK: - Send Message

    func send() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isLoading else { return }

        let userMessage = MentorMessage(role: .user, content: text)
        messages.append(userMessage)
        inputText = ""
        isLoading = true
        saveMessages()

        Task {
            do {
                let memory = UserMemoryStore.shared.memory
                let system = mentorSystemPrompt(memory: memory)

                let recentMessages = messages.suffix(6)
                var conversationContext = recentMessages.map { msg in
                    "\(msg.role == .user ? "User" : "RawDog"): \(msg.content)"
                }.joined(separator: "\n")

                let done = RetentionService.shared.todayCompletedCount()
                let total = RetentionService.shared.todayScheduledCount()
                conversationContext += "\n\n[Today: \(done)/\(total) commitments done]"

                let response = try await GroqService.shared.callRetention(
                    system: system,
                    user: conversationContext,
                    maxTokens: 150
                )

                let rawdogMessage = MentorMessage(role: .rawdog, content: response)
                messages.append(rawdogMessage)
                isLoading = false
                saveMessages()
            } catch {
                let errorMessage = MentorMessage(
                    role: .rawdog,
                    content: "Can't connect right now. Try again in a sec."
                )
                messages.append(errorMessage)
                isLoading = false
                saveMessages()
            }
        }
    }

    func sendQuickPrompt(_ prompt: String) {
        inputText = prompt
        send()
    }

    // MARK: - System Prompt

    private func mentorSystemPrompt(memory: UserMemory) -> String {
        let calendar = Calendar.current
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let recentLogs = CommitmentStore.logs.filter { $0.date >= thirtyDaysAgo }
        let verified = recentLogs.filter { $0.status == .verified }.count
        let failed = recentLogs.filter { $0.status == .failed }.count

        let streakSummary = StreakService.shared.records.map {
            "\($0.commitmentTitle): \($0.currentStreak)d streak (best: \($0.bestStreak)d)"
        }.joined(separator: ", ")

        return """
        You are RawDog, a Shiba Inu accountability coach who knows this person deeply. \
        You are their mentor, not a chatbot. You remember everything about them.

        \(memory.toContextString())

        30-DAY SUMMARY:
        Verified: \(verified), Failed: \(failed)
        Streaks: \(streakSummary)
        Hours recovered: \(String(format: "%.1f", Double(verified) * 0.5))

        RULES:
        - Max 3 sentences per response
        - Reference their actual data naturally
        - Be direct, warm, honest. Never preachy.
        - Use contractions. Short sentences.
        - If they're struggling, be empathetic but forward-looking
        - If they're winning, acknowledge without being over the top
        - You can ask follow-up questions
        - Never say "I'm an AI" or break character
        """
    }

    // MARK: - Clear History

    func clearHistory() {
        messages = []
        saveMessages()
    }
}

// MARK: - Mentor Chat View

struct MentorChatView: View {
    @StateObject private var viewModel = MentorChatViewModel()
    @Environment(\.dismiss) private var dismiss

    private let quickPrompts = [
        "How am I doing?",
        "What should I focus on?",
        "Motivate me",
        "Analyze my week",
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            header

            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: RawDog.Spacing.sm) {
                        // Quick prompts when empty
                        if viewModel.messages.isEmpty {
                            if let greeting = viewModel.preWarmedGreeting {
                                rawdogBubble(text: greeting)
                                    .id("greeting")
                            }

                            quickPromptPills
                        }

                        ForEach(viewModel.messages) { message in
                            if message.role == .user {
                                userBubble(text: message.content)
                            } else {
                                rawdogBubble(text: message.content)
                            }
                        }

                        if viewModel.isLoading {
                            typingIndicator
                        }
                    }
                    .padding(.horizontal, RawDog.Spacing.md)
                    .padding(.vertical, RawDog.Spacing.sm)
                }
                .onChange(of: viewModel.messages.count) {
                    if let last = viewModel.messages.last {
                        withAnimation {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }

            // Input bar
            inputBar
        }
        .background(RawDog.Colors.background)
        .onAppear {
            viewModel.preWarm()
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(RawDog.Colors.textSecondary)
            }

            Spacer()

            HStack(spacing: 8) {
                AnimatedMascot(state: .neutral, size: 40)

                Text("RawDog")
                    .font(RawDog.Typography.headline)
                    .foregroundStyle(RawDog.Colors.textPrimary)
            }

            Spacer()

            // Balance layout
            Color.clear
                .frame(width: 28, height: 28)
        }
        .padding(.horizontal, RawDog.Spacing.md)
        .padding(.vertical, RawDog.Spacing.sm)
        .background(RawDog.Colors.cardBackground)
    }

    // MARK: - Quick Prompts

    private var quickPromptPills: some View {
        VStack(spacing: RawDog.Spacing.sm) {
            ForEach(quickPrompts, id: \.self) { prompt in
                Button {
                    viewModel.sendQuickPrompt(prompt)
                } label: {
                    Text(prompt)
                        .font(RawDog.Typography.subheadline)
                        .foregroundStyle(RawDog.Colors.accentIce)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RawDog.Colors.cardBackground, in: RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(RawDog.Colors.borderSubtle, lineWidth: 1)
                        )
                }
            }
        }
        .padding(.top, RawDog.Spacing.sm)
    }

    // MARK: - Message Bubbles

    private func userBubble(text: String) -> some View {
        HStack {
            Spacer()
            Text(text)
                .font(RawDog.Typography.body)
                .foregroundStyle(.black)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(RawDog.Colors.accentIce, in: BubbleShape(isUser: true))
        }
    }

    private func rawdogBubble(text: String) -> some View {
        HStack {
            Text(text)
                .font(RawDog.Typography.body)
                .foregroundStyle(RawDog.Colors.textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(RawDog.Colors.cardBackground, in: BubbleShape(isUser: false))
                .overlay(
                    BubbleShape(isUser: false)
                        .strokeBorder(RawDog.Colors.borderSubtle, lineWidth: 1)
                )
            Spacer()
        }
    }

    private var typingIndicator: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { _ in
                    Circle()
                        .fill(RawDog.Colors.textSecondary)
                        .frame(width: 6, height: 6)
                        .opacity(0.6)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(RawDog.Colors.cardBackground, in: BubbleShape(isUser: false))
            .overlay(
                BubbleShape(isUser: false)
                    .strokeBorder(RawDog.Colors.borderSubtle, lineWidth: 1)
            )
            Spacer()
        }
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(spacing: RawDog.Spacing.sm) {
            TextField("Ask RawDog anything...", text: $viewModel.inputText)
                .font(RawDog.Typography.body)
                .foregroundStyle(RawDog.Colors.textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(RawDog.Colors.surfaceElevated, in: Capsule())

            Button {
                viewModel.send()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundStyle(
                        viewModel.inputText.trimmingCharacters(in: .whitespaces).isEmpty
                            ? RawDog.Colors.textSecondary
                            : RawDog.Colors.accentIce
                    )
            }
            .disabled(viewModel.inputText.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isLoading)
        }
        .padding(.horizontal, RawDog.Spacing.md)
        .padding(.vertical, RawDog.Spacing.sm)
        .background(RawDog.Colors.cardBackground)
    }
}

// MARK: - Bubble Shape

private struct BubbleShape: InsettableShape {
    let isUser: Bool

    func path(in rect: CGRect) -> Path {
        let radius: CGFloat = 16
        let tailSize: CGFloat = 4

        if isUser {
            return RoundedRectangle(cornerRadius: radius)
                .path(in: CGRect(x: 0, y: 0, width: rect.width - tailSize, height: rect.height))
        } else {
            return RoundedRectangle(cornerRadius: radius)
                .path(in: CGRect(x: tailSize, y: 0, width: rect.width - tailSize, height: rect.height))
        }
    }

    func inset(by amount: CGFloat) -> some InsettableShape {
        self
    }
}

// MARK: - Floating Mentor Button

struct FloatingMentorButton: View {
    @State private var showChat = false

    var body: some View {
        Button {
            showChat = true
        } label: {
            Image(systemName: "bubble.left.fill")
                .font(.title3)
                .foregroundStyle(.black)
                .frame(width: 52, height: 52)
                .background(RawDog.Colors.accentIce, in: Circle())
                .shadow(color: RawDog.Colors.accentIce.opacity(0.3), radius: 8, y: 4)
        }
        .fullScreenCover(isPresented: $showChat) {
            MentorChatView()
        }
    }
}
