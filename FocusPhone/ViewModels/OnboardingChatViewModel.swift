import Foundation

struct ChatMessage: Identifiable, Equatable {
    let id = UUID()
    let role: ChatRole
    let content: String
    let timestamp = Date()
    var suggestionChips: [String]?

    enum ChatRole: Equatable {
        case user
        case assistant
        case system
    }
}

// MARK: - Onboarding Answers (collected from structured screens)

struct OnboardingAnswers {
    var dataShockReaction: String?
    var selectedGoalID: String?
    var commitmentDays: Int?
    var strictnessLevel: String?
    var selectedProfileIDs: [String] = []
    var wakeTime: SimpleTime?
    var bedTime: SimpleTime?
}

@MainActor
class OnboardingChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText = ""
    @Published var isLoading = false
    @Published var generatedProfile: PersonalRestrictionProfile?
    @Published var errorMessage: String?
    @Published var conversationStage: ConversationStage = .dataShock
    @Published var isVoiceMode = false
    @Published var mascotState: MascotState = .neutral
    @Published var onboardingAnswers = OnboardingAnswers()

    enum ConversationStage {
        case dataShock
        case goalSelection
        case commitment
        case strictness
        case chatting
        case profileReady
        case applying
    }

    private var conversationHistory: [AIService.Message] = []
    let speechService = SpeechService()

    func startConversation() {
        guard messages.isEmpty else { return }

        // Build context from structured screen answers
        let userContext = buildUserContext()
        let systemPrompt = GeminiPrompts.onboardingSystem(userContext: userContext)
        conversationHistory = [
            AIService.Message(role: "system", content: systemPrompt),
        ]

        mascotState = .thinking
        isLoading = true
        conversationStage = .chatting
        Task {
            do {
                let greeting = "hey, i've already picked my settings. here's what i chose: \(userContext). let's fine-tune my restrictions."
                let startMessages = conversationHistory + [
                    AIService.Message(role: "user", content: greeting)
                ]
                let response = try await AIService.shared.chatWithFallback(
                    messages: startMessages,
                    temperature: 0.7,
                    maxTokens: 500
                )

                conversationHistory.append(AIService.Message(role: "user", content: greeting))
                conversationHistory.append(AIService.Message(role: "assistant", content: response))

                let (displayText, chips) = parseChipsFromResponse(response)
                var msg = ChatMessage(role: .assistant, content: displayText)
                msg.suggestionChips = chips
                messages.append(msg)
                mascotState = .amused
            } catch {
                errorMessage = error.localizedDescription
                mascotState = .concerned
            }
            isLoading = false
        }
    }

    func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        inputText = ""
        messages.append(ChatMessage(role: .user, content: text))
        conversationHistory.append(AIService.Message(role: "user", content: text))

        mascotState = .thinking
        isLoading = true
        Task {
            do {
                let response = try await AIService.shared.chatWithFallback(
                    messages: conversationHistory,
                    temperature: 0.7,
                    maxTokens: 1024
                )

                conversationHistory.append(AIService.Message(role: "assistant", content: response))

                // Check if response contains a profile JSON
                if let profile = parseProfileFromResponse(response) {
                    generatedProfile = profile
                    let displayText = response
                        .components(separatedBy: "PROFILE_JSON:")
                        .first?
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        ?? "here's your personalized restriction profile!"
                    if !displayText.isEmpty {
                        var msg = ChatMessage(role: .assistant, content: displayText)
                        msg.suggestionChips = nil
                        messages.append(msg)
                    }
                    mascotState = .proud
                    conversationStage = .profileReady
                } else {
                    let (displayText, chips) = parseChipsFromResponse(response)
                    var msg = ChatMessage(role: .assistant, content: displayText)
                    msg.suggestionChips = chips
                    messages.append(msg)
                    mascotState = chips != nil ? .amused : .neutral
                }
            } catch {
                errorMessage = error.localizedDescription
                mascotState = .concerned
            }
            isLoading = false
        }
    }

    // MARK: - Voice Mode

    func enterVoiceMode() {
        Task {
            let granted = await speechService.requestPermission()
            if granted {
                isVoiceMode = true
                speechService.startListening()
                mascotState = .listening
            }
        }
    }

    func exitVoiceMode() {
        speechService.stopListening()
        isVoiceMode = false
        mascotState = .neutral
    }

    func sendVoiceMessage(_ text: String) {
        speechService.stopListening()
        isVoiceMode = false
        inputText = text
        sendMessage()
    }

    func toggleVoiceInput() {
        if isVoiceMode {
            exitVoiceMode()
        } else {
            enterVoiceMode()
        }
    }

    func applyProfile() {
        guard let profile = generatedProfile else { return }
        conversationStage = .applying

        RestrictionEngine.activateProfile(profile)
        AppState.shared.isOnboardingCompleted = true
    }

    // MARK: - Chip Parsing

    private func parseChipsFromResponse(_ response: String) -> (String, [String]?) {
        let lines = response.components(separatedBy: "\n")
        guard let lastLine = lines.last?.trimmingCharacters(in: .whitespacesAndNewlines),
              lastLine.hasPrefix("CHIPS:") else {
            return (response, nil)
        }

        let displayText = lines.dropLast().joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        let chipsRaw = lastLine.replacingOccurrences(of: "CHIPS:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)

        // Parse JSON array ["a","b","c"]
        if let data = chipsRaw.data(using: .utf8),
           let chips = try? JSONDecoder().decode([String].self, from: data),
           !chips.isEmpty {
            return (displayText, chips)
        }

        return (displayText.isEmpty ? response : displayText, nil)
    }

    // MARK: - Context Builder

    private func buildUserContext() -> String {
        var parts: [String] = []
        if let reaction = onboardingAnswers.dataShockReaction {
            parts.append("data shock reaction: \(reaction)")
        }
        if let goal = onboardingAnswers.selectedGoalID {
            parts.append("goal: \(goal)")
        }
        if let days = onboardingAnswers.commitmentDays {
            parts.append("commitment: \(days) days")
        }
        if let strictness = onboardingAnswers.strictnessLevel {
            parts.append("strictness: \(strictness)")
        }
        if !onboardingAnswers.selectedProfileIDs.isEmpty {
            parts.append("selected profiles: \(onboardingAnswers.selectedProfileIDs.joined(separator: ", "))")
        }
        if let wake = onboardingAnswers.wakeTime {
            parts.append("wake time: \(wake.formatted)")
        }
        if let bed = onboardingAnswers.bedTime {
            parts.append("bed time: \(bed.formatted)")
        }
        return parts.isEmpty ? "no preferences yet" : parts.joined(separator: ", ")
    }

    // MARK: - Profile Parsing

    private func parseProfileFromResponse(_ response: String) -> PersonalRestrictionProfile? {
        guard let markerRange = response.range(of: "PROFILE_JSON:") else { return nil }
        let jsonString = String(response[markerRange.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)

        guard let jsonStart = jsonString.firstIndex(of: "{"),
              let jsonEnd = findMatchingBrace(in: jsonString, from: jsonStart) else { return nil }

        let jsonSubstring = String(jsonString[jsonStart...jsonEnd])
        guard let data = jsonSubstring.data(using: .utf8) else { return nil }

        do {
            let parsed = try JSONDecoder().decode(AIGeneratedProfile.self, from: data)
            return PersonalRestrictionProfile(
                activePresetIDs: parsed.activePresetIDs ?? [],
                timedWindowApps: (parsed.timedWindowApps ?? []).map { app in
                    TimedWindowApp(
                        appName: app.appName,
                        windowDurationMinutes: app.windowDurationMinutes,
                        cooldownMinutes: app.cooldownMinutes
                    )
                },
                blockYouTubeNativeApp: parsed.blockYouTubeNativeApp ?? false,
                blockedWebsites: parsed.blockedWebsites ?? [],
                browserContentFilters: parsed.browserContentFilters ?? [],
                blockAppStore: parsed.blockAppStore ?? true,
                blockAppDeletion: parsed.blockAppDeletion ?? true,
                dailyExtensionCapMinutes: parsed.dailyExtensionCapMinutes ?? 30,
                onboardingSummary: parsed.onboardingSummary
            )
        } catch {
            print("OnboardingChatVM: Failed to parse profile JSON: \(error)")
            return nil
        }
    }

    private func findMatchingBrace(in string: String, from startIndex: String.Index) -> String.Index? {
        var depth = 0
        var index = startIndex
        while index < string.endIndex {
            let char = string[index]
            if char == "{" { depth += 1 }
            if char == "}" { depth -= 1 }
            if depth == 0 { return index }
            index = string.index(after: index)
        }
        return nil
    }
}

// MARK: - AI-Generated Profile DTO

private struct AIGeneratedProfile: Decodable {
    let activePresetIDs: [String]?
    let timedWindowApps: [AITimedWindowApp]?
    let blockYouTubeNativeApp: Bool?
    let blockedWebsites: [String]?
    let browserContentFilters: [String]?
    let blockAppStore: Bool?
    let blockAppDeletion: Bool?
    let dailyExtensionCapMinutes: Int?
    let onboardingSummary: String?
}

private struct AITimedWindowApp: Decodable {
    let appName: String
    let windowDurationMinutes: Int
    let cooldownMinutes: Int
}
