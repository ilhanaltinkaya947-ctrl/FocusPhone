import Foundation

// MARK: - Hourly Usage Model

struct HourlyUsage: Codable, Equatable {
    let bundleID: String
    var hourStart: Date    // floored to :00
    var secondsUsed: Int
    var limit: Int         // default 300 = 5 minutes
    var extended: Bool
    var extensionGrantedSeconds: Int  // 0-600 max

    var totalAllowedSeconds: Int {
        limit + extensionGrantedSeconds
    }

    var remainingSeconds: Int {
        max(0, totalAllowedSeconds - secondsUsed)
    }

    var isLimitReached: Bool {
        secondsUsed >= totalAllowedSeconds
    }

    var isInCurrentHour: Bool {
        let hourFloor = Calendar.current.date(bySetting: .minute, value: 0, of: Date()) ?? Date()
        return hourStart >= hourFloor
    }
}

// MARK: - Extension Result

enum ExtensionResult {
    case approved(seconds: Int)
    case denied(reason: String)
}

// MARK: - Hourly Timer Service

final class HourlyTimerService {
    static let shared = HourlyTimerService()

    private static let usageKey = "hourlyUsageData"
    private static let extensionCountKey = "hourlyExtensionCounts"

    /// Default limit per app per hour (5 minutes)
    static let defaultLimitSeconds = 300

    /// Max extension per hour (10 additional minutes)
    static let maxExtensionSeconds = 600

    /// Max extension requests per app per day
    static let maxDailyExtensionRequests = 2

    /// Apps tracked by the hourly system
    static let trackedApps: [String: String] = [
        "com.google.ios.youtube": "YouTube",
        "com.burbn.instagram": "Instagram",
        "com.atebits.Tweetie2": "Twitter/X",
        "com.zhiliaoapp.musically": "TikTok",
        "com.reddit.Reddit": "Reddit",
        "com.toyopagroup.picaboo": "Snapchat",
    ]

    // MARK: - Usage Tracking

    private var usageCache: [String: HourlyUsage] = [:]

    func startTracking() {
        resetIfNewHour()
    }

    func resetIfNewHour() {
        let hourFloor = floorToHour(Date())

        for (bundleID, _) in Self.trackedApps {
            if let existing = getUsage(bundleID: bundleID) {
                if existing.hourStart < hourFloor {
                    // New hour — reset
                    let fresh = HourlyUsage(
                        bundleID: bundleID,
                        hourStart: hourFloor,
                        secondsUsed: 0,
                        limit: Self.defaultLimitSeconds,
                        extended: false,
                        extensionGrantedSeconds: 0
                    )
                    setUsage(fresh)
                }
            }
        }
    }

    func recordUsage(bundleID: String, seconds: Int) {
        resetIfNewHour()

        var usage = getOrCreateUsage(bundleID: bundleID)
        usage.secondsUsed += seconds
        setUsage(usage)

        // Check if limit just reached
        if usage.isLimitReached {
            let appName = Self.trackedApps[bundleID] ?? bundleID
            let remaining = minutesUntilNextHour()

            let content = UNMutableNotificationContent()
            content.title = "RawDog"
            content.body = "your 5 minutes on \(appName) is up. next window opens in \(remaining) min. 🐕"
            content.sound = .default

            let request = UNNotificationRequest(
                identifier: "hourly_limit_\(bundleID)",
                content: content,
                trigger: nil
            )
            UNUserNotificationCenter.current().add(request)
        }
    }

    func getRemainingSeconds(bundleID: String) -> Int {
        resetIfNewHour()
        return getOrCreateUsage(bundleID: bundleID).remainingSeconds
    }

    func isLimitReached(bundleID: String) -> Bool {
        resetIfNewHour()
        return getOrCreateUsage(bundleID: bundleID).isLimitReached
    }

    // MARK: - Extension Requests

    func requestExtension(bundleID: String, reason: String) async -> ExtensionResult {
        let appName = Self.trackedApps[bundleID] ?? bundleID

        // Check daily extension request count
        let todayCount = getTodayExtensionCount(bundleID: bundleID)
        guard todayCount < Self.maxDailyExtensionRequests else {
            return .denied(reason: "you've used both extension requests for \(appName) today. try again tomorrow.")
        }

        // Check reason length
        guard reason.count >= 20 else {
            return .denied(reason: "give me a real reason. at least 20 characters.")
        }

        // AI evaluation
        do {
            let response = try await AIService.shared.evaluateExtensionRequest(
                appName: appName,
                reason: reason,
                requestedMinutes: 10,
                dailyUsed: AppState.shared.dailyExtensionMinutesUsed,
                dailyCap: AppState.shared.restrictionProfile?.dailyExtensionCapMinutes ?? 30
            )

            if response {
                // Grant extension
                var usage = getOrCreateUsage(bundleID: bundleID)
                usage.extended = true
                usage.extensionGrantedSeconds = min(Self.maxExtensionSeconds, usage.extensionGrantedSeconds + 600)
                setUsage(usage)
                incrementTodayExtensionCount(bundleID: bundleID)

                return .approved(seconds: 600)
            } else {
                return .denied(reason: "request denied by AI. try again next hour.")
            }
        } catch {
            return .denied(reason: "couldn't process request. blocked until next hour.")
        }
    }

    // MARK: - Free Time Check

    func isInFreeTimeBlock() -> Bool {
        // TODO: Check CalendarService for current free time blocks
        // For now, always return false (hourly limits always active)
        return false
    }

    // MARK: - Private Helpers

    private func getUsage(bundleID: String) -> HourlyUsage? {
        if let cached = usageCache[bundleID] {
            return cached
        }
        let all: [String: HourlyUsage]? = AppState.shared.load(forKey: Self.usageKey)
        return all?[bundleID]
    }

    private func getOrCreateUsage(bundleID: String) -> HourlyUsage {
        if let existing = getUsage(bundleID: bundleID), existing.isInCurrentHour {
            return existing
        }
        return HourlyUsage(
            bundleID: bundleID,
            hourStart: floorToHour(Date()),
            secondsUsed: 0,
            limit: Self.defaultLimitSeconds,
            extended: false,
            extensionGrantedSeconds: 0
        )
    }

    private func setUsage(_ usage: HourlyUsage) {
        usageCache[usage.bundleID] = usage
        var all: [String: HourlyUsage] = AppState.shared.load(forKey: Self.usageKey) ?? [:]
        all[usage.bundleID] = usage
        AppState.shared.save(all, forKey: Self.usageKey)
    }

    private func floorToHour(_ date: Date) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour], from: date)
        return calendar.date(from: components) ?? date
    }

    private func minutesUntilNextHour() -> Int {
        let minute = Calendar.current.component(.minute, from: Date())
        return 60 - minute
    }

    // MARK: - Daily Extension Count

    private func getTodayExtensionCount(bundleID: String) -> Int {
        let key = "\(Self.extensionCountKey)_\(bundleID)"
        let stored: [String: Int]? = AppState.shared.load(forKey: key)
        let today = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none)
        return stored?[today] ?? 0
    }

    private func incrementTodayExtensionCount(bundleID: String) {
        let key = "\(Self.extensionCountKey)_\(bundleID)"
        var stored: [String: Int] = AppState.shared.load(forKey: key) ?? [:]
        let today = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none)
        stored[today] = (stored[today] ?? 0) + 1
        // Keep only today's entry
        stored = stored.filter { $0.key == today }
        AppState.shared.save(stored, forKey: key)
    }
}

// MARK: - Import for notifications

import UserNotifications
