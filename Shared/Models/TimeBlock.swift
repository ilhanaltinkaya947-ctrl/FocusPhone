import Foundation

struct TimeBlock: Codable, Identifiable, Equatable {
    var id: UUID
    var modeID: UUID
    var dayOfWeek: Int            // 1=Sunday ... 7=Saturday
    var startHour: Int
    var startMinute: Int
    var endHour: Int
    var endMinute: Int
    var isRecurring: Bool

    init(
        id: UUID = UUID(),
        modeID: UUID,
        dayOfWeek: Int,
        startHour: Int,
        startMinute: Int,
        endHour: Int,
        endMinute: Int,
        isRecurring: Bool = true
    ) {
        self.id = id
        self.modeID = modeID
        self.dayOfWeek = dayOfWeek
        self.startHour = startHour
        self.startMinute = startMinute
        self.endHour = endHour
        self.endMinute = endMinute
        self.isRecurring = isRecurring
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
