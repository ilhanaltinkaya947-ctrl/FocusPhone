import Foundation

enum TimeBlockValidationError: Error, LocalizedError {
    case invalidHour(Int)
    case invalidMinute(Int)
    case invalidDay(Int)
    case startNotBeforeEnd(startMinutes: Int, endMinutes: Int)
    case overlappingBlocks(TimeBlock, TimeBlock)
    case unknownModeName(String)

    var errorDescription: String? {
        switch self {
        case .invalidHour(let h): return "Invalid hour: \(h) (must be 0-23)"
        case .invalidMinute(let m): return "Invalid minute: \(m) (must be 0-59)"
        case .invalidDay(let d): return "Invalid day: \(d) (must be 1-7)"
        case .startNotBeforeEnd(let s, let e): return "Block start (\(s)m) must be before end (\(e)m)"
        case .overlappingBlocks: return "Two blocks overlap on the same day"
        case .unknownModeName(let name): return "Unknown mode: \(name)"
        }
    }
}

enum TimeBlockValidator {

    // MARK: - Single Block Validation

    /// Validates a single TimeBlock's fields are in legal ranges
    static func validate(_ block: TimeBlock) -> [TimeBlockValidationError] {
        var errors: [TimeBlockValidationError] = []

        if block.startHour < 0 || block.startHour > 23 {
            errors.append(.invalidHour(block.startHour))
        }
        if block.endHour < 0 || block.endHour > 23 {
            errors.append(.invalidHour(block.endHour))
        }
        if block.startMinute < 0 || block.startMinute > 59 {
            errors.append(.invalidMinute(block.startMinute))
        }
        if block.endMinute < 0 || block.endMinute > 59 {
            errors.append(.invalidMinute(block.endMinute))
        }
        if block.dayOfWeek < 1 || block.dayOfWeek > 7 {
            errors.append(.invalidDay(block.dayOfWeek))
        }

        let startMinutes = block.startHour * 60 + block.startMinute
        let endMinutes = block.endHour * 60 + block.endMinute
        if startMinutes >= endMinutes {
            errors.append(.startNotBeforeEnd(startMinutes: startMinutes, endMinutes: endMinutes))
        }

        return errors
    }

    /// Returns true if the block is valid
    static func isValid(_ block: TimeBlock) -> Bool {
        validate(block).isEmpty
    }

    // MARK: - Set Validation

    /// Detects overlapping blocks on the same day
    static func findOverlaps(in blocks: [TimeBlock]) -> [(TimeBlock, TimeBlock)] {
        var overlaps: [(TimeBlock, TimeBlock)] = []

        let grouped = Dictionary(grouping: blocks) { $0.dayOfWeek }

        for (_, dayBlocks) in grouped {
            let sorted = dayBlocks.sorted {
                ($0.startHour * 60 + $0.startMinute) < ($1.startHour * 60 + $1.startMinute)
            }

            for i in 0..<sorted.count {
                for j in (i + 1)..<sorted.count {
                    let aEnd = sorted[i].endHour * 60 + sorted[i].endMinute
                    let bStart = sorted[j].startHour * 60 + sorted[j].startMinute
                    if aEnd > bStart {
                        overlaps.append((sorted[i], sorted[j]))
                    }
                }
            }
        }

        return overlaps
    }

    // MARK: - Sanitize AI Response

    /// Sanitizes a raw AI schedule block: clamps values and maps mode name to mode ID.
    /// Returns nil if the mode name doesn't match any known mode.
    static func sanitize(
        _ groqBlock: AIScheduleBlock,
        modeMap: [String: UUID]
    ) -> TimeBlock? {
        guard let modeID = modeMap[groqBlock.mode.lowercased()] else {
            return nil
        }

        let startHour = clamp(groqBlock.startHour, 0, 23)
        let startMinute = clamp(groqBlock.startMinute, 0, 59)
        let endHour = clamp(groqBlock.endHour, 0, 23)
        let endMinute = clamp(groqBlock.endMinute, 0, 59)
        let day = clamp(groqBlock.day, 1, 7)

        let startTotal = startHour * 60 + startMinute
        var endTotal = endHour * 60 + endMinute

        // If start >= end, push end to start + 30 min (minimum viable block)
        if startTotal >= endTotal {
            endTotal = min(startTotal + 30, 23 * 60 + 59)
        }

        return TimeBlock(
            modeID: modeID,
            dayOfWeek: day,
            startHour: startHour,
            startMinute: startMinute,
            endHour: endTotal / 60,
            endMinute: endTotal % 60
        )
    }

    // MARK: - Conflict Resolution

    /// Resolves overlaps by truncating the later block's start or removing it if too short.
    /// Blocks should be for a single day. Returns de-overlapped blocks.
    static func resolveConflicts(_ blocks: [TimeBlock]) -> [TimeBlock] {
        let grouped = Dictionary(grouping: blocks) { $0.dayOfWeek }
        var result: [TimeBlock] = []

        for (_, dayBlocks) in grouped {
            var sorted = dayBlocks.sorted {
                ($0.startHour * 60 + $0.startMinute) < ($1.startHour * 60 + $1.startMinute)
            }

            for i in 1..<sorted.count {
                let prevEnd = sorted[i - 1].endHour * 60 + sorted[i - 1].endMinute
                let currStart = sorted[i].startHour * 60 + sorted[i].startMinute

                if prevEnd > currStart {
                    // Truncate current block's start to previous block's end
                    let newStart = prevEnd
                    let currEnd = sorted[i].endHour * 60 + sorted[i].endMinute

                    if currEnd > newStart + 5 { // Keep block only if > 5 min remaining
                        sorted[i] = TimeBlock(
                            id: sorted[i].id,
                            modeID: sorted[i].modeID,
                            dayOfWeek: sorted[i].dayOfWeek,
                            startHour: newStart / 60,
                            startMinute: newStart % 60,
                            endHour: sorted[i].endHour,
                            endMinute: sorted[i].endMinute
                        )
                    } else {
                        // Block too small after truncation, mark for removal
                        sorted[i] = TimeBlock(
                            id: sorted[i].id,
                            modeID: sorted[i].modeID,
                            dayOfWeek: sorted[i].dayOfWeek,
                            startHour: 0,
                            startMinute: 0,
                            endHour: 0,
                            endMinute: 0
                        )
                    }
                }
            }

            // Filter out zero-duration blocks
            result.append(contentsOf: sorted.filter { isValid($0) })
        }

        return result
    }

    // MARK: - Check if new block overlaps existing ones

    /// Returns true if `newBlock` overlaps any block in `existingBlocks` on the same day
    static func wouldOverlap(_ newBlock: TimeBlock, with existingBlocks: [TimeBlock]) -> Bool {
        let sameDayBlocks = existingBlocks.filter { $0.dayOfWeek == newBlock.dayOfWeek }

        let newStart = newBlock.startHour * 60 + newBlock.startMinute
        let newEnd = newBlock.endHour * 60 + newBlock.endMinute

        for block in sameDayBlocks {
            let bStart = block.startHour * 60 + block.startMinute
            let bEnd = block.endHour * 60 + block.endMinute

            if newStart < bEnd && newEnd > bStart {
                return true
            }
        }
        return false
    }

    // MARK: - Helpers

    private static func clamp(_ value: Int, _ lo: Int, _ hi: Int) -> Int {
        min(max(value, lo), hi)
    }
}
