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
                colorHex: "#F5A623",
                blockAppStore: true,
                blockAppDeletion: true,
                isSystem: true,
                blockedWebsites: socialMediaDomains + newsDomains
            ),
            Mode(
                name: "Deep Work",
                icon: "brain.head.profile",
                colorHex: "#4A90D9",
                blockAppStore: true,
                blockAppDeletion: true,
                isSystem: true,
                blockedWebsites: socialMediaDomains + newsDomains
            ),
            Mode(
                name: "Break",
                icon: "cup.and.saucer.fill",
                colorHex: "#7ED321",
                blockAppStore: false,
                blockAppDeletion: false,
                isSystem: true
            ),
            Mode(
                name: "Exercise",
                icon: "figure.run",
                colorHex: "#E74C3C",
                blockAppStore: true,
                blockAppDeletion: true,
                isSystem: true
            ),
            Mode(
                name: "Commute",
                icon: "car.fill",
                colorHex: "#9B59B6",
                blockAppStore: false,
                blockAppDeletion: true,
                isSystem: true
            ),
            Mode(
                name: "Wind Down",
                icon: "moon.fill",
                colorHex: "#8E8E93",
                blockAppStore: true,
                blockAppDeletion: true,
                isSystem: true,
                blockedWebsites: socialMediaDomains
            ),
            Mode(
                name: "Free Time",
                icon: "gamecontroller.fill",
                colorHex: "#34C759",
                blockAppStore: false,
                blockAppDeletion: false,
                isSystem: true
            ),
            Mode(
                name: "Sleep",
                icon: "bed.double.fill",
                colorHex: "#1C1C1E",
                blockAppStore: true,
                blockAppDeletion: true,
                isSystem: true,
                blockedWebsites: socialMediaDomains
            ),
        ]
    }
}
