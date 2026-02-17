import Foundation
import ManagedSettings
import FamilyControls

final class BlockingService {
    static let store = ManagedSettingsStore()

    static func applyBlocks(using selection: FamilyActivitySelection) {
        let applications = selection.applicationTokens
        let categories = selection.categoryTokens

        store.shield.applications = applications.isEmpty ? nil : applications
        store.shield.applicationCategories = categories.isEmpty
            ? nil
            : .specific(categories)
        store.application.denyAppInstallation = true
    }

    static func applyBlocksFromStorage() {
        guard let data = Constants.sharedDefaults.data(forKey: Constants.selectedCategoriesKey),
              let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) else {
            return
        }
        applyBlocks(using: selection)
    }

    static func clearAllBlocks() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.application.denyAppInstallation = false
    }

    static func saveSelection(_ selection: FamilyActivitySelection) {
        if let data = try? JSONEncoder().encode(selection) {
            Constants.sharedDefaults.set(data, forKey: Constants.selectedCategoriesKey)
        }
    }
}
