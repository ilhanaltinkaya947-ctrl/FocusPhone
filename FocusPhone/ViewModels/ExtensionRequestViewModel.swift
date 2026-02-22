import Foundation

@MainActor
class ExtensionRequestViewModel: ObservableObject {
    @Published var reason = ""
    @Published var requestedMinutes = 5
    @Published var isLoading = false
    @Published var result: RequestResult?
    @Published var errorMessage: String?

    let appName: String

    enum RequestResult {
        case approved(minutes: Int)
        case denied
    }

    init(appName: String) {
        self.appName = appName
    }

    var dailyCap: Int {
        AppState.shared.restrictionProfile?.dailyExtensionCapMinutes ?? 30
    }

    var dailyUsed: Int {
        AppState.shared.dailyExtensionMinutesUsed
    }

    var dailyRemaining: Int {
        max(0, dailyCap - dailyUsed)
    }

    var usageProgress: Double {
        guard dailyCap > 0 else { return 1.0 }
        return Double(dailyUsed) / Double(dailyCap)
    }

    var isCapReached: Bool {
        dailyUsed >= dailyCap
    }

    func submitRequest() {
        guard !reason.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Please provide a reason."
            return
        }
        guard !isCapReached else {
            errorMessage = "Daily extension cap reached."
            return
        }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                let approved = try await AIService.shared.evaluateExtensionRequest(
                    appName: appName,
                    reason: reason,
                    requestedMinutes: requestedMinutes,
                    dailyUsed: dailyUsed,
                    dailyCap: dailyCap
                )

                let request = ExtensionRequest(
                    appName: appName,
                    reason: reason,
                    requestedMinutes: requestedMinutes,
                    grantedMinutes: approved ? requestedMinutes : nil,
                    wasApproved: approved
                )
                AppState.shared.logExtensionRequest(request)

                if approved {
                    // Find the app and grant extension
                    if let app = AppState.shared.timedWindowStates.first(where: { $0.appName == appName }) {
                        RestrictionEngine.grantExtension(appID: app.id, minutes: requestedMinutes)
                    }
                    result = .approved(minutes: requestedMinutes)
                } else {
                    result = .denied
                }
            } catch {
                errorMessage = error.localizedDescription
            }

            isLoading = false
        }
    }
}
