import Foundation

// MARK: - Journey (AI-generated schedule)

struct Journey: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    let title: String
    let goal: String
    let weeks: [JourneyWeek]
    var createdAt: Date = Date()
    var isActive: Bool = true

    private enum CodingKeys: String, CodingKey {
        case title, goal, weeks
    }

    init(title: String, goal: String, weeks: [JourneyWeek]) {
        self.title = title
        self.goal = goal
        self.weeks = weeks
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decode(String.self, forKey: .title)
        goal = try container.decode(String.self, forKey: .goal)
        weeks = try container.decode([JourneyWeek].self, forKey: .weeks)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(title, forKey: .title)
        try container.encode(goal, forKey: .goal)
        try container.encode(weeks, forKey: .weeks)
    }
}

struct JourneyWeek: Codable, Equatable {
    let weekNumber: Int
    let theme: String
    let milestone: String
    let days: [JourneyDay]
}

struct JourneyDay: Codable, Equatable {
    let dayName: String
    let task: JourneyTask
}

struct JourneyTask: Codable, Equatable {
    let title: String
    let description: String
    let scheduledTime: String // "HH:MM"
    let durationMinutes: Int
    let verificationType: String
    let completionCriteria: String
}

// MARK: - Weekly Insight (AI-generated)

struct WeeklyInsight: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    let headline: String
    let insight: String
    let adjustment: String?
    let motivationStyle: String
    let blockers: [String]
    let openLoop: String?
    let milestone: String?
    var generatedAt: Date = Date()

    private enum CodingKeys: String, CodingKey {
        case headline, insight, adjustment, motivationStyle, blockers, openLoop, milestone
    }

    init(headline: String, insight: String, adjustment: String?, motivationStyle: String, blockers: [String], openLoop: String?, milestone: String?) {
        self.headline = headline
        self.insight = insight
        self.adjustment = adjustment
        self.motivationStyle = motivationStyle
        self.blockers = blockers
        self.openLoop = openLoop
        self.milestone = milestone
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        headline = try container.decode(String.self, forKey: .headline)
        insight = try container.decode(String.self, forKey: .insight)
        adjustment = try container.decodeIfPresent(String.self, forKey: .adjustment)
        motivationStyle = try container.decode(String.self, forKey: .motivationStyle)
        blockers = try container.decodeIfPresent([String].self, forKey: .blockers) ?? []
        openLoop = try container.decodeIfPresent(String.self, forKey: .openLoop)
        milestone = try container.decodeIfPresent(String.self, forKey: .milestone)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(headline, forKey: .headline)
        try container.encode(insight, forKey: .insight)
        try container.encode(adjustment, forKey: .adjustment)
        try container.encode(motivationStyle, forKey: .motivationStyle)
        try container.encode(blockers, forKey: .blockers)
        try container.encode(openLoop, forKey: .openLoop)
        try container.encode(milestone, forKey: .milestone)
    }
}

// MARK: - Groq Response Types

struct GroqResponse: Codable {
    struct Choice: Codable {
        struct Message: Codable {
            let content: String
        }
        let message: Message
    }
    let choices: [Choice]
}

enum GroqError: Error, LocalizedError {
    case parseError
    case networkError(Error)
    case httpError(Int, String)
    case noResponse

    var errorDescription: String? {
        switch self {
        case .parseError: return "Failed to parse AI response"
        case .networkError(let error): return "Network error: \(error.localizedDescription)"
        case .httpError(let code, let msg): return "Server error (\(code)): \(msg)"
        case .noResponse: return "No response from AI"
        }
    }
}
