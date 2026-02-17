import SwiftUI

@MainActor
class ScheduleViewModel: ObservableObject {
    @Published var freedomWindows: [FreedomWindow] = []

    init() {
        loadWindows()
    }

    func addWindow(_ window: FreedomWindow) {
        freedomWindows.append(window)
        saveAndRegister()
    }

    func removeWindow(at offsets: IndexSet) {
        freedomWindows.remove(atOffsets: offsets)
        saveAndRegister()
    }

    func toggleWindow(_ window: FreedomWindow) {
        guard let index = freedomWindows.firstIndex(where: { $0.id == window.id }) else { return }
        freedomWindows[index].isEnabled.toggle()
        saveAndRegister()
    }

    private func loadWindows() {
        freedomWindows = AppState.shared.freedomWindows
    }

    private func saveAndRegister() {
        AppState.shared.freedomWindows = freedomWindows
        ScheduleService.registerSchedules(for: freedomWindows)
    }
}
