import Foundation

struct ExtensionRequest: Codable, Identifiable, Equatable {
    var id: UUID
    var appName: String
    var reason: String
    var requestedMinutes: Int
    var grantedMinutes: Int?
    var wasApproved: Bool
    var timestamp: Date

    init(
        id: UUID = UUID(),
        appName: String,
        reason: String,
        requestedMinutes: Int,
        grantedMinutes: Int? = nil,
        wasApproved: Bool,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.appName = appName
        self.reason = reason
        self.requestedMinutes = requestedMinutes
        self.grantedMinutes = grantedMinutes
        self.wasApproved = wasApproved
        self.timestamp = timestamp
    }
}

struct DailyUsage: Codable, Identifiable, Equatable {
    var id: UUID
    var date: Date
    var extensionMinutesUsed: Int
    var timedWindowsOpened: Int
    var extensionRequestsMade: Int
    var extensionRequestsApproved: Int

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        extensionMinutesUsed: Int = 0,
        timedWindowsOpened: Int = 0,
        extensionRequestsMade: Int = 0,
        extensionRequestsApproved: Int = 0
    ) {
        self.id = id
        self.date = date
        self.extensionMinutesUsed = extensionMinutesUsed
        self.timedWindowsOpened = timedWindowsOpened
        self.extensionRequestsMade = extensionRequestsMade
        self.extensionRequestsApproved = extensionRequestsApproved
    }
}
