import Foundation

struct WeeklySchedule: Codable, Identifiable, Equatable {
    var id: UUID
    var name: String
    var blockIDs: [UUID]
    var isActive: Bool

    init(
        id: UUID = UUID(),
        name: String = "My Schedule",
        blockIDs: [UUID] = [],
        isActive: Bool = true
    ) {
        self.id = id
        self.name = name
        self.blockIDs = blockIDs
        self.isActive = isActive
    }
}
