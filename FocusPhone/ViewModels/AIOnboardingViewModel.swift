import SwiftUI
import FamilyControls
import WidgetKit

struct GroqScheduleBlock: Codable {
    let mode: String
    let day: Int
    let startHour: Int
    let startMinute: Int
    let endHour: Int
    let endMinute: Int
}

struct GroqScheduleResponse: Codable {
    let blocks: [GroqScheduleBlock]
}

@MainActor
class AIOnboardingViewModel: ObservableObject {
    // Life areas
    @Published var selectedLifeAreas: [LifeArea] = []

    // Quick questions
    @Published var wakeTime: Int = 7
    @Published var sleepTime: Int = 23
    @Published var workStartHour: Int = 9
    @Published var workEndHour: Int = 17
    @Published var workDays: [Int] = [2, 3, 4, 5, 6]
    @Published var exerciseFrequency: Int = 3
    @Published var biggestTimeWasters: [String] = []

    // New onboarding fields
    @Published var weeklyGoalText: String = ""
    @Published var customBlockedWebsites: [String] = []
    @Published var commitmentLevel: String = "balanced"
    @Published var onboardingAppSelection: FamilyActivitySelection = .init()
    @Published var hasUserEdited: Bool = false

    // Generated schedule
    @Published var generatedBlocks: [TimeBlock] = []
    @Published var isGenerating = false
    @Published var usedFallback = false
    @Published var errorMessage: String?

    var profile: UserProfile {
        UserProfile(
            selectedLifeAreas: selectedLifeAreas,
            wakeTime: wakeTime,
            sleepTime: sleepTime,
            workStartHour: workStartHour,
            workEndHour: workEndHour,
            workDays: workDays,
            exerciseFrequency: exerciseFrequency,
            biggestTimeWasters: biggestTimeWasters,
            weeklyGoalText: weeklyGoalText,
            customBlockedWebsites: customBlockedWebsites,
            commitmentLevel: commitmentLevel
        )
    }

    func toggleLifeArea(_ area: LifeArea) {
        if let index = selectedLifeAreas.firstIndex(of: area) {
            selectedLifeAreas.remove(at: index)
        } else if selectedLifeAreas.count < 5 {
            selectedLifeAreas.append(area)
        }
    }

    func toggleWorkDay(_ day: Int) {
        if let index = workDays.firstIndex(of: day) {
            workDays.remove(at: index)
        } else {
            workDays.append(day)
        }
    }

    func toggleTimeWaster(_ waster: String) {
        if let index = biggestTimeWasters.firstIndex(of: waster) {
            biggestTimeWasters.remove(at: index)
        } else {
            biggestTimeWasters.append(waster)
        }
    }

    // MARK: - Block Editing

    func addBlock(_ block: TimeBlock) {
        generatedBlocks.append(block)
        hasUserEdited = true
    }

    func updateBlock(_ block: TimeBlock) {
        if let index = generatedBlocks.firstIndex(where: { $0.id == block.id }) {
            generatedBlocks[index] = block
            hasUserEdited = true
        }
    }

    func removeBlock(_ block: TimeBlock) {
        generatedBlocks.removeAll { $0.id == block.id }
        hasUserEdited = true
    }

    // MARK: - Schedule Generation

    func generateSchedule() {
        isGenerating = true
        errorMessage = nil
        usedFallback = false
        generatedBlocks = []

        let modes = AppState.shared.modes
        let currentProfile = profile

        Task {
            // Try AI first if API key is available
            if KeychainService.hasKey && AppState.shared.aiEnabled {
                do {
                    let blocks = try await generateWithAI(profile: currentProfile, modes: modes)
                    generatedBlocks = blocks
                    isGenerating = false
                    return
                } catch {
                    // Fall through to template
                }
            }

            // Fallback to template
            let blocks = ScheduleTemplateService.generateSchedule(from: currentProfile, modes: modes)
            generatedBlocks = blocks
            usedFallback = true
            isGenerating = false
        }
    }

    func applySchedule() {
        let state = AppState.shared

        // Save profile
        state.userProfile = profile

        // Set time blocks
        state.timeBlocks = generatedBlocks

        // Apply app selection to blocking modes (Deep Work, Morning Routine, Wind Down, Sleep)
        let blockingModeNames = ["Deep Work", "Morning Routine", "Wind Down", "Sleep"]
        if !onboardingAppSelection.applicationTokens.isEmpty ||
           !onboardingAppSelection.categoryTokens.isEmpty {
            var modes = state.modes
            for i in modes.indices where blockingModeNames.contains(modes[i].name) {
                modes[i].setFamilyActivitySelection(onboardingAppSelection)
            }
            state.modes = modes
        }

        // Append custom websites to blocking modes
        if !customBlockedWebsites.isEmpty {
            var modes = state.modes
            for i in modes.indices where blockingModeNames.contains(modes[i].name) {
                let existing = Set(modes[i].blockedWebsites)
                let newSites = customBlockedWebsites.filter { !existing.contains($0) }
                modes[i].blockedWebsites.append(contentsOf: newSites)
            }
            state.modes = modes
        }

        // Register schedules
        ScheduleService.registerAllTimeBlocks()

        // Reload widgets
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Private

    private func generateWithAI(profile: UserProfile, modes: [Mode]) async throws -> [TimeBlock] {
        let modeNames = modes.map(\.name)

        // Check cache
        let userPrompt = AIPromptTemplates.scheduleBuilderUser(profile: profile)
        if let cached = AIResponseCache.get(for: userPrompt),
           let data = cached.data(using: .utf8),
           let response = try? JSONDecoder().decode(GroqScheduleResponse.self, from: data) {
            return mapResponseToBlocks(response, modes: modes)
        }

        let messages: [GroqService.Message] = [
            .init(role: "system", content: AIPromptTemplates.scheduleBuilderSystem(modeNames: modeNames, commitmentLevel: profile.commitmentLevel)),
            .init(role: "user", content: userPrompt),
        ]

        let response = try await GroqService.shared.chatJSON(messages: messages, as: GroqScheduleResponse.self)

        // Cache the raw response
        if let data = try? JSONEncoder().encode(response),
           let jsonString = String(data: data, encoding: .utf8) {
            AIResponseCache.set(jsonString, for: userPrompt)
        }

        return mapResponseToBlocks(response, modes: modes)
    }

    private func mapResponseToBlocks(_ response: GroqScheduleResponse, modes: [Mode]) -> [TimeBlock] {
        let modeMap = Dictionary(uniqueKeysWithValues: modes.map { ($0.name.lowercased(), $0.id) })

        return response.blocks.compactMap { block in
            guard let modeID = modeMap[block.mode.lowercased()] else { return nil }
            return TimeBlock(
                modeID: modeID,
                dayOfWeek: block.day,
                startHour: block.startHour,
                startMinute: block.startMinute,
                endHour: block.endHour,
                endMinute: block.endMinute
            )
        }
    }
}
