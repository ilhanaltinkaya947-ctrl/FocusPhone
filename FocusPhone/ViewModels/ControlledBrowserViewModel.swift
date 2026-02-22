import Foundation
import Combine

@MainActor
class ControlledBrowserViewModel: ObservableObject {
    @Published var currentURL: URL?
    @Published var currentDomain: String = ""
    @Published var isLoading = false
    @Published var canGoBack = false
    @Published var canGoForward = false

    var allowedDomains: [String] {
        var domains = ["youtube.com", "m.youtube.com", "www.youtube.com"]
        // Add domains from restriction profile that have content filters (not fully blocked)
        if let profile = AppState.shared.restrictionProfile {
            for filterID in profile.browserContentFilters {
                switch filterID {
                case "youtube_focus": break // already added
                case "instagram_focus":
                    domains.append(contentsOf: ["instagram.com", "www.instagram.com"])
                case "twitter_focus":
                    domains.append(contentsOf: ["twitter.com", "x.com", "www.twitter.com", "www.x.com"])
                default: break
                }
            }
        }
        return domains
    }

    func isNavigationAllowed(to url: URL) -> Bool {
        guard let host = url.host?.lowercased() else { return false }
        return allowedDomains.contains { host == $0 || host.hasSuffix(".\($0)") }
    }

    var contentStrippingJS: String {
        var scripts: [String] = []

        // YouTube content stripping
        scripts.append(youTubeStrippingScript)

        // Add platform-specific scripts based on active content filters
        let filters = AppState.shared.restrictionProfile?.browserContentFilters ?? []
        if filters.contains("instagram_focus") {
            scripts.append(instagramStrippingScript)
        }
        if filters.contains("twitter_focus") {
            scripts.append(twitterStrippingScript)
        }

        return scripts.joined(separator: "\n\n")
    }

    // MARK: - YouTube Content Stripping

    private var youTubeStrippingScript: String {
        """
        (function() {
            'use strict';

            // CSS to inject
            const style = document.createElement('style');
            style.textContent = `
                /* Hide Shorts */
                ytm-reel-shelf-renderer,
                ytm-shorts-lockup-view-model,
                a[href*='/shorts/'],
                ytm-pivot-bar-item-renderer:has(a[href*='shorts']),
                .pivot-shorts { display: none !important; }

                /* Hide recommendations and feed */
                ytm-rich-item-renderer,
                ytm-item-section-renderer,
                ytm-video-with-context-renderer,
                .rich-grid-media,
                ytm-rich-section-renderer { display: none !important; }

                /* Hide chip filters */
                .chip-container,
                ytm-chip-cloud-renderer { display: none !important; }

                /* Hide trending */
                ytm-browse-feed-renderer { display: none !important; }
            `;
            document.head.appendChild(style);

            // Replace thumbnails with text titles
            function stripThumbnails() {
                document.querySelectorAll('ytm-media-item, ytd-rich-item-renderer').forEach(el => {
                    const title = el.querySelector('#video-title, .media-item-headline');
                    const thumb = el.querySelector('ytm-thumbnail-overlay-time-status-renderer, img.yt-core-image');
                    if (thumb && title) {
                        thumb.style.display = 'none';
                    }
                });
            }

            // Disable autoplay
            function disableAutoplay() {
                const video = document.querySelector('video');
                if (video) {
                    video.autoplay = false;
                    video.removeAttribute('autoplay');
                }
            }

            // Run periodically to catch dynamically loaded content
            stripThumbnails();
            disableAutoplay();
            const observer = new MutationObserver(() => {
                stripThumbnails();
                disableAutoplay();
            });
            observer.observe(document.body, { childList: true, subtree: true });
        })();
        """
    }

    // MARK: - Instagram Content Stripping

    private var instagramStrippingScript: String {
        """
        (function() {
            'use strict';
            const style = document.createElement('style');
            style.textContent = `
                a[href='/reels/'], a[href*='/reels'],
                a[href='/explore/'], a[href*='/explore'],
                a[href*='/reel/'],
                section:has(canvas),
                [role='presentation'] { display: none !important; }
            `;
            document.head.appendChild(style);
        })();
        """
    }

    // MARK: - Twitter Content Stripping

    private var twitterStrippingScript: String {
        """
        (function() {
            'use strict';
            const style = document.createElement('style');
            style.textContent = `
                a[href='/explore'], a[href*='/explore'],
                [data-testid='trend'],
                [data-testid='sidebarColumn'] section { display: none !important; }
            `;
            document.head.appendChild(style);
        })();
        """
    }
}
