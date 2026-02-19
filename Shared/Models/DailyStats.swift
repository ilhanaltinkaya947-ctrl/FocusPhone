import Foundation

struct DailyStats: Codable, Identifiable, Equatable {
    var id: UUID
    var date: Date
    var modeMinutes: [String: Int]
    var pickupCount: Int
    var blockedAttempts: Int
    var focusScore: Double
    var intentionCompleted: Bool

    init(
        id: UUID = UUID(),
        date: Date = Calendar.current.startOfDay(for: Date()),
        modeMinutes: [String: Int] = [:],
        pickupCount: Int = 0,
        blockedAttempts: Int = 0,
        focusScore: Double = 0.0,
        intentionCompleted: Bool = false
    ) {
        self.id = id
        self.date = date
        self.modeMinutes = modeMinutes
        self.pickupCount = pickupCount
        self.blockedAttempts = blockedAttempts
        self.focusScore = focusScore
        self.intentionCompleted = intentionCompleted
    }
}
