import Foundation

// MARK: - Chat Message (kept for potential future use)

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

// MARK: - Legacy Onboarding Answers (kept for backward compat)

struct OnboardingAnswers {
    var dataShockReaction: String?
    var selectedGoalID: String?
    var commitmentDays: Int?
    var strictnessLevel: String?
    var selectedProfileIDs: [String] = []
    var wakeTime: SimpleTime?
    var bedTime: SimpleTime?
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
