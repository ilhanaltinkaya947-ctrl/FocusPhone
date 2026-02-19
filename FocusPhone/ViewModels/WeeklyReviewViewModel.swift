import SwiftUI
import WidgetKit

struct WeeklyReviewSuggestion: Codable {
    let type: String
    let modeName: String
    let dayOfWeek: Int
    let startHour: Int
    let startMinute: Int
    let endHour: Int
    let endMinute: Int
    let reason: String
    let originalBlockID: String?
}

struct WeeklyReviewResponse: Codable {
    let summary: String
    let suggestions: [WeeklyReviewSuggestion]
}

@MainActor
class WeeklyReviewViewModel: ObservableObject {
    @Published var currentStep = 0
    @Published var isLoading = false
    @Published var summary: String?
    @Published var suggestions: [WeeklyReviewSuggestion] = []
    @Published var appliedSuggestions: Set<Int> = []
    @Published var commitmentLevel: String = AppState.shared.commitmentLevel
    @Published var sealed = false

    var shouldShowReview: Bool {
        let state = AppState.shared
        guard state.aiEnabled else { return false }

        let calendar = Calendar.current
        let today = calendar.component(.weekday, from: Date())
        guard today == state.weeklyReviewDay else { return false }

        if let lastReview = state.lastWeeklyReview,
           calendar.isDateInToday(lastReview) {
            return false
        }

        return true
    }

    func generateReview() {
        isLoading = true

        let modes = AppState.shared.modes
        let blocks = AppState.shared.timeBlocks
        let sessions = AppState.shared.sessionsForWeek()

        Task {
            // Try AI if available
            if KeychainService.hasKey {
                do {
                    let scheduleText = AIPromptTemplates.formatScheduleForPrompt(blocks: blocks, modes: modes)
                    let statsText = formatStats(sessions: sessions, modes: modes)

                    let messages: [GroqService.Message] = [
                        .init(role: "system", content: AIPromptTemplates.weeklyReviewSystem),
                        .init(role: "user", content: AIPromptTemplates.weeklyReviewUser(
                            stats: statsText,
                            schedule: scheduleText
                        )),
                    ]

                    let response = try await GroqService.shared.chatJSON(
                        messages: messages,
                        as: WeeklyReviewResponse.self
                    )

                    summary = response.summary
                    suggestions = response.suggestions
                    isLoading = false
                    return
                } catch {
                    // Fall through to local summary
                }
            }

            // Fallback: local summary
            summary = generateLocalSummary(sessions: sessions, modes: modes)
            suggestions = []
            isLoading = false
        }
    }

    func applySuggestion(at index: Int) {
        guard index < suggestions.count else { return }
        let suggestion = suggestions[index]

        var blocks = AppState.shared.timeBlocks
        let modes = AppState.shared.modes
        let modeMap = Dictionary(uniqueKeysWithValues: modes.map { ($0.name.lowercased(), $0.id) })

        switch suggestion.type {
        case "add":
            guard let modeID = modeMap[suggestion.modeName.lowercased()] else { return }
            blocks.append(TimeBlock(
                modeID: modeID,
                dayOfWeek: suggestion.dayOfWeek,
                startHour: suggestion.startHour,
                startMinute: suggestion.startMinute,
                endHour: suggestion.endHour,
                endMinute: suggestion.endMinute
            ))

        case "remove":
            if let idStr = suggestion.originalBlockID,
               let blockID = UUID(uuidString: idStr) {
                blocks.removeAll { $0.id == blockID }
            }

        case "resize":
            if let idStr = suggestion.originalBlockID,
               let blockID = UUID(uuidString: idStr),
               let idx = blocks.firstIndex(where: { $0.id == blockID }) {
                blocks[idx].startHour = suggestion.startHour
                blocks[idx].startMinute = suggestion.startMinute
                blocks[idx].endHour = suggestion.endHour
                blocks[idx].endMinute = suggestion.endMinute
            }

        default:
            break
        }

        AppState.shared.timeBlocks = blocks
        ScheduleService.registerAllTimeBlocks()
        WidgetCenter.shared.reloadAllTimelines()

        appliedSuggestions.insert(index)
    }

    func sealWeek() {
        AppState.shared.commitmentLevel = commitmentLevel
        AppState.shared.lastWeeklyReview = Date()
        sealed = true
    }

    // MARK: - Private

    private func formatStats(sessions: [ModeSession], modes: [Mode]) -> String {
        var lines: [String] = []

        let modeGroups = Dictionary(grouping: sessions, by: \.modeID)
        for (modeID, modeSessions) in modeGroups {
            let modeName = modes.first(where: { $0.id == modeID })?.name ?? "Unknown"
            let totalMinutes = modeSessions.reduce(0) { total, session in
                let duration = (session.endDate ?? Date()).timeIntervalSince(session.startDate) / 60
                return total + Int(duration)
            }
            let hours = totalMinutes / 60
            let mins = totalMinutes % 60
            lines.append("\(modeName): \(hours)h \(mins)m across \(modeSessions.count) sessions")
        }

        if lines.isEmpty {
            return "No tracked sessions this week."
        }

        return lines.joined(separator: "\n")
    }

    private func generateLocalSummary(sessions: [ModeSession], modes: [Mode]) -> String {
        let totalSessions = sessions.count
        if totalSessions == 0 {
            return "No sessions were tracked this week. Consider setting up time blocks to start building your routine."
        }

        let totalMinutes = sessions.reduce(0) { total, session in
            let duration = (session.endDate ?? Date()).timeIntervalSince(session.startDate) / 60
            return total + Int(duration)
        }
        let hours = totalMinutes / 60

        return "This week you had \(totalSessions) scheduled sessions totaling about \(hours) hours. Keep building consistent habits!"
    }
}
