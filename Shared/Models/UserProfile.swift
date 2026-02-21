import Foundation

struct FixedCommitment: Codable, Equatable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var dayOfWeek: Int   // 1=Sunday ... 7=Saturday
    var startHour: Int
    var endHour: Int
}

struct UserProfile: Codable, Equatable {
    var selectedLifeAreas: [LifeArea]
    var wakeTime: Int           // Hour (5-11)
    var sleepTime: Int          // Hour (20-2)
    var workStartHour: Int
    var workEndHour: Int
    var workDays: [Int]         // 1=Sunday ... 7=Saturday
    var exerciseFrequency: Int  // 0-7 times per week
    var biggestTimeWasters: [String]
    var weeklyGoalText: String
    var customBlockedWebsites: [String]
    var commitmentLevel: String // "gentle", "balanced", "strict"
    var energyPattern: String   // "morning_person", "night_owl", "steady"
    var fixedCommitments: [FixedCommitment]
    var distractionTrigger: String // "boredom", "stress", "habit", "social_pressure"
    var dailyPhoneGoal: Int     // target max hours of phone time

    enum CodingKeys: String, CodingKey {
        case selectedLifeAreas, wakeTime, sleepTime, workStartHour, workEndHour
        case workDays, exerciseFrequency, biggestTimeWasters
        case weeklyGoalText, customBlockedWebsites, commitmentLevel
        case energyPattern, fixedCommitments, distractionTrigger, dailyPhoneGoal
    }

    static let `default` = UserProfile(
        selectedLifeAreas: [.body, .mind, .career],
        wakeTime: 7,
        sleepTime: 23,
        workStartHour: 9,
        workEndHour: 17,
        workDays: [2, 3, 4, 5, 6],
        exerciseFrequency: 3,
        biggestTimeWasters: ["Social Media"],
        weeklyGoalText: "",
        customBlockedWebsites: [],
        commitmentLevel: "balanced"
    )

    // Backward-compatible decoder
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        selectedLifeAreas = try container.decode([LifeArea].self, forKey: .selectedLifeAreas)
        wakeTime = try container.decode(Int.self, forKey: .wakeTime)
        sleepTime = try container.decode(Int.self, forKey: .sleepTime)
        workStartHour = try container.decode(Int.self, forKey: .workStartHour)
        workEndHour = try container.decode(Int.self, forKey: .workEndHour)
        workDays = try container.decode([Int].self, forKey: .workDays)
        exerciseFrequency = try container.decode(Int.self, forKey: .exerciseFrequency)
        biggestTimeWasters = try container.decode([String].self, forKey: .biggestTimeWasters)
        weeklyGoalText = try container.decodeIfPresent(String.self, forKey: .weeklyGoalText) ?? ""
        customBlockedWebsites = try container.decodeIfPresent([String].self, forKey: .customBlockedWebsites) ?? []
        commitmentLevel = try container.decodeIfPresent(String.self, forKey: .commitmentLevel) ?? "balanced"
        energyPattern = try container.decodeIfPresent(String.self, forKey: .energyPattern) ?? "steady"
        fixedCommitments = try container.decodeIfPresent([FixedCommitment].self, forKey: .fixedCommitments) ?? []
        distractionTrigger = try container.decodeIfPresent(String.self, forKey: .distractionTrigger) ?? "habit"
        dailyPhoneGoal = try container.decodeIfPresent(Int.self, forKey: .dailyPhoneGoal) ?? 4
    }

    init(
        selectedLifeAreas: [LifeArea],
        wakeTime: Int,
        sleepTime: Int,
        workStartHour: Int,
        workEndHour: Int,
        workDays: [Int],
        exerciseFrequency: Int,
        biggestTimeWasters: [String],
        weeklyGoalText: String = "",
        customBlockedWebsites: [String] = [],
        commitmentLevel: String = "balanced",
        energyPattern: String = "steady",
        fixedCommitments: [FixedCommitment] = [],
        distractionTrigger: String = "habit",
        dailyPhoneGoal: Int = 4
    ) {
        self.selectedLifeAreas = selectedLifeAreas
        self.wakeTime = wakeTime
        self.sleepTime = sleepTime
        self.workStartHour = workStartHour
        self.workEndHour = workEndHour
        self.workDays = workDays
        self.exerciseFrequency = exerciseFrequency
        self.biggestTimeWasters = biggestTimeWasters
        self.weeklyGoalText = weeklyGoalText
        self.customBlockedWebsites = customBlockedWebsites
        self.commitmentLevel = commitmentLevel
        self.energyPattern = energyPattern
        self.fixedCommitments = fixedCommitments
        self.distractionTrigger = distractionTrigger
        self.dailyPhoneGoal = dailyPhoneGoal
    }
}
