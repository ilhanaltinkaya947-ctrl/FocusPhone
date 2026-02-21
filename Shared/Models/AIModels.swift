import Foundation

struct AIScheduleBlock: Codable {
    let mode: String
    let day: Int
    let startHour: Int
    let startMinute: Int
    let endHour: Int
    let endMinute: Int
}

struct AIScheduleResponse: Codable {
    let blocks: [AIScheduleBlock]
}
