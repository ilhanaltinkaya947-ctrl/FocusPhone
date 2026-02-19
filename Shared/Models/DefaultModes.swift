import Foundation

enum DefaultModes {
    private static let socialMediaDomains = [
        "twitter.com", "x.com",
        "facebook.com",
        "instagram.com",
        "tiktok.com",
        "reddit.com",
        "snapchat.com",
    ]

    private static let newsDomains = [
        "news.ycombinator.com",
        "cnn.com",
        "bbc.com",
    ]

    static func allDefaults() -> [Mode] {
        [
            Mode(
                name: "Morning Routine",
                icon: "sunrise.fill",
                colorHex: "#E8DCC8",
                blockAppStore: true,
                blockAppDeletion: true,
                isSystem: true,
                blockedWebsites: socialMediaDomains + newsDomains
            ),
            Mode(
                name: "Deep Work",
                icon: "brain.head.profile",
                colorHex: "#A8C5A0",
                blockAppStore: true,
                blockAppDeletion: true,
                isSystem: true,
                blockedWebsites: socialMediaDomains + newsDomains
            ),
            Mode(
                name: "Break",
                icon: "cup.and.saucer.fill",
                colorHex: "#F0C9A6",
                blockAppStore: false,
                blockAppDeletion: false,
                isSystem: true
            ),
            Mode(
                name: "Exercise",
                icon: "figure.run",
                colorHex: "#A0B8D0",
                blockAppStore: true,
                blockAppDeletion: true,
                isSystem: true
            ),
            Mode(
                name: "Commute",
                icon: "car.fill",
                colorHex: "#8EBAB8",
                blockAppStore: false,
                blockAppDeletion: true,
                isSystem: true
            ),
            Mode(
                name: "Wind Down",
                icon: "moon.fill",
                colorHex: "#C4B5D4",
                blockAppStore: true,
                blockAppDeletion: true,
                isSystem: true,
                blockedWebsites: socialMediaDomains
            ),
            Mode(
                name: "Free Time",
                icon: "gamecontroller.fill",
                colorHex: "#E8B8B8",
                blockAppStore: false,
                blockAppDeletion: false,
                isSystem: true
            ),
            Mode(
                name: "Sleep",
                icon: "bed.double.fill",
                colorHex: "#3A3A4A",
                blockAppStore: true,
                blockAppDeletion: true,
                isSystem: true,
                blockedWebsites: socialMediaDomains
            ),
        ]
    }
}
