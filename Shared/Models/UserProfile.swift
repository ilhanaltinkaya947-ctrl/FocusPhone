import Foundation

struct UserProfile: Codable, Equatable {
    var selectedLifeAreas: [LifeArea]
    var wakeTime: Int           // Hour (5-11)
    var sleepTime: Int          // Hour (20-2)
    var workStartHour: Int
    var workEndHour: Int
    var workDays: [Int]         // 1=Sunday ... 7=Saturday
    var exerciseFrequency: Int  // 0-7 times per week
    var biggestTimeWasters: [String]

    static let `default` = UserProfile(
        selectedLifeAreas: [.body, .mind, .career],
        wakeTime: 7,
        sleepTime: 23,
        workStartHour: 9,
        workEndHour: 17,
        workDays: [2, 3, 4, 5, 6],
        exerciseFrequency: 3,
        biggestTimeWasters: ["Social Media"]
    )
}
