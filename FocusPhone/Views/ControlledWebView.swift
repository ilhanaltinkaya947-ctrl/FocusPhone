import SwiftUI
import WebKit

struct ControlledWebView: UIViewRepresentable {
    let url: URL
    let contentStrippingJS: String
    let isNavigationAllowed: (URL) -> Bool
    @Binding var isLoading: Bool
    @Binding var canGoBack: Bool
    @Binding var canGoForward: Bool
    @Binding var currentURL: URL?

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()

        // Inject content stripping script at document end
        let script = WKUserScript(
            source: contentStrippingJS,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: false
        )
        config.userContentController.addUserScript(script)

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true

        // Observe loading state
        context.coordinator.observeWebView(webView)

        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        // No dynamic updates needed
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, WKNavigationDelegate {
        let parent: ControlledWebView
        private var observations: [NSKeyValueObservation] = []

        init(parent: ControlledWebView) {
            self.parent = parent
        }

        func observeWebView(_ webView: WKWebView) {
            let loadingObs = webView.observe(\.isLoading) { [weak self] webView, _ in
                DispatchQueue.main.async {
                    self?.parent.isLoading = webView.isLoading
                }
            }
            let backObs = webView.observe(\.canGoBack) { [weak self] webView, _ in
                DispatchQueue.main.async {
                    self?.parent.canGoBack = webView.canGoBack
                }
            }
            let forwardObs = webView.observe(\.canGoForward) { [weak self] webView, _ in
                DispatchQueue.main.async {
                    self?.parent.canGoForward = webView.canGoForward
                }
            }
            let urlObs = webView.observe(\.url) { [weak self] webView, _ in
                DispatchQueue.main.async {
                    self?.parent.currentURL = webView.url
                }
            }
            observations = [loadingObs, backObs, forwardObs, urlObs]
        }

        // Block navigation to non-allowed domains
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if let url = navigationAction.request.url {
                if parent.isNavigationAllowed(url) {
                    decisionHandler(.allow)
                } else {
                    decisionHandler(.cancel)
                }
            } else {
                decisionHandler(.allow)
            }
        }

        // Re-inject content stripping after navigation
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            webView.evaluateJavaScript(parent.contentStrippingJS, completionHandler: nil)
        }
    }
}
