import Foundation

// MARK: - Enhanced Profile

struct EnhancedProfile: Identifiable {
    let id: String
    let name: String
    let icon: String
    let description: String
    let stays: [String]      // "What stays" summary
    let goes: [String]       // "What goes" summary
    let presetID: String     // maps to RestrictionPresets
    let hourlyLimitApps: [String]   // bundle IDs for HourlyTimerService
    let browserFilters: Set<ContentFilterProfile>
    let allowsExtensions: Bool
    let dailyExtensionCap: Int
    let sensitivityLevel: ProfileSensitivity
}

enum ProfileSensitivity {
    case standard    // normal RawDog tone
    case supportive  // gentler, used for porn recovery
}

// MARK: - Prebuilt Profiles

enum PrebuiltProfiles {

    static let all: [EnhancedProfile] = [
        youtubeAddict,
        instagramAddict,
        socialMediaDetox,
        pornRecovery,
        deepFocus,
        digitalMinimalist,
    ]

    static func profile(for id: String) -> EnhancedProfile? {
        all.first { $0.id == id }
    }

    // MARK: - YouTube Addict

    static let youtubeAddict = EnhancedProfile(
        id: "youtube_addict",
        name: "YouTube Addict",
        icon: "play.rectangle.fill",
        description: "You lose hours to YouTube. We strip everything addictive, keep what's useful.",
        stays: ["Search bar", "Subscriptions", "Video player", "Comments"],
        goes: ["Thumbnails", "Shorts", "Recommendations", "Autoplay", "Home feed"],
        presetID: "doom_scrolling_recovery",
        hourlyLimitApps: ["com.google.ios.youtube"],
        browserFilters: [.youtubeAddict],
        allowsExtensions: true,
        dailyExtensionCap: 30,
        sensitivityLevel: .standard
    )

    // MARK: - Instagram Addict

    static let instagramAddict = EnhancedProfile(
        id: "instagram_addict",
        name: "Instagram Addict",
        icon: "camera.fill",
        description: "Instagram's algorithm is designed to trap you. We break the trap.",
        stays: ["Following feed", "DMs", "Search", "Profile viewing"],
        goes: ["Explore", "Reels", "Suggested content", "Stories from strangers", "Shop"],
        presetID: "social_media_addict",
        hourlyLimitApps: ["com.burbn.instagram"],
        browserFilters: [.instagramAddict],
        allowsExtensions: true,
        dailyExtensionCap: 30,
        sensitivityLevel: .standard
    )

    // MARK: - Social Media Detox

    static let socialMediaDetox = EnhancedProfile(
        id: "social_media_detox",
        name: "Social Media Detox",
        icon: "bubble.left.and.bubble.right.fill",
        description: "All of them. At once. 5 minutes per hour each.",
        stays: ["DMs on each platform", "Search", "Following feeds only"],
        goes: ["All algorithmic content", "Explore/discover", "Shorts/reels", "Trending"],
        presetID: "social_media_addict",
        hourlyLimitApps: [
            "com.burbn.instagram",
            "com.atebits.Tweetie2",
            "com.zhiliaoapp.musically",
            "com.toyopagroup.picaboo",
            "com.reddit.Reddit",
            "com.google.ios.youtube",
        ],
        browserFilters: [.socialMediaDetox],
        allowsExtensions: true,
        dailyExtensionCap: 15,
        sensitivityLevel: .standard
    )

    // MARK: - Porn Recovery

    static let pornRecovery = EnhancedProfile(
        id: "porn_recovery",
        name: "Clean Mind",
        icon: "shield.checkered",
        description: "No judgment. Just a clean start. Permanent blocks, no extensions.",
        stays: ["All safe browsing", "Safe search enforced", "Normal app usage"],
        goes: ["All adult content domains", "Explicit search results", "NSFW subreddits"],
        presetID: "porn_addiction_recovery",
        hourlyLimitApps: [],
        browserFilters: [.pornRecovery],
        allowsExtensions: false,
        dailyExtensionCap: 0,
        sensitivityLevel: .supportive
    )

    // MARK: - Deep Focus

    static let deepFocus = EnhancedProfile(
        id: "deep_focus",
        name: "Deep Focus",
        icon: "brain.head.profile.fill",
        description: "All social media blocked during commitment windows. 5min/hour during breaks.",
        stays: ["Calendar", "Health", "Workout apps", "Productivity tools"],
        goes: ["All social media during focus", "Browser distractions", "News feeds"],
        presetID: "work_from_home_focus",
        hourlyLimitApps: [
            "com.burbn.instagram",
            "com.atebits.Tweetie2",
            "com.zhiliaoapp.musically",
            "com.google.ios.youtube",
            "com.reddit.Reddit",
        ],
        browserFilters: [.youtubeAddict, .instagramAddict, .twitterAddict],
        allowsExtensions: true,
        dailyExtensionCap: 20,
        sensitivityLevel: .standard
    )

    // MARK: - Digital Minimalist

    static let digitalMinimalist = EnhancedProfile(
        id: "digital_minimalist_v2",
        name: "Digital Minimalist",
        icon: "leaf.fill",
        description: "Phone as a tool, not a toy. Only essentials allowed.",
        stays: ["Phone", "Messages", "Calendar", "Maps", "Health"],
        goes: ["All social media", "All entertainment", "App Store", "Games"],
        presetID: "digital_minimalist",
        hourlyLimitApps: [],  // All social permanently blocked, no hourly needed
        browserFilters: [.socialMediaDetox, .pornRecovery],
        allowsExtensions: true,
        dailyExtensionCap: 15,
        sensitivityLevel: .standard
    )
}
