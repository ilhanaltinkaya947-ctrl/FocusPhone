import SwiftUI
import WidgetKit

@MainActor
class CalendarViewModel: ObservableObject {
    @Published var selectedDate: Date = Date()
    @Published var timeBlocks: [TimeBlock] = []
    @Published var modes: [Mode] = []
    @Published var dailyIntention: DailyIntention?
    @Published var currentModeInfo: CurrentModeInfo?

    struct CurrentModeInfo {
        let mode: Mode
        let block: TimeBlock
        let remainingSeconds: Int
    }

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

    var isSelectedDateToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }

    func loadData() {
        AppState.shared.seedDefaultsIfNeeded()
        modes = AppState.shared.modes
        timeBlocks = AppState.shared.timeBlocks
        loadIntention()
        updateCurrentMode()
    }

    func loadIntention() {
        dailyIntention = AppState.shared.intention(for: selectedDate)
    }

    func saveIntention(_ text: String) {
        AppState.shared.setIntention(text, for: selectedDate)
        dailyIntention = AppState.shared.intention(for: selectedDate)
    }

    func updateCurrentMode() {
        guard Calendar.current.isDateInToday(selectedDate) else {
            currentModeInfo = nil
            return
        }
        let now = Date()
        let cal = Calendar.current
        let currentMinutes = cal.component(.hour, from: now) * 60 + cal.component(.minute, from: now)
        let weekday = cal.component(.weekday, from: now)

        for block in timeBlocks where block.dayOfWeek == weekday {
            let start = block.startHour * 60 + block.startMinute
            let end = block.endHour * 60 + block.endMinute
            if currentMinutes >= start && currentMinutes < end {
                if let mode = modes.first(where: { $0.id == block.modeID }) {
                    let remaining = (end - currentMinutes) * 60
                    currentModeInfo = CurrentModeInfo(mode: mode, block: block, remainingSeconds: remaining)
                    return
                }
            }
        }
        currentModeInfo = nil
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
        WidgetCenter.shared.reloadAllTimelines()
    }
}
