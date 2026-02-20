import Foundation

struct ContentFilterPreset: Identifiable {
    let id: String
    let displayName: String
    let icon: String
    let description: String
    let urlBlockPatterns: [URLBlockPattern]
    let cssHideRules: [CSSHideRule]
}

struct URLBlockPattern {
    let urlFilter: String       // regex
    let ifDomain: [String]      // only apply on these domains
}

struct CSSHideRule {
    let selector: String
    let urlFilter: String       // regex matching page URL
    let ifDomain: [String]
}
