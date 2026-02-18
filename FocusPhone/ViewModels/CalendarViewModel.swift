import SwiftUI

@MainActor
class CalendarViewModel: ObservableObject {
    @Published var selectedDate: Date = Date()
    @Published var timeBlocks: [TimeBlock] = []
    @Published var modes: [Mode] = []

    init() {
        loadData()
    }

    var selectedWeekday: Int {
        Calendar.current.component(.weekday, from: selectedDate)
    }

    var blocksForSelectedDay: [TimeBlock] {
        timeBlocks
            .filter { $0.dayOfWeek == selectedWeekday }
            .sorted { ($0.startHour * 60 + $0.startMinute) < ($1.startHour * 60 + $1.startMinute) }
    }

    func loadData() {
        AppState.shared.seedDefaultsIfNeeded()
        modes = AppState.shared.modes
        timeBlocks = AppState.shared.timeBlocks
    }

    func addTimeBlock(_ block: TimeBlock) {
        timeBlocks.append(block)
        saveAndSync()
    }

    func updateTimeBlock(_ block: TimeBlock) {
        if let index = timeBlocks.firstIndex(where: { $0.id == block.id }) {
            timeBlocks[index] = block
            saveAndSync()
        }
    }

    func removeTimeBlock(_ block: TimeBlock) {
        timeBlocks.removeAll { $0.id == block.id }
        saveAndSync()
    }

    func mode(for block: TimeBlock) -> Mode? {
        modes.first { $0.id == block.modeID }
    }

    private func saveAndSync() {
        AppState.shared.timeBlocks = timeBlocks
        ScheduleService.registerAllTimeBlocks()
    }
}
