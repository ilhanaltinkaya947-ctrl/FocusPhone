import Foundation

struct ChatMessage: Identifiable, Equatable {
    let id = UUID()
    let role: ChatRole
    let content: String
    let timestamp = Date()

    enum ChatRole: Equatable {
        case user
        case assistant
        case system
    }
}

@MainActor
class OnboardingChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText = ""
    @Published var isLoading = false
    @Published var generatedProfile: PersonalRestrictionProfile?
    @Published var errorMessage: String?
    @Published var conversationStage: ConversationStage = .chatting

    enum ConversationStage {
        case chatting
        case profileReady
        case applying
    }

    private var conversationHistory: [AIService.Message] = []
    let speechService = SpeechService()

    func startConversation() {
        guard messages.isEmpty else { return }

        let systemPrompt = GeminiPrompts.onboardingSystem()
        conversationHistory = [
            AIService.Message(role: "system", content: systemPrompt),
        ]

        isLoading = true
        Task {
            do {
                // Ask AI to start the conversation
                let startMessages = conversationHistory + [
                    AIService.Message(role: "user", content: "Hi, I want to set up my phone restrictions.")
                ]
                let response = try await AIService.shared.chatWithFallback(
                    messages: startMessages,
                    temperature: 0.7,
                    maxTokens: 500
                )

                conversationHistory.append(AIService.Message(role: "user", content: "Hi, I want to set up my phone restrictions."))
                conversationHistory.append(AIService.Message(role: "assistant", content: response))

                messages.append(ChatMessage(role: .assistant, content: response))
            } catch {
                errorMessage = error.localizedDescription
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
                    // Show the response text (without the JSON part)
                    let displayText = response
                        .components(separatedBy: "PROFILE_JSON:")
                        .first?
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        ?? "Here's your personalized restriction profile!"
                    if !displayText.isEmpty {
                        messages.append(ChatMessage(role: .assistant, content: displayText))
                    }
                    conversationStage = .profileReady
                } else {
                    messages.append(ChatMessage(role: .assistant, content: response))
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    func toggleVoiceInput() {
        if speechService.isListening {
            speechService.stopListening()
            if !speechService.transcribedText.isEmpty {
                inputText = speechService.transcribedText
            }
        } else {
            Task {
                let granted = await speechService.requestPermission()
                if granted {
                    speechService.startListening()
                }
            }
        }
    }

    func applyProfile() {
        guard let profile = generatedProfile else { return }
        conversationStage = .applying

        RestrictionEngine.activateProfile(profile)
        AppState.shared.isOnboardingCompleted = true
    }

    // MARK: - Profile Parsing

    private func parseProfileFromResponse(_ response: String) -> PersonalRestrictionProfile? {
        // Look for "PROFILE_JSON:" marker
        guard let markerRange = response.range(of: "PROFILE_JSON:") else { return nil }
        let jsonString = String(response[markerRange.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)

        // Try to find JSON object boundaries
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
