import SwiftUI

struct ControlledBrowserView: View {
    @StateObject private var viewModel = ControlledBrowserViewModel()
    @State private var webViewID = UUID() // for force-refreshing

    private let defaultURL = URL(string: "https://m.youtube.com")!

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Domain bar
                HStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(.green)

                    Text(viewModel.currentURL?.host ?? "youtube.com")
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Spacer()

                    if viewModel.isLoading {
                        ProgressView()
                            .controlSize(.small)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))

                // WebView
                ControlledWebView(
                    url: defaultURL,
                    contentStrippingJS: viewModel.contentStrippingJS,
                    isNavigationAllowed: { viewModel.isNavigationAllowed(to: $0) },
                    isLoading: $viewModel.isLoading,
                    canGoBack: $viewModel.canGoBack,
                    canGoForward: $viewModel.canGoForward,
                    currentURL: $viewModel.currentURL
                )
                .id(webViewID)
            }
            .navigationTitle("Browser")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    // Quick navigation buttons
                    ForEach(quickLinks, id: \.label) { link in
                        Button {
                            viewModel.currentURL = link.url
                            webViewID = UUID()
                        } label: {
                            VStack(spacing: 2) {
                                Image(systemName: link.icon)
                                    .font(.caption)
                                Text(link.label)
                                    .font(.caption2)
                            }
                        }
                    }
                }
            }
        }
    }

    private struct QuickLink {
        let label: String
        let icon: String
        let url: URL
    }

    private var quickLinks: [QuickLink] {
        var links: [QuickLink] = [
            QuickLink(label: "YouTube", icon: "play.rectangle", url: URL(string: "https://m.youtube.com")!),
        ]

        let filters = AppState.shared.restrictionProfile?.browserContentFilters ?? []
        if filters.contains("instagram_focus") {
            links.append(QuickLink(label: "Instagram", icon: "camera", url: URL(string: "https://www.instagram.com")!))
        }
        if filters.contains("twitter_focus") {
            links.append(QuickLink(label: "Twitter", icon: "bubble.left", url: URL(string: "https://x.com")!))
        }

        return links
    }
}
