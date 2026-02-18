import Foundation
#if canImport(SafariServices)
import SafariServices
#endif

final class ContentBlockerService {

    private static var rulesFileURL: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: Constants.appGroupID)?
            .appendingPathComponent(Constants.contentBlockerRulesFileName)
    }

    // MARK: - Public API

    static func applyWebsiteBlocks(for domains: [String]) {
        let validDomains = domains.compactMap(sanitizeDomain).filter { !$0.isEmpty }
        let rules = generateRules(for: validDomains)
        writeRules(rules)
        reloadContentBlocker()
    }

    static func clearWebsiteBlocks() {
        writeRules(noOpRules)
        reloadContentBlocker()
    }

    // MARK: - Domain Validation

    private static func sanitizeDomain(_ raw: String) -> String? {
        let domain = raw
            .trimmingCharacters(in: .whitespaces)
            .lowercased()

        guard !domain.isEmpty,
              domain.contains("."),
              !domain.hasPrefix("."),
              !domain.hasSuffix(".") else {
            return nil
        }
        return domain
    }

    // MARK: - Rule Generation

    private static func generateRules(for domains: [String]) -> [[String: Any]] {
        guard !domains.isEmpty else { return noOpRules }

        return domains.map { domain in
            let escaped = escapeForRegex(domain)
            return [
                "trigger": ["url-filter": ".*\\\\.?\(escaped)"],
                "action": ["type": "block"]
            ] as [String: Any]
        }
    }

    private static func escapeForRegex(_ domain: String) -> String {
        var result = domain
        for char in ["\\", ".", "+", "*", "?", "[", "]", "(", ")", "{", "}", "^", "$", "|"] {
            result = result.replacingOccurrences(of: char, with: "\\\\\(char)")
        }
        return result
    }

    private static let noOpRules: [[String: Any]] = [
        [
            "trigger": ["url-filter": "fokusphone-placeholder-will-not-match-anything\\.example"],
            "action": ["type": "block"]
        ]
    ]

    // MARK: - File I/O

    private static func writeRules(_ rules: [[String: Any]]) {
        guard let fileURL = rulesFileURL else { return }
        do {
            let data = try JSONSerialization.data(withJSONObject: rules)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("ContentBlockerService: Failed to write rules: \(error)")
        }
    }

    // MARK: - Reload

    static func reloadContentBlocker() {
        #if canImport(SafariServices)
        SFContentBlockerManager.reloadContentBlocker(
            withIdentifier: Constants.contentBlockerBundleID
        ) { error in
            if let error = error {
                print("ContentBlockerService: Failed to reload: \(error)")
            }
        }
        #endif
    }
}
