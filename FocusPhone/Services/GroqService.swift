import Foundation

class GroqService {
    static let shared = GroqService()

    private let model = "llama-3.1-8b-instant"

    // MARK: - Core API Call (through Cloudflare Worker)

    private func call(system: String, user: String, maxTokens: Int = 1000) async throws -> String {
        guard let url = URL(string: Constants.groqServiceBaseURL) else {
            throw GroqError.noResponse
        }

        let body: [String: Any] = [
            "model": model,
            "max_tokens": maxTokens,
            "messages": [
                ["role": "system", "content": system],
                ["role": "user", "content": user]
            ]
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            throw GroqError.parseError
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(Constants.aiServiceToken)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw GroqError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GroqError.noResponse
        }

        guard httpResponse.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw GroqError.httpError(httpResponse.statusCode, body)
        }

        let groqResponse = try JSONDecoder().decode(GroqResponse.self, from: data)
        guard let content = groqResponse.choices.first?.message.content else {
            throw GroqError.noResponse
        }

        return content
    }

    /// Extract JSON from a response that may contain markdown code fences
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

// MARK: - Journey Engine

extension GroqService {

    func generateJourney(goal: String, weeks: Int, dailyMinutes: Int) async throws -> Journey {
        let memory = UserMemoryStore.shared.memory

        let system = """
        You are RawDog's schedule architect. You build structured, realistic \
        week-by-week commitment schedules.

        \(memory.toContextString())

        Rules:
        - Never schedule on the user's consistently skipped days unless asked
        - Respect their daily available time limit
        - Build progressively — week 1 is easier than week 4
        - Each week has a clear theme and milestone
        - Each day has exactly ONE concrete task with a time and duration
        - Tasks must be completable and verifiable with a photo
        - Return ONLY valid JSON, no explanation

        JSON structure:
        {
          "title": "string",
          "goal": "string",
          "weeks": [
            {
              "weekNumber": 1,
              "theme": "string",
              "milestone": "string",
              "days": [
                {
                  "dayName": "Monday",
                  "task": {
                    "title": "string",
                    "description": "string",
                    "scheduledTime": "HH:MM",
                    "durationMinutes": 30,
                    "verificationType": "photo",
                    "completionCriteria": "string"
                  }
                }
              ]
            }
          ]
        }
        """

        let userPrompt = """
        Build a \(weeks)-week schedule for: \(goal)
        Daily time available: \(dailyMinutes) minutes
        """

        let raw = try await call(system: system, user: userPrompt, maxTokens: 2000)
        let jsonString = extractJSON(from: raw)

        guard let data = jsonString.data(using: .utf8),
              let journey = try? JSONDecoder().decode(Journey.self, from: data)
        else { throw GroqError.parseError }

        // Update memory with schedule generation timestamp
        var m = UserMemoryStore.shared.memory
        m.lastScheduleGeneratedAt = Date()
        UserMemoryStore.shared.memory = m

        return journey
    }
}

// MARK: - Mentor Service

extension GroqService {

    func generateWeeklyMorningMessage() async throws -> String {
        let memory = UserMemoryStore.shared.memory

        let system = """
        You are RawDog, a disciplined Shiba Inu who acts as a personal \
        accountability coach. You are direct, warm, and believe in the user. \
        Never preachy. Never generic. Reference their actual data.

        \(memory.toContextString())
        """

        let prompt = """
        Write a Monday morning notification message (max 2 sentences).
        Reference something specific from their recent performance.
        Energy level: high but not cringe. Direct.
        """

        return try await call(system: system, user: prompt, maxTokens: 100)
    }

    func generateSessionFeedback(commitment: String, wasVerified: Bool, streak: Int) async throws -> String {
        let memory = UserMemoryStore.shared.memory

        let system = """
        You are RawDog. Direct, honest, warm. Never more than 2 sentences.

        \(memory.toContextString())
        """

        let status = wasVerified ? "just completed and verified" : "just skipped"
        let prompt = "User \(status) their \(commitment) session. Streak: \(streak) days. Respond."

        return try await call(system: system, user: prompt, maxTokens: 80)
    }

    func generateWeeklyInsights(stats: [String: HabitStats]) async throws -> WeeklyInsight {
        let memory = UserMemoryStore.shared.memory

        let statsString = stats.map { key, stat in
            "\(key): \(Int(stat.completionRate * 100))% completion, \(stat.currentStreak) day streak"
        }.joined(separator: "\n")

        let system = """
        You are RawDog's behavior analysis engine. Analyze the user's weekly \
        performance data and generate honest, specific insights.

        \(memory.toContextString())

        Return ONLY valid JSON:
        {
          "headline": "one punchy sentence summarizing the week",
          "insight": "2-3 sentence honest analysis referencing specific patterns",
          "adjustment": "one specific schedule change recommendation or null",
          "motivationStyle": "what motivates this person based on their data",
          "blockers": ["pattern 1", "pattern 2"],
          "openLoop": "one thing to follow up on next week or null",
          "milestone": "a win worth celebrating or null"
        }
        """

        let prompt = "This week's stats:\n\(statsString)"

        let raw = try await call(system: system, user: prompt, maxTokens: 400)
        let jsonString = extractJSON(from: raw)

        guard let data = jsonString.data(using: .utf8),
              let insight = try? JSONDecoder().decode(WeeklyInsight.self, from: data)
        else { throw GroqError.parseError }

        // Store insights back into memory so future calls are smarter
        UserMemoryStore.shared.updateFromAIInsights(
            motivationStyle: insight.motivationStyle,
            blockers: insight.blockers,
            checkInSummary: insight.insight,
            openLoops: insight.openLoop.map { [$0] },
            milestone: insight.milestone
        )

        return insight
    }

    func askMentor(question: String) async throws -> String {
        let memory = UserMemoryStore.shared.memory

        let system = """
        You are RawDog, a Shiba Inu accountability coach. You know this person \
        well — their patterns, wins, and struggles. Be direct and personal.
        Max 3 sentences. No fluff.

        \(memory.toContextString())
        """

        return try await call(system: system, user: question, maxTokens: 150)
    }
}
