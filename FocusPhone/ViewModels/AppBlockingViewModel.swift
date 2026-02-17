import SwiftUI
import FamilyControls

@MainActor
class AppBlockingViewModel: ObservableObject {
    @Published var authorizationStatus: AuthorizationStatus = .notDetermined
    @Published var activitySelection = FamilyActivitySelection()

    init() {
        loadSavedSelection()
        checkAuthorizationStatus()
    }

    func requestAuthorization() {
        Task {
            do {
                try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                authorizationStatus = .approved
            } catch {
                print("FamilyControls authorization failed: \(error)")
                authorizationStatus = .denied
            }
        }
    }

    func activateDetoxMode() {
        BlockingService.applyBlocks(using: activitySelection)
        AppState.shared.currentMode = .detox
        objectWillChange.send()
    }

    func deactivateDetoxMode() {
        BlockingService.clearAllBlocks()
        AppState.shared.currentMode = .freedom
        objectWillChange.send()
    }

    func saveSelection() {
        BlockingService.saveSelection(activitySelection)
    }

    private func loadSavedSelection() {
        if let data = Constants.sharedDefaults.data(forKey: Constants.selectedCategoriesKey),
           let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
            activitySelection = selection
        }
    }

    private func checkAuthorizationStatus() {
        // AuthorizationCenter status is checked via the shared instance
        // On app launch, if we've previously authorized, status will be .approved
        let center = AuthorizationCenter.shared
        switch center.authorizationStatus {
        case .approved:
            authorizationStatus = .approved
        case .denied:
            authorizationStatus = .denied
        case .notDetermined:
            authorizationStatus = .notDetermined
        @unknown default:
            authorizationStatus = .notDetermined
        }
    }
}
