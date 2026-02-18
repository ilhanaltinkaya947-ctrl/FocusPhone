import SwiftUI
import FamilyControls

@MainActor
class ModeListViewModel: ObservableObject {
    @Published var modes: [Mode] = []
    @Published var activeModeID: UUID?

    init() {
        loadModes()
    }

    func loadModes() {
        AppState.shared.seedDefaultsIfNeeded()
        modes = AppState.shared.modes
        activeModeID = AppState.shared.activeModeID
    }

    func updateMode(_ mode: Mode) {
        if let index = modes.firstIndex(where: { $0.id == mode.id }) {
            modes[index] = mode
            saveModes()

            // If this is the active mode, re-apply blocks immediately
            if AppState.shared.activeModeID == mode.id {
                BlockingService.applyBlocks(for: mode)
            }
        }
    }

    func addMode(_ mode: Mode) {
        modes.append(mode)
        saveModes()
    }

    func deleteMode(_ mode: Mode) {
        guard !mode.isSystem else { return }
        modes.removeAll { $0.id == mode.id }
        var blocks = AppState.shared.timeBlocks
        blocks.removeAll { $0.modeID == mode.id }
        AppState.shared.timeBlocks = blocks
        saveModes()
    }

    private func saveModes() {
        AppState.shared.modes = modes
    }
}
