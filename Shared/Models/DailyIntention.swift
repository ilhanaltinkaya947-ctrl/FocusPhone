import Foundation

struct DailyIntention: Codable, Identifiable, Equatable {
    var id: UUID
    var date: Date
    var text: String
    var completed: Bool?

    init(
        id: UUID = UUID(),
        date: Date = Calendar.current.startOfDay(for: Date()),
        text: String = "",
        completed: Bool? = nil
    ) {
        self.id = id
        self.date = date
        self.text = text
        self.completed = completed
    }
}
