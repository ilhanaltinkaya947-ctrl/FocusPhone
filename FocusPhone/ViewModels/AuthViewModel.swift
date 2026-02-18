import SwiftUI
import FamilyControls
import SafariServices

@MainActor
class AuthViewModel: ObservableObject {
    @Published var authorizationStatus: AuthorizationStatus = .notDetermined
    @Published var contentBlockerEnabled = false

    init() {
        checkAuthorizationStatus()
        checkContentBlockerState()
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

    func checkContentBlockerState() {
        SFContentBlockerManager.getStateOfContentBlocker(
            withIdentifier: Constants.contentBlockerBundleID
        ) { state, error in
            DispatchQueue.main.async {
                self.contentBlockerEnabled = state?.isEnabled ?? false
            }
        }
    }

    private func checkAuthorizationStatus() {
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
