import Foundation

enum ContentFilterPresetStore {

    static let allPresets: [ContentFilterPreset] = [
        youTubeFocus,
        instagramFocus,
        twitterFocus,
    ]

    static func preset(for id: String) -> ContentFilterPreset? {
        allPresets.first { $0.id == id }
    }

    /// Combines CSS hide rules into a JavaScript injection string for the controlled browser.
    static func browserInjectionScript(for presetIDs: Set<String>) -> String {
        var selectors: [String] = []
        for presetID in presetIDs {
            guard let preset = preset(for: presetID) else { continue }
            for rule in preset.cssHideRules {
                selectors.append(rule.selector)
            }
        }
        guard !selectors.isEmpty else { return "" }
        let css = selectors.map { "\($0) { display: none !important; }" }.joined(separator: "\n")
        return """
        (function() {
            const style = document.createElement('style');
            style.textContent = `\(css)`;
            document.head.appendChild(style);
        })();
        """
    }

    // MARK: - YouTube Focus

    static let youTubeFocus = ContentFilterPreset(
        id: "youtube_focus",
        displayName: "YouTube Focus",
        icon: "play.rectangle",
        description: "Use YouTube but hide Shorts, trending, and recommendations",
        urlBlockPatterns: [
            URLBlockPattern(
                urlFilter: "youtube\\.com/shorts",
                ifDomain: ["*youtube.com"]
            ),
            URLBlockPattern(
                urlFilter: "youtube\\.com/feed/trending",
                ifDomain: ["*youtube.com"]
            ),
        ],
        cssHideRules: [
            CSSHideRule(
                selector: "ytm-reel-shelf-renderer, ytm-shorts-lockup-view-model, a[href*='/shorts/']",
                urlFilter: ".*youtube\\.com",
                ifDomain: ["*youtube.com"]
            ),
            CSSHideRule(
                selector: "ytm-pivot-bar-item-renderer:has(a[href*='shorts']), .pivot-shorts",
                urlFilter: ".*youtube\\.com",
                ifDomain: ["*youtube.com"]
            ),
            CSSHideRule(
                selector: ".chip-container, ytm-chip-cloud-renderer",
                urlFilter: ".*youtube\\.com",
                ifDomain: ["*youtube.com"]
            ),
            // Hide video recommendation cards, thumbnails, and feed content
            CSSHideRule(
                selector: "ytm-rich-item-renderer, ytm-item-section-renderer, ytm-video-with-context-renderer",
                urlFilter: ".*youtube\\.com",
                ifDomain: ["*youtube.com"]
            ),
            CSSHideRule(
                selector: ".rich-grid-media, ytm-rich-section-renderer, ytm-browse-feed-renderer .item",
                urlFilter: ".*youtube\\.com",
                ifDomain: ["*youtube.com"]
            ),
        ]
    )

    // MARK: - Instagram Focus

    static let instagramFocus = ContentFilterPreset(
        id: "instagram_focus",
        displayName: "Instagram Focus",
        icon: "camera",
        description: "Use Instagram but hide Reels, Explore, and Stories",
        urlBlockPatterns: [
            URLBlockPattern(
                urlFilter: "instagram\\.com/reels",
                ifDomain: ["*instagram.com"]
            ),
            URLBlockPattern(
                urlFilter: "instagram\\.com/explore",
                ifDomain: ["*instagram.com"]
            ),
            // Block individual reel links (opened from DMs)
            URLBlockPattern(
                urlFilter: "instagram\\.com/reel/",
                ifDomain: ["*instagram.com"]
            ),
        ],
        cssHideRules: [
            CSSHideRule(
                selector: "a[href='/reels/'], a[href*='/reels']",
                urlFilter: ".*instagram\\.com",
                ifDomain: ["*instagram.com"]
            ),
            CSSHideRule(
                selector: "a[href='/explore/'], a[href*='/explore']",
                urlFilter: ".*instagram\\.com",
                ifDomain: ["*instagram.com"]
            ),
            // Story tray (structural selectors — stable against class obfuscation)
            CSSHideRule(
                selector: "section:has(canvas), header + section:first-of-type",
                urlFilter: ".*instagram\\.com",
                ifDomain: ["*instagram.com"]
            ),
            // Story modal overlay
            CSSHideRule(
                selector: "[role='presentation']",
                urlFilter: ".*instagram\\.com/stories",
                ifDomain: ["*instagram.com"]
            ),
            // Reel embeds in DMs
            CSSHideRule(
                selector: "a[href*='/reel/']",
                urlFilter: ".*instagram\\.com/direct",
                ifDomain: ["*instagram.com"]
            ),
        ]
    )

    // MARK: - Twitter/X Focus

    static let twitterFocus = ContentFilterPreset(
        id: "twitter_focus",
        displayName: "Twitter/X Focus",
        icon: "bubble.left",
        description: "Use Twitter but hide Explore, trending, and recommendations",
        urlBlockPatterns: [
            URLBlockPattern(
                urlFilter: "(twitter|x)\\.com/explore",
                ifDomain: ["*twitter.com", "*x.com"]
            ),
            URLBlockPattern(
                urlFilter: "(twitter|x)\\.com/i/trends",
                ifDomain: ["*twitter.com", "*x.com"]
            ),
        ],
        cssHideRules: [
            CSSHideRule(
                selector: "a[href='/explore'], a[href*='/explore']",
                urlFilter: ".*(twitter|x)\\.com",
                ifDomain: ["*twitter.com", "*x.com"]
            ),
            CSSHideRule(
                selector: "[data-testid='trend'], [data-testid='sidebarColumn'] section",
                urlFilter: ".*(twitter|x)\\.com",
                ifDomain: ["*twitter.com", "*x.com"]
            ),
        ]
    )
}
