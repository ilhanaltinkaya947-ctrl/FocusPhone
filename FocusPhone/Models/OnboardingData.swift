import Foundation

struct OnboardingSelections {
    var age: String?           // "13-17", "18-24", "25-34", "35-44", "45+"
    var occupation: String?    // "student", "employee", "freelance", etc.
    var problems: [String] = []  // multi-select: social_media, youtube, porn, etc.
    var goals: [String] = []     // multi-select: gym, study, business, etc.
    var firstCommitment: Commitment?

    // MARK: - Map problems to preset IDs

    func presetIDs() -> [String] {
        var ids: [String] = []
        for problem in problems {
            switch problem {
            case "social_media": ids.append("social_media_addict")
            case "youtube": ids.append("doom_scrolling_recovery")
            case "porn": ids.append("porn_addiction_recovery")
            case "doom_scrolling": ids.append("doom_scrolling_recovery")
            case "gaming": ids.append("digital_minimalist")
            case "messaging": ids.append("work_from_home_focus")
            case "shopping": ids.append("digital_minimalist")
            default: break
            }
        }
        return Array(Set(ids))
    }

    // MARK: - Map goals to commitment suggestions

    func suggestedCommitments() -> [(emoji: String, title: String, category: CommitmentCategory)] {
        var suggestions: [(String, String, CommitmentCategory)] = []

        for goal in goals {
            switch goal {
            case "gym":     suggestions.append(("💪", "Hit the gym", .gym))
            case "study":   suggestions.append(("📚", "Study session", .study))
            case "business": suggestions.append(("💻", "Deep work block", .work))
            case "heal":    suggestions.append(("🧘", "Meditation", .meditation))
            case "skill":   suggestions.append(("🎯", "Skill practice", .custom))
            case "present": suggestions.append(("🌿", "Screen-free hour", .outdoor))
            case "sleep":   suggestions.append(("😴", "Lights out by 11", .custom))
            default: break
            }
        }

        if suggestions.isEmpty {
            suggestions.append(("💪", "Morning workout", .gym))
            suggestions.append(("📚", "30 min reading", .study))
            suggestions.append(("🧘", "5 min meditation", .meditation))
        }

        return suggestions
    }

    // MARK: - Map selections to PersonalRestrictionProfile

    func toProfile() -> PersonalRestrictionProfile {
        let presets = presetIDs()

        var blockedSites: [String] = []
        var contentFilters: [String] = []

        if problems.contains("porn") {
            contentFilters.append("adult_content")
            blockedSites.append(contentsOf: ["pornhub.com", "xvideos.com", "xnxx.com"])
        }
        if problems.contains("social_media") {
            blockedSites.append(contentsOf: ["twitter.com", "x.com", "instagram.com", "tiktok.com", "facebook.com"])
        }
        if problems.contains("youtube") {
            blockedSites.append("youtube.com")
        }
        if problems.contains("shopping") {
            blockedSites.append(contentsOf: ["amazon.com", "ebay.com", "aliexpress.com"])
        }

        let blockYouTube = problems.contains("youtube")

        let cap: Int
        switch age {
        case "13-17": cap = 15
        case "18-24": cap = 20
        default: cap = 30
        }

        return PersonalRestrictionProfile(
            activePresetIDs: presets,
            blockYouTubeNativeApp: blockYouTube,
            blockedWebsites: Array(Set(blockedSites)),
            browserContentFilters: contentFilters,
            blockAppStore: true,
            blockAppDeletion: true,
            dailyExtensionCapMinutes: cap,
            onboardingSummary: buildSummary()
        )
    }

    private func buildSummary() -> String {
        var parts: [String] = []
        if !problems.isEmpty {
            parts.append("Blocking: \(problems.joined(separator: ", "))")
        }
        if !goals.isEmpty {
            parts.append("Goals: \(goals.joined(separator: ", "))")
        }
        if let age = age {
            parts.append("Age: \(age)")
        }
        return parts.joined(separator: ". ")
    }

    // MARK: - Calculate "years phone will steal" for shock screen

    func yearsPhoneWillSteal() -> Int {
        let dailyHours = 4.5 // average
        let remainingYears: Double
        switch age {
        case "13-17": remainingYears = 65
        case "18-24": remainingYears = 58
        case "25-34": remainingYears = 50
        case "35-44": remainingYears = 40
        case "45+": remainingYears = 30
        default: remainingYears = 50
        }
        let totalHours = dailyHours * 365 * remainingYears
        return Int(totalHours / (24 * 365)) // convert to years
    }
}
