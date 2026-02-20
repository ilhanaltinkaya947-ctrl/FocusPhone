import Foundation
#if canImport(SafariServices)
import SafariServices
#endif

enum ContentBlockerError: Error, LocalizedError {
    case noAppGroupContainer
    case writeFailure(Error)
    case reloadFailure(Error)

    var errorDescription: String? {
        switch self {
        case .noAppGroupContainer: return "Cannot access App Group container for content blocker."
        case .writeFailure(let error): return "Failed to write blocker rules: \(error.localizedDescription)"
        case .reloadFailure(let error): return "Failed to reload content blocker: \(error.localizedDescription)"
        }
    }
}

final class ContentBlockerService {

    private static var rulesFileURL: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: Constants.appGroupID)?
            .appendingPathComponent(Constants.contentBlockerRulesFileName)
    }

    // MARK: - Public API

    static func applyWebsiteBlocks(for domains: [String]) throws {
        let validDomains = domains.compactMap(sanitizeDomain).filter { !$0.isEmpty }
        let rules = generateRules(for: validDomains)
        try writeRules(rules)
        reloadContentBlocker()
    }

    static func clearWebsiteBlocks() {
        try? writeRules(noOpRules)
        reloadContentBlocker()
    }

    /// Checks that the rules file exists in the App Group container
    static func verifyContentBlocker() -> Bool {
        guard let fileURL = rulesFileURL else { return false }
        return FileManager.default.fileExists(atPath: fileURL.path)
    }

    // MARK: - Domain Validation

    private static func sanitizeDomain(_ raw: String) -> String? {
        var domain = raw
            .trimmingCharacters(in: .whitespaces)
            .lowercased()

        // Strip protocol prefixes
        for prefix in ["https://", "http://"] {
            if domain.hasPrefix(prefix) {
                domain = String(domain.dropFirst(prefix.count))
            }
        }

        // Strip www. prefix
        if domain.hasPrefix("www.") {
            domain = String(domain.dropFirst(4))
        }

        // Strip trailing paths, query strings, fragments, and ports
        if let slashIndex = domain.firstIndex(of: "/") {
            domain = String(domain[..<slashIndex])
        }
        if let colonIndex = domain.firstIndex(of: ":") {
            domain = String(domain[..<colonIndex])
        }

        // Validate: only alphanumeric, hyphens, dots allowed
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-."))
        guard !domain.isEmpty,
              domain.unicodeScalars.allSatisfy({ allowed.contains($0) }),
              domain.contains("."),
              !domain.hasPrefix("."),
              !domain.hasSuffix("."),
              !domain.hasPrefix("-") else {
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
                "trigger": ["url-filter": ".*[./]\(escaped)"],
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

    private static func writeRules(_ rules: [[String: Any]]) throws {
        guard let fileURL = rulesFileURL else {
            throw ContentBlockerError.noAppGroupContainer
        }
        do {
            let data = try JSONSerialization.data(withJSONObject: rules)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            throw ContentBlockerError.writeFailure(error)
        }
    }

    // MARK: - Reload

    static func reloadContentBlocker(completion: ((Error?) -> Void)? = nil) {
        #if canImport(SafariServices)
        SFContentBlockerManager.reloadContentBlocker(
            withIdentifier: Constants.contentBlockerBundleID
        ) { error in
            if let error = error {
                print("ContentBlockerService: Failed to reload: \(error)")
            }
            completion?(error)
        }
        #else
        completion?(nil)
        #endif
    }
}
