import Foundation

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
