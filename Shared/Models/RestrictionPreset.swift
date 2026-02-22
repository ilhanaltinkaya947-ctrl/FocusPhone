import Foundation

struct PresetConfig {
    let id: String
    let displayName: String
    let icon: String
    let description: String
    let timedWindowApps: [PresetTimedWindowApp]
    let permanentBlockDomains: [String]
    let permanentBlockCategoryNames: [String]
    let blockedWebsites: [String]
    let contentFilterPresetIDs: [String]
    let blockAppStore: Bool
    let blockAppDeletion: Bool
    let blockYouTubeNativeApp: Bool
    let dailyExtensionCapMinutes: Int
}

struct PresetTimedWindowApp {
    let appName: String
    let windowDurationMinutes: Int
    let cooldownMinutes: Int
}

enum RestrictionPresets {

    static let allPresets: [PresetConfig] = [
        socialMediaAddict,
        pornAddictionRecovery,
        doomScrollingRecovery,
        workFromHomeFocus,
        studentFocus,
        digitalMinimalist,
    ]

    static func preset(for id: String) -> PresetConfig? {
        allPresets.first { $0.id == id }
    }

    // MARK: - Social Media Addict

    static let socialMediaAddict = PresetConfig(
        id: "social_media_addict",
        displayName: "Social Media Addict",
        icon: "bubble.left.and.bubble.right.fill",
        description: "Break the scroll habit. Timed windows for social apps, permanent blocks on feeds.",
        timedWindowApps: [
            PresetTimedWindowApp(appName: "Instagram", windowDurationMinutes: 5, cooldownMinutes: 120),
            PresetTimedWindowApp(appName: "TikTok", windowDurationMinutes: 5, cooldownMinutes: 120),
            PresetTimedWindowApp(appName: "Twitter", windowDurationMinutes: 5, cooldownMinutes: 120),
            PresetTimedWindowApp(appName: "Snapchat", windowDurationMinutes: 5, cooldownMinutes: 180),
        ],
        permanentBlockDomains: ["reddit.com", "facebook.com"],
        permanentBlockCategoryNames: ["Social Networking"],
        blockedWebsites: ["reddit.com", "facebook.com", "tiktok.com"],
        contentFilterPresetIDs: ["youtube_focus", "instagram_focus", "twitter_focus"],
        blockAppStore: true,
        blockAppDeletion: true,
        blockYouTubeNativeApp: true,
        dailyExtensionCapMinutes: 30
    )

    // MARK: - Porn Addiction Recovery

    static let pornAddictionRecovery = PresetConfig(
        id: "porn_addiction_recovery",
        displayName: "Porn Addiction Recovery",
        icon: "shield.checkered",
        description: "Maximum protection. Block adult content, lock down browsers, restrict private browsing.",
        timedWindowApps: [],
        permanentBlockDomains: [],
        permanentBlockCategoryNames: [],
        blockedWebsites: [
            "pornhub.com", "xvideos.com", "xhamster.com", "xnxx.com",
            "redtube.com", "youporn.com", "tube8.com", "spankbang.com",
            "eporner.com", "beeg.com", "onlyfans.com", "fansly.com",
        ],
        contentFilterPresetIDs: [],
        blockAppStore: true,
        blockAppDeletion: true,
        blockYouTubeNativeApp: false,
        dailyExtensionCapMinutes: 0
    )

    // MARK: - Doom Scrolling Recovery

    static let doomScrollingRecovery = PresetConfig(
        id: "doom_scrolling_recovery",
        displayName: "Doom Scrolling Recovery",
        icon: "arrow.down.circle.fill",
        description: "Stop infinite feeds. Block algorithmic content, allow intentional use only.",
        timedWindowApps: [
            PresetTimedWindowApp(appName: "Twitter", windowDurationMinutes: 5, cooldownMinutes: 180),
            PresetTimedWindowApp(appName: "Reddit", windowDurationMinutes: 5, cooldownMinutes: 180),
        ],
        permanentBlockDomains: ["news.ycombinator.com"],
        permanentBlockCategoryNames: [],
        blockedWebsites: ["reddit.com", "news.ycombinator.com", "buzzfeed.com", "9gag.com"],
        contentFilterPresetIDs: ["youtube_focus", "twitter_focus"],
        blockAppStore: false,
        blockAppDeletion: true,
        blockYouTubeNativeApp: true,
        dailyExtensionCapMinutes: 30
    )

    // MARK: - Work From Home Focus

    static let workFromHomeFocus = PresetConfig(
        id: "work_from_home_focus",
        displayName: "Work From Home Focus",
        icon: "desktopcomputer",
        description: "Eliminate work-hour distractions. Social media blocked, messaging in timed windows.",
        timedWindowApps: [
            PresetTimedWindowApp(appName: "Instagram", windowDurationMinutes: 5, cooldownMinutes: 120),
            PresetTimedWindowApp(appName: "Twitter", windowDurationMinutes: 5, cooldownMinutes: 120),
        ],
        permanentBlockDomains: ["reddit.com", "facebook.com"],
        permanentBlockCategoryNames: [],
        blockedWebsites: ["reddit.com", "facebook.com", "tiktok.com"],
        contentFilterPresetIDs: ["youtube_focus"],
        blockAppStore: true,
        blockAppDeletion: true,
        blockYouTubeNativeApp: true,
        dailyExtensionCapMinutes: 30
    )

    // MARK: - Student Focus

    static let studentFocus = PresetConfig(
        id: "student_focus",
        displayName: "Student Focus",
        icon: "graduationcap.fill",
        description: "Stay focused during study. Block social media and games, allow educational tools.",
        timedWindowApps: [
            PresetTimedWindowApp(appName: "Instagram", windowDurationMinutes: 5, cooldownMinutes: 120),
            PresetTimedWindowApp(appName: "TikTok", windowDurationMinutes: 5, cooldownMinutes: 180),
            PresetTimedWindowApp(appName: "Snapchat", windowDurationMinutes: 5, cooldownMinutes: 120),
        ],
        permanentBlockDomains: [],
        permanentBlockCategoryNames: ["Games"],
        blockedWebsites: ["reddit.com", "9gag.com"],
        contentFilterPresetIDs: ["youtube_focus", "instagram_focus"],
        blockAppStore: true,
        blockAppDeletion: true,
        blockYouTubeNativeApp: true,
        dailyExtensionCapMinutes: 20
    )

    // MARK: - Digital Minimalist

    static let digitalMinimalist = PresetConfig(
        id: "digital_minimalist",
        displayName: "Digital Minimalist",
        icon: "leaf.fill",
        description: "Phone as a tool, not a toy. Only essentials allowed. Maximum restriction.",
        timedWindowApps: [],
        permanentBlockDomains: [],
        permanentBlockCategoryNames: ["Social Networking", "Games", "Entertainment"],
        blockedWebsites: [
            "reddit.com", "facebook.com", "twitter.com", "x.com",
            "tiktok.com", "instagram.com", "youtube.com", "twitch.tv",
        ],
        contentFilterPresetIDs: ["youtube_focus", "instagram_focus", "twitter_focus"],
        blockAppStore: true,
        blockAppDeletion: true,
        blockYouTubeNativeApp: true,
        dailyExtensionCapMinutes: 15
    )
}
