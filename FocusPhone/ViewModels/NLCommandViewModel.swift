import SwiftUI
import WidgetKit

struct AIScheduleChange: Codable {
    let type: String        // add, remove, move, resize
    let modeName: String?
    let dayOfWeek: Int?
    let startHour: Int?
    let startMinute: Int?
    let endHour: Int?
    let endMinute: Int?
    let originalBlockID: String?
}

struct NLCommandResponse: Codable {
    let changes: [AIScheduleChange]
    let message: String?
}

@MainActor
class NLCommandViewModel: ObservableObject {
    @Published var commandText = ""
    @Published var isProcessing = false
    @Published var resultMessage: String?
    @Published var resultSuccess: Bool?
    @Published var pendingChanges: [AIScheduleChange] = []
    @Published var showingConfirmation = false

    func processCommand() {
        guard !commandText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isProcessing = true
        resultMessage = nil
        resultSuccess = nil
        pendingChanges = []

        let modes = AppState.shared.modes
        let blocks = AppState.shared.timeBlocks
        let modeNames = modes.map(\.name)
        let scheduleText = AIPromptTemplates.formatScheduleForPrompt(blocks: blocks, modes: modes)
        let command = commandText

        Task {
            do {
                let messages: [GroqService.Message] = [
                    .init(role: "system", content: AIPromptTemplates.nlCommandSystem(
                        modeNames: modeNames,
                        currentSchedule: scheduleText
                    )),
                    .init(role: "user", content: command),
                ]

                let response = try await GroqService.shared.chatJSON(
                    messages: messages,
                    as: NLCommandResponse.self
                )

                if response.changes.isEmpty {
                    resultMessage = response.message ?? "I couldn't understand that command."
                    resultSuccess = false
                } else {
                    pendingChanges = response.changes
                    resultMessage = response.message
                    showingConfirmation = true
                }
            } catch {
                resultMessage = "Something went wrong. Try the manual editor instead."
                resultSuccess = false
            }

            isProcessing = false
        }
    }

    func applyChanges() {
        var blocks = AppState.shared.timeBlocks
        let modes = AppState.shared.modes
        let modeMap = Dictionary(uniqueKeysWithValues: modes.map { ($0.name.lowercased(), $0.id) })

        for change in pendingChanges {
            switch change.type {
            case "add":
                guard let modeName = change.modeName,
                      let modeID = modeMap[modeName.lowercased()],
                      let day = change.dayOfWeek,
                      let sh = change.startHour,
                      let sm = change.startMinute,
                      let eh = change.endHour,
                      let em = change.endMinute else { continue }

                let newBlock = TimeBlock(
                    modeID: modeID,
                    dayOfWeek: day,
                    startHour: sh,
                    startMinute: sm,
                    endHour: eh,
                    endMinute: em
                )
                blocks.append(newBlock)

            case "remove":
                guard let idStr = change.originalBlockID,
                      let blockID = UUID(uuidString: idStr) else { continue }
                blocks.removeAll { $0.id == blockID }

            case "move":
                guard let idStr = change.originalBlockID,
                      let blockID = UUID(uuidString: idStr),
                      let index = blocks.firstIndex(where: { $0.id == blockID }) else { continue }

                if let day = change.dayOfWeek { blocks[index].dayOfWeek = day }
                if let sh = change.startHour { blocks[index].startHour = sh }
                if let sm = change.startMinute { blocks[index].startMinute = sm }
                if let eh = change.endHour { blocks[index].endHour = eh }
                if let em = change.endMinute { blocks[index].endMinute = em }

            case "resize":
                guard let idStr = change.originalBlockID,
                      let blockID = UUID(uuidString: idStr),
                      let index = blocks.firstIndex(where: { $0.id == blockID }) else { continue }

                if let sh = change.startHour { blocks[index].startHour = sh }
                if let sm = change.startMinute { blocks[index].startMinute = sm }
                if let eh = change.endHour { blocks[index].endHour = eh }
                if let em = change.endMinute { blocks[index].endMinute = em }

            default:
                break
            }
        }

        AppState.shared.timeBlocks = blocks
        ScheduleService.registerAllTimeBlocks()
        WidgetCenter.shared.reloadAllTimelines()

        pendingChanges = []
        showingConfirmation = false
        resultSuccess = true
        resultMessage = "Changes applied!"
    }

    func changeDescription(_ change: AIScheduleChange) -> String {
        let modes = AppState.shared.modes
        let dayName = dayNameForWeekday(change.dayOfWeek ?? 0)

        switch change.type {
        case "add":
            let time = formatTime(change.startHour, change.startMinute, change.endHour, change.endMinute)
            return "Add \(change.modeName ?? "block") on \(dayName) \(time)"
        case "remove":
            if let idStr = change.originalBlockID,
               let blockID = UUID(uuidString: idStr),
               let block = AppState.shared.timeBlocks.first(where: { $0.id == blockID }),
               let mode = modes.first(where: { $0.id == block.modeID }) {
                return "Remove \(mode.name) on \(dayNameForWeekday(block.dayOfWeek))"
            }
            return "Remove block"
        case "move":
            let time = formatTime(change.startHour, change.startMinute, change.endHour, change.endMinute)
            return "Move to \(dayName) \(time)"
        case "resize":
            let time = formatTime(change.startHour, change.startMinute, change.endHour, change.endMinute)
            return "Resize to \(time)"
        default:
            return change.type
        }
    }

    private func dayNameForWeekday(_ day: Int) -> String {
        switch day {
        case 1: return "Sunday"
        case 2: return "Monday"
        case 3: return "Tuesday"
        case 4: return "Wednesday"
        case 5: return "Thursday"
        case 6: return "Friday"
        case 7: return "Saturday"
        default: return ""
        }
    }

    private func formatTime(_ sh: Int?, _ sm: Int?, _ eh: Int?, _ em: Int?) -> String {
        guard let sh, let sm, let eh, let em else { return "" }
        return String(format: "%02d:%02d-%02d:%02d", sh, sm, eh, em)
    }
}
