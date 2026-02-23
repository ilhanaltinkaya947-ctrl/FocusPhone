import Foundation

// MARK: - Filter Profile

enum ContentFilterProfile: String, Codable, CaseIterable {
    case youtubeAddict = "youtube_addict"
    case instagramAddict = "instagram_addict"
    case twitterAddict = "twitter_addict"
    case pornRecovery = "porn_recovery"
    case socialMediaDetox = "social_media_detox"

    var displayName: String {
        switch self {
        case .youtubeAddict: "YouTube Filter"
        case .instagramAddict: "Instagram Filter"
        case .twitterAddict: "Twitter/X Filter"
        case .pornRecovery: "Safe Browsing"
        case .socialMediaDetox: "Social Media Filter"
        }
    }
}

// MARK: - Browser Content Filter

enum BrowserContentFilter {

    /// Returns the JS injection string for a given URL and active filter profiles
    static func jsInjection(for url: URL, profiles: Set<ContentFilterProfile>) -> String? {
        let host = url.host?.lowercased() ?? ""

        var scripts: [String] = []

        if profiles.contains(.youtubeAddict) && isYouTube(host) {
            scripts.append(youtubeFilterJS)
        }

        if profiles.contains(.instagramAddict) && isInstagram(host) {
            scripts.append(instagramFilterJS)
        }

        if profiles.contains(.twitterAddict) && isTwitter(host) {
            scripts.append(twitterFilterJS)
        }

        if profiles.contains(.pornRecovery) {
            scripts.append(safeSearchJS)
        }

        if profiles.contains(.socialMediaDetox) {
            if isYouTube(host) { scripts.append(youtubeFilterJS) }
            if isInstagram(host) { scripts.append(instagramFilterJS) }
            if isTwitter(host) { scripts.append(twitterFilterJS) }
        }

        return scripts.isEmpty ? nil : scripts.joined(separator: "\n")
    }

    // MARK: - Domain Checks

    private static func isYouTube(_ host: String) -> Bool {
        host.contains("youtube.com") || host.contains("youtu.be") || host.contains("m.youtube.com")
    }

    private static func isInstagram(_ host: String) -> Bool {
        host.contains("instagram.com")
    }

    private static func isTwitter(_ host: String) -> Bool {
        host.contains("twitter.com") || host.contains("x.com")
    }

    // MARK: - YouTube Filter JS

    static let youtubeFilterJS = """
    (function() {
        'use strict';

        const SELECTORS_TO_HIDE = [
            // Thumbnails
            'img.yt-core-image',
            'ytd-thumbnail',
            '#thumbnail',
            'ytm-media-item .media-item-thumbnail-container',

            // Shorts
            'ytd-reel-shelf-renderer',
            'ytd-shorts',
            '[is-shorts]',
            'ytm-reel-shelf-renderer',
            'a[href*="/shorts/"]',

            // Recommendations
            'ytd-watch-next-secondary-results-renderer',
            '#related',
            '#items.ytd-watch-next-secondary-results-renderer',

            // Homepage feed (keep search results)
            'ytd-rich-grid-renderer',
            'ytd-rich-item-renderer',
            'ytm-rich-grid-renderer',

            // End cards and autoplay
            '.ytp-ce-element',
            '.ytp-endscreen-content',
            '.ytp-autonav-endscreen-countdown-container',
            '#autoplay',

            // Ads
            'ytd-ad-slot-renderer',
            '.ytp-ad-module',
            '#player-ads',
            'ytd-promoted-sparkles-web-renderer',
            'ytm-promoted-sparkles-web-renderer',
        ];

        function hideElements() {
            SELECTORS_TO_HIDE.forEach(function(sel) {
                document.querySelectorAll(sel).forEach(function(el) {
                    el.style.display = 'none';
                });
            });

            // Convert video list items to text-only
            document.querySelectorAll('ytd-video-renderer, ytd-compact-video-renderer').forEach(function(el) {
                var title = el.querySelector('#video-title');
                var channel = el.querySelector('#channel-name, .ytd-channel-name');
                if (title && !el.dataset.rawdogProcessed) {
                    el.dataset.rawdogProcessed = 'true';
                    var link = title.closest('a') || title;
                    var href = link.getAttribute('href') || '';
                    var channelText = channel ? channel.textContent.trim() : '';
                    var titleText = title.textContent.trim();

                    // Replace entire renderer content with text
                    el.innerHTML = '';
                    var textRow = document.createElement('a');
                    textRow.href = href;
                    textRow.style.cssText = 'display:block;padding:8px 16px;color:white;text-decoration:none;font-size:14px;border-bottom:1px solid #333;';
                    textRow.textContent = channelText ? '[' + channelText + '] — ' + titleText : titleText;
                    el.appendChild(textRow);
                }
            });
        }

        // Run immediately and observe mutations
        hideElements();
        var observer = new MutationObserver(hideElements);
        observer.observe(document.body || document.documentElement, {
            childList: true,
            subtree: true
        });
    })();
    """

