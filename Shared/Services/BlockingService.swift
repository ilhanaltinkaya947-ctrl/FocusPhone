import Foundation
import ManagedSettings
import FamilyControls

final class BlockingService {
    static let store = ManagedSettingsStore()

    static func applyBlocks(for mode: Mode) {
        // App/category blocking
        if let selection = mode.familyActivitySelection {
            let applications = selection.applicationTokens
            let categories = selection.categoryTokens
            store.shield.applications = applications.isEmpty ? nil : applications
            store.shield.applicationCategories = categories.isEmpty ? nil : .specific(categories)
        } else {
            store.shield.applications = nil
            store.shield.applicationCategories = nil
        }

        store.application.denyAppInstallation = mode.blockAppStore
        store.application.denyAppRemoval = mode.blockAppDeletion

        // Website blocking via Safari Content Blocker (domain blocks + content filter presets)
        do {
            try ContentBlockerService.applyAllRules(
                domainBlocks: mode.blockedWebsites,
                enabledPresets: AppState.shared.enabledContentFilterPresets
            )
        } catch {
            print("BlockingService: Content blocker error: \(error.localizedDescription)")
        }
    }

    static func applyBlocksForActiveMode() {
        guard let modeID = AppState.shared.activeModeID,
              let mode = AppState.shared.mode(for: modeID) else {
            clearAllBlocks()
            return
        }
        applyBlocks(for: mode)
    }

    static func clearAllBlocks() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.application.denyAppInstallation = false
        store.application.denyAppRemoval = false
        ContentBlockerService.clearWebsiteBlocks()
    }
}
