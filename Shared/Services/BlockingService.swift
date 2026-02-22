import Foundation
import ManagedSettings
import FamilyControls

final class BlockingService {
    static let store = ManagedSettingsStore()

    /// Apply permanent blocks from a restriction profile (categories, apps, App Store, websites).
    static func applyPermanentBlocks(from profile: PersonalRestrictionProfile) {
        // Category blocking
        if let catData = profile.permanentBlockCategories,
           let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: catData) {
            let categories = selection.categoryTokens
            store.shield.applicationCategories = categories.isEmpty ? nil : .specific(categories)
        }

        // App blocking (permanent + YouTube native if flagged)
        if let appData = profile.permanentBlockApps,
           let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: appData) {
            let applications = selection.applicationTokens
            store.shield.applications = applications.isEmpty ? nil : applications
        }

        // Also block timed window apps (they get unblocked during windows)
        var allBlockedApps = store.shield.applications ?? Set()
        for app in profile.timedWindowApps {
            if let tokenData = app.appToken,
               let token = try? JSONDecoder().decode(ApplicationToken.self, from: tokenData) {
                allBlockedApps.insert(token)
            }
        }
        store.shield.applications = allBlockedApps.isEmpty ? nil : allBlockedApps

        store.application.denyAppInstallation = profile.blockAppStore
        store.application.denyAppRemoval = profile.blockAppDeletion

        // Website blocking via Safari Content Blocker
        do {
            try ContentBlockerService.applyAllRules(
                domainBlocks: profile.blockedWebsites,
                enabledPresets: Set(profile.activePresetIDs)
            )
        } catch {
            print("BlockingService: Content blocker error: \(error.localizedDescription)")
        }
    }

    /// Temporarily unblock a specific app (for timed window or extension).
    static func unblockApp(token: Data) {
        guard let appToken = try? JSONDecoder().decode(ApplicationToken.self, from: token) else { return }
        var applications = store.shield.applications ?? Set()
        applications.remove(appToken)
        store.shield.applications = applications.isEmpty ? nil : applications
    }

    /// Re-block a specific app after a timed window or extension ends.
    static func reblockApp(token: Data) {
        guard let appToken = try? JSONDecoder().decode(ApplicationToken.self, from: token) else { return }
        var applications = store.shield.applications ?? Set()
        applications.insert(appToken)
        store.shield.applications = applications
    }

    /// Clear all blocks.
    static func clearAllBlocks() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.application.denyAppInstallation = false
        store.application.denyAppRemoval = false
        ContentBlockerService.clearWebsiteBlocks()
    }
}
