import SwiftUI
import FamilyControls
import ManagedSettings
import WidgetKit

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
    @Published var enabledPresets: Set<String> = []
    @Published var hasUserEdited: Bool = false

    // Personalization
    @Published var energyPattern: String = "steady"
    @Published var fixedCommitments: [FixedCommitment] = []
    @Published var distractionTrigger: String = "habit"
    @Published var dailyPhoneGoal: Int = 4

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
            commitmentLevel: commitmentLevel,
            energyPattern: energyPattern,
            fixedCommitments: fixedCommitments,
            distractionTrigger: distractionTrigger,
            dailyPhoneGoal: dailyPhoneGoal
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
            // Try AI first if enabled
            if AppState.shared.aiEnabled {
                do {
                    let blocks = try await generateWithAI(profile: currentProfile, modes: modes)
                    generatedBlocks = blocks
                    isGenerating = false
                    return
                } catch {
                    errorMessage = error.localizedDescription
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

        // Save profile and content filter presets
        state.userProfile = profile
        state.enabledContentFilterPresets = enabledPresets

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

        // Map time waster chips to domain lists and add to blocking modes
        let wasterDomains = domainsForTimeWasters(biggestTimeWasters)

        // Combine custom websites + time waster domains
        let allWebsites = customBlockedWebsites + wasterDomains

        if !allWebsites.isEmpty {
            var modes = state.modes
            for i in modes.indices where blockingModeNames.contains(modes[i].name) {
                let existing = Set(modes[i].blockedWebsites)
                let newSites = allWebsites.filter { !existing.contains($0) }
                modes[i].blockedWebsites.append(contentsOf: newSites)
            }
            state.modes = modes
        }

        // Register schedules
        let registration = ScheduleService.registerAllTimeBlocks()
        if !registration.failed.isEmpty {
            print("Warning: \(registration.failed.count) blocks failed to register")
        }

        // Reload widgets
        WidgetCenter.shared.reloadAllTimelines()

        // CRITICAL: Find and activate the current block immediately
        // Without this, activeModeID is nil and nothing blocks after onboarding
        activateCurrentBlock()
    }

    /// Finds the TimeBlock active right now and applies its mode's blocking rules
    private func activateCurrentBlock() {
        let state = AppState.shared
        let calendar = Calendar.current
        let now = Date()
        let weekday = calendar.component(.weekday, from: now)
        let currentMinutes = calendar.component(.hour, from: now) * 60 + calendar.component(.minute, from: now)

        let todayBlocks = state.timeBlocks(forDay: weekday)
        let activeBlock = todayBlocks.first { block in
            let start = block.startHour * 60 + block.startMinute
            let end = block.endHour * 60 + block.endMinute
            return currentMinutes >= start && currentMinutes < end
        }

        if let activeBlock = activeBlock,
           let mode = state.mode(for: activeBlock.modeID) {
            state.activeModeID = activeBlock.modeID
            state.startSession(for: mode)
            BlockingService.applyBlocks(for: mode)

            // Set block end time for shield display
            if let endTime = calendar.date(
                bySettingHour: activeBlock.endHour,
                minute: activeBlock.endMinute,
                second: 0,
                of: now
            ) {
                state.activeBlockEndTime = endTime
            }
        } else {
            state.activeModeID = nil
            state.activeBlockEndTime = nil
            BlockingService.clearAllBlocks()
        }
    }

    // MARK: - Time Waster Mapping

    private func domainsForTimeWasters(_ wasters: [String]) -> [String] {
        let mapping: [String: [String]] = [
            "Social Media": ["twitter.com", "x.com", "facebook.com", "instagram.com", "tiktok.com", "reddit.com", "snapchat.com"],
            "YouTube": ["youtube.com"],
            "News": ["news.ycombinator.com", "cnn.com", "bbc.com"],
            "Gaming": ["twitch.tv", "steampowered.com"],
            "Shopping": ["amazon.com", "ebay.com"],
            "Streaming": ["netflix.com", "hulu.com", "disneyplus.com"],
        ]
        return wasters.flatMap { mapping[$0] ?? [] }
    }

    // MARK: - Private

    private func generateWithAI(profile: UserProfile, modes: [Mode]) async throws -> [TimeBlock] {
        let modeNames = modes.map(\.name)
        let modeMap = Dictionary(uniqueKeysWithValues: modes.map { ($0.name.lowercased(), $0.id) })

        // Check cache (includes mode context for invalidation)
        let userPrompt = AIPromptTemplates.scheduleBuilderUser(profile: profile)
        if let cached = AIResponseCache.get(for: userPrompt, modeContext: modeNames),
           let data = cached.data(using: .utf8),
           let response = try? JSONDecoder().decode(AIScheduleResponse.self, from: data) {
            return sanitizeAndValidate(response, modeMap: modeMap)
        }

        let messages: [AIService.Message] = [
            .init(role: "system", content: AIPromptTemplates.scheduleBuilderSystem(modeNames: modeNames, commitmentLevel: profile.commitmentLevel)),
            .init(role: "user", content: userPrompt),
        ]

        // Use fallback chain — tries 70B then 8B
        let response = try await AIService.shared.chatJSONWithFallback(
            messages: messages,
            as: AIScheduleResponse.self
        )

        // Cache the raw response
        if let data = try? JSONEncoder().encode(response),
           let jsonString = String(data: data, encoding: .utf8) {
            AIResponseCache.set(jsonString, for: userPrompt, modeContext: modeNames)
        }

        return sanitizeAndValidate(response, modeMap: modeMap)
    }

    /// Sanitize, validate, and resolve conflicts in AI-generated blocks
    private func sanitizeAndValidate(_ response: AIScheduleResponse, modeMap: [String: UUID]) -> [TimeBlock] {
        // Sanitize each block (clamp values, map mode names)
        let sanitized = response.blocks.compactMap { groqBlock in
            TimeBlockValidator.sanitize(groqBlock, modeMap: modeMap)
        }

        // Resolve any overlapping blocks
        return TimeBlockValidator.resolveConflicts(sanitized)
    }
}
