import Foundation

struct FreedomWindow: Codable, Identifiable, Equatable {
    var id: UUID
    var label: String
    var days: Set<Weekday>
    var startHour: Int
    var startMinute: Int
    var endHour: Int
    var endMinute: Int
    var isEnabled: Bool

    init(
        id: UUID = UUID(),
        label: String = "Freedom Window",
        days: Set<Weekday> = [],
        startHour: Int = 12,
        startMinute: Int = 0,
        endHour: Int = 13,
        endMinute: Int = 0,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.label = label
        self.days = days
        self.startHour = startHour
        self.startMinute = startMinute
        self.endHour = endHour
        self.endMinute = endMinute
        self.isEnabled = isEnabled
    }

    var startTimeString: String {
        String(format: "%02d:%02d", startHour, startMinute)
    }

    var endTimeString: String {
        String(format: "%02d:%02d", endHour, endMinute)
    }
}

enum Weekday: Int, Codable, CaseIterable, Identifiable, Comparable {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7

    var id: Int { rawValue }

    var shortName: String {
        switch self {
        case .sunday: return "Sun"
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        }
    }

    static func < (lhs: Weekday, rhs: Weekday) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
