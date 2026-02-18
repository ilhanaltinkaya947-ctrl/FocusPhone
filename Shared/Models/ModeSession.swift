import Foundation

struct ModeSession: Codable, Identifiable {
    var id: UUID
    var modeID: UUID
    var modeName: String
    var modeColorHex: String
    var startDate: Date
    var endDate: Date?

    init(
        id: UUID = UUID(),
        modeID: UUID,
        modeName: String,
        modeColorHex: String,
        startDate: Date = Date(),
        endDate: Date? = nil
    ) {
        self.id = id
        self.modeID = modeID
        self.modeName = modeName
        self.modeColorHex = modeColorHex
        self.startDate = startDate
        self.endDate = endDate
    }

    var duration: TimeInterval {
        let end = endDate ?? Date()
        return end.timeIntervalSince(startDate)
    }
}
