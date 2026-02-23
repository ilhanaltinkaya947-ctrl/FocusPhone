import Foundation

// MARK: - Habit Stack Analysis Result

struct HabitStackAnalysis: Codable {
    let strongestHabit: String
    let stackSuggestion: String
    let failingCommitment: String?
    let failurePattern: String?
    let scheduleAdjustment: String?
}

// MARK: - Habit Stacking Service

final class HabitStackingService {
    static let shared = HabitStackingService()

    private static let analysisKey = "habitStackAnalysis"
    private static let lastAnalysisDateKey = "habitStackLastAnalysis"
    private static let suggestionsKey = "habitStackSuggestions"
    private static let minimumDaysRequired = 14

    // MARK: - Persistence

    var latestAnalysis: HabitStackAnalysis? {
        get { AppState.shared.load(forKey: Self.analysisKey) }
        set { AppState.shared.save(newValue, forKey: Self.analysisKey) }
    }

    var suggestions: [String] {
        get { AppState.shared.load(forKey: Self.suggestionsKey) ?? [] }
        set { AppState.shared.save(newValue, forKey: Self.suggestionsKey) }
    }

    var lastAnalysisDate: Date? {
        get { Constants.sharedDefaults.object(forKey: Self.lastAnalysisDateKey) as? Date }
        set { Constants.sharedDefaults.set(newValue, forKey: Self.lastAnalysisDateKey) }
    }

    // MARK: - Eligibility Check

    var hasEnoughData: Bool {
        let calendar = Calendar.current
        let logs = CommitmentStore.logs
        guard let earliest = logs.map(\.date).min() else { return false }
        let daysSinceFirst = calendar.dateComponents([.day], from: earliest, to: Date()).day ?? 0
        return daysSinceFirst >= Self.minimumDaysRequired
    }

    var needsAnalysis: Bool {
        guard hasEnoughData else { return false }
        guard let lastDate = lastAnalysisDate else { return true }
        // Re-analyze weekly
        let daysSince = Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
        return daysSince >= 7
    }

    // MARK: - Run Analysis

    func analyzeIfNeeded() async {
        guard needsAnalysis else { return }
        await runAnalysis()
    }

    func runAnalysis() async {
        let commitments = CommitmentStore.commitments.filter(\.isActive)
        guard commitments.count >= 2 else { return }

        let memory = UserMemoryStore.shared.memory

        // Build per-commitment data
        let commitmentData = commitments.map { c -> String in
            let stat = CommitmentStore.stats(for: c.id)
            let logs = CommitmentStore.logsForCommitment(id: c.id)
            let recentLogs = logs.prefix(14)
            let recentVerified = recentLogs.filter { $0.status == .verified }.count
            let recentFailed = recentLogs.filter { $0.status == .failed }.count

            // Find common failure times
            let failedHours = logs.filter { $0.status == .failed }
                .map { Calendar.current.component(.hour, from: $0.date) }
            let avgFailHour = failedHours.isEmpty ? "N/A" : "\(failedHours.reduce(0, +) / failedHours.count):00"

            return """
            - \(c.title) (\(c.category.rawValue))
              Schedule: \(c.scheduledHour):\(String(format: "%02d", c.scheduledMinute))
              Streak: \(stat.currentStreak) days, Best: \(stat.bestStreak)
              Completion: \(Int(stat.completionRate * 100))%
              Last 14 days: \(recentVerified) verified, \(recentFailed) failed
              Trend: \(stat.trend.rawValue)
              Common failure time: \(avgFailHour)
            """
        }.joined(separator: "\n")

        let system = """
        You are RawDog's behavior analysis engine. Analyze commitment patterns \
        and find habit stacking opportunities. Be specific and data-driven.

        \(memory.toContextString())
        """

        let prompt = """
        Analyze these 2+ weeks of commitment data and return a JSON object:

        COMMITMENTS:
        \(commitmentData)

        Return ONLY valid JSON with these fields:
        {
          "strongestHabit": "the commitment with highest consistency",
          "stackSuggestion": "a specific tiny habit to pair with their strongest one (1 sentence)",
          "failingCommitment": "the commitment struggling most, or null if all are good",
          "failurePattern": "when/why they fail (e.g. 'skips gym on Wednesdays after late work'), or null",
          "scheduleAdjustment": "one specific timing change that could help, or null"
        }

        Rules:
        - stackSuggestion must build ON an existing win, not create a new big habit
        - Be specific: "After your 6am gym, do 30 seconds of cold shower" not "add a new habit"
        - failurePattern should reference actual day/time patterns from the data
        - scheduleAdjustment should be actionable: "Move meditation from 7pm to 6:30am before gym"
        """

        do {
            let response = try await GroqService.shared.callRetention(system: system, user: prompt, maxTokens: 400)
            if let data = extractJSON(from: response).data(using: .utf8),
               let analysis = try? JSONDecoder().decode(HabitStackAnalysis.self, from: data) {
                latestAnalysis = analysis
                lastAnalysisDate = Date()

                // Build simple suggestions list
                var sug: [String] = []
                sug.append(analysis.stackSuggestion)
                if let adj = analysis.scheduleAdjustment {
                    sug.append(adj)
                }
                suggestions = sug
            }
        } catch {
            print("HabitStackingService: Analysis failed: \(error)")
        }
    }

    // MARK: - JSON Extraction

    private func extractJSON(from text: String) -> String {
        if let jsonStart = text.range(of: "```json"),
           let jsonEnd = text.range(of: "```", range: jsonStart.upperBound..<text.endIndex) {
            return String(text[jsonStart.upperBound..<jsonEnd.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let start = text.range(of: "```"),
           let end = text.range(of: "```", range: start.upperBound..<text.endIndex) {
            return String(text[start.upperBound..<end.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let start = text.firstIndex(of: "{"),
           let end = text.lastIndex(of: "}") {
            return String(text[start...end])
        }
        return text
    }
}
