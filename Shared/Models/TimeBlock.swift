import Foundation

struct TimeBlock: Codable, Identifiable, Equatable {
    var id: UUID
    var appID: UUID                   // ID of TimedWindowApp
    var dayOfWeek: Int                // 1=Sunday ... 7=Saturday
    var startHour: Int
    var startMinute: Int
    var endHour: Int
    var endMinute: Int
    var isRecurring: Bool

    init(
        id: UUID = UUID(),
        appID: UUID,
        dayOfWeek: Int,
        startHour: Int,
        startMinute: Int,
        endHour: Int,
        endMinute: Int,
        isRecurring: Bool = true
    ) {
        self.id = id
        self.appID = appID
        self.dayOfWeek = dayOfWeek
        self.startHour = startHour
        self.startMinute = startMinute
        self.endHour = endHour
        self.endMinute = endMinute
        self.isRecurring = isRecurring
    }

    // Backward-compatible decoding: accept both "appID" and legacy "modeID"
    enum CodingKeys: String, CodingKey {
        case id, appID, modeID, dayOfWeek, startHour, startMinute, endHour, endMinute, isRecurring
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        appID = try container.decodeIfPresent(UUID.self, forKey: .appID)
            ?? (try container.decodeIfPresent(UUID.self, forKey: .modeID))
            ?? UUID()
        dayOfWeek = try container.decode(Int.self, forKey: .dayOfWeek)
        startHour = try container.decode(Int.self, forKey: .startHour)
        startMinute = try container.decode(Int.self, forKey: .startMinute)
        endHour = try container.decode(Int.self, forKey: .endHour)
        endMinute = try container.decode(Int.self, forKey: .endMinute)
        isRecurring = try container.decode(Bool.self, forKey: .isRecurring)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(appID, forKey: .appID)
        try container.encode(dayOfWeek, forKey: .dayOfWeek)
        try container.encode(startHour, forKey: .startHour)
        try container.encode(startMinute, forKey: .startMinute)
        try container.encode(endHour, forKey: .endHour)
        try container.encode(endMinute, forKey: .endMinute)
        try container.encode(isRecurring, forKey: .isRecurring)
    }

    var startTimeString: String {
        String(format: "%02d:%02d", startHour, startMinute)
    }

    var endTimeString: String {
        String(format: "%02d:%02d", endHour, endMinute)
    }

    var durationMinutes: Int {
        let startTotal = startHour * 60 + startMinute
        let endTotal = endHour * 60 + endMinute
        return endTotal >= startTotal ? endTotal - startTotal : (24 * 60 - startTotal) + endTotal
    }
}
