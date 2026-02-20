import Foundation
import CryptoKit

enum AIResponseCache {
    private static let cacheKey = "aiResponseCache"
    private static let ttlSeconds: TimeInterval = 7 * 24 * 60 * 60 // 7 days
    private static let maxEntries = 50
    private static let defaults = Constants.sharedDefaults

    private struct CacheEntry: Codable {
        let value: String
        let timestamp: Date
    }

    static func get(for prompt: String, modeContext: [String] = []) -> String? {
        guard let cache = loadCache() else { return nil }
        let key = hash(prompt, modeContext: modeContext)

        guard let entry = cache[key] else { return nil }
        guard Date().timeIntervalSince(entry.timestamp) < ttlSeconds else {
            var updated = cache
            updated.removeValue(forKey: key)
            saveCache(updated)
            return nil
        }
        return entry.value
    }

    static func set(_ value: String, for prompt: String, modeContext: [String] = []) {
        var cache = loadCache() ?? [:]
        let key = hash(prompt, modeContext: modeContext)
        cache[key] = CacheEntry(value: value, timestamp: Date())

        // Evict oldest entries if over max
        if cache.count > maxEntries {
            let sorted = cache.sorted { $0.value.timestamp < $1.value.timestamp }
            let toRemove = cache.count - maxEntries
            for entry in sorted.prefix(toRemove) {
                cache.removeValue(forKey: entry.key)
            }
        }

        saveCache(cache)
    }

    static func clear() {
        defaults.removeObject(forKey: cacheKey)
    }

    /// Hash includes both the prompt and mode names so mode changes invalidate cache
    static func hash(_ input: String, modeContext: [String] = []) -> String {
        let combined = input + "|modes:" + modeContext.sorted().joined(separator: ",")
        let data = Data(combined.utf8)
        let digest = SHA256.hash(data: data)
        return digest.prefix(16).map { String(format: "%02x", $0) }.joined()
    }

    // MARK: - Private

    private static func loadCache() -> [String: CacheEntry]? {
        guard let data = defaults.data(forKey: cacheKey) else { return nil }
        return try? JSONDecoder().decode([String: CacheEntry].self, from: data)
    }

    private static func saveCache(_ cache: [String: CacheEntry]) {
        if let data = try? JSONEncoder().encode(cache) {
            defaults.set(data, forKey: cacheKey)
        }
    }
}