    // MARK: - Instagram Filter JS

    static let instagramFilterJS = """
    (function() {
        'use strict';

        const SELECTORS_TO_HIDE = [
            // Explore tab
            'a[href="/explore/"]',
            'a[href="/explore"]',

            // Reels tab
            'a[href="/reels/"]',
            'a[href="/reels"]',

            // Shop tab
            'a[href="/shop/"]',

            // Suggested posts in feed
            '[data-testid="suggested-post"]',
            'article:has(span:contains("Suggested"))',

            // Suggested accounts
            '[data-testid="suggested-users"]',

            // Stories from non-followed (suggested stories)
            '[data-testid="suggested-stories"]',
        ];

        function hideElements() {
            SELECTORS_TO_HIDE.forEach(function(sel) {
                try {
                    document.querySelectorAll(sel).forEach(function(el) {
                        el.style.display = 'none';
                    });
                } catch(e) {}
            });

            // Hide "Suggested for you" sections by text content
            document.querySelectorAll('span, div').forEach(function(el) {
                var text = el.textContent.trim();
                if (text === 'Suggested for you' || text === 'Suggested Posts') {
                    var container = el.closest('div[style]') || el.parentElement?.parentElement;
                    if (container) container.style.display = 'none';
                }
            });
        }

        hideElements();
        var observer = new MutationObserver(hideElements);
        observer.observe(document.body || document.documentElement, {
            childList: true,
            subtree: true
        });
    })();
    """

    // MARK: - Twitter/X Filter JS

    static let twitterFilterJS = """
    (function() {
        'use strict';

        const SELECTORS_TO_HIDE = [
            // Trending / What's happening
            '[data-testid="trend"]',
            'div[aria-label="Timeline: Trending now"]',
            'aside[aria-label="Trending"]',

            // Who to follow / Suggested accounts
            'aside[aria-label="Who to follow"]',
            '[data-testid="UserCell"]:not([data-testid="conversation"])',

            // Promoted tweets
            '[data-testid="placementTracking"]',
            'div:has(> span:contains("Promoted"))',
            'div:has(> span:contains("Ad"))',
        ];

        function hideElements() {
            SELECTORS_TO_HIDE.forEach(function(sel) {
                try {
                    document.querySelectorAll(sel).forEach(function(el) {
                        el.style.display = 'none';
                    });
                } catch(e) {}
            });

            // Force "Following" tab instead of "For You"
            var forYouTab = document.querySelector('a[href="/home"][role="tab"][aria-selected="true"]');
            var followingTab = document.querySelector('a[href="/home/following"][role="tab"]');
            if (forYouTab && followingTab && !followingTab.getAttribute('aria-selected')) {
                followingTab.click();
            }
        }

        hideElements();
        var observer = new MutationObserver(hideElements);
        observer.observe(document.body || document.documentElement, {
            childList: true,
            subtree: true
        });
    })();
    """

    // MARK: - Safe Search Enforcement JS

    static let safeSearchJS = """
    (function() {
        'use strict';
        var url = window.location.href;

        // Google safe search
        if (url.includes('google.com/search') && !url.includes('safe=active')) {
            var sep = url.includes('?') ? '&' : '?';
            window.location.replace(url + sep + 'safe=active');
        }

        // Bing safe search
        if (url.includes('bing.com/search') && !url.includes('adlt=strict')) {
            var sep = url.includes('?') ? '&' : '?';
            window.location.replace(url + sep + 'adlt=strict');
        }

        // DuckDuckGo safe search
        if (url.includes('duckduckgo.com') && !url.includes('kp=1')) {
            var sep = url.includes('?') ? '&' : '?';
            window.location.replace(url + sep + 'kp=1');
        }
    })();
    """

    // MARK: - Blocked Porn Domains

    static let blockedAdultDomains: [String] = [
        "pornhub.com", "xvideos.com", "xhamster.com", "xnxx.com",
        "redtube.com", "youporn.com", "tube8.com", "spankbang.com",
        "eporner.com", "beeg.com", "onlyfans.com", "fansly.com",
        "chaturbate.com", "livejasmin.com", "stripchat.com",
        "brazzers.com", "realitykings.com", "bangbros.com",
        "naughtyamerica.com", "blacked.com", "tushy.com",
        "rule34.xxx", "nhentai.net", "hanime.tv", "hentaihaven.xxx",
    ]
}
