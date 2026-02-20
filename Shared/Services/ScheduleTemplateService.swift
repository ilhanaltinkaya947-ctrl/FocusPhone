import Foundation

enum ScheduleTemplateService {

    static func generateSchedule(from profile: UserProfile, modes: [Mode]) -> [TimeBlock] {
        var blocks: [TimeBlock] = []

        let modeMap = Dictionary(uniqueKeysWithValues: modes.map { ($0.name, $0.id) })
        let isGentle = profile.commitmentLevel == "gentle"
        let isStrict = profile.commitmentLevel == "strict"

        for day in 1...7 {
            let isWorkDay = profile.workDays.contains(day)

            // Sleep block: sleepTime to wakeTime
            if let sleepID = modeMap["Sleep"] {
                blocks.append(TimeBlock(
                    modeID: sleepID,
                    dayOfWeek: day,
                    startHour: profile.sleepTime,
                    startMinute: 0,
                    endHour: 23,
                    endMinute: 59
                ))

                // Early morning sleep (previous day's sleep continues)
                blocks.append(TimeBlock(
                    modeID: sleepID,
                    dayOfWeek: day,
                    startHour: 0,
                    startMinute: 0,
                    endHour: profile.wakeTime,
                    endMinute: 0
                ))
            }

            // Morning Routine: wake to wake+1
            if let morningID = modeMap["Morning Routine"] {
                blocks.append(TimeBlock(
                    modeID: morningID,
                    dayOfWeek: day,
                    startHour: profile.wakeTime,
                    startMinute: 0,
                    endHour: profile.wakeTime + 1,
                    endMinute: 0
                ))
            }

            if isWorkDay {
                // Deep Work: morning routine end to work start (if gap exists)
                let morningEnd = profile.wakeTime + 1
                if morningEnd < profile.workStartHour, let deepID = modeMap["Deep Work"] {
                    blocks.append(TimeBlock(
                        modeID: deepID,
                        dayOfWeek: day,
                        startHour: morningEnd,
                        startMinute: 0,
                        endHour: profile.workStartHour,
                        endMinute: 0
                    ))
                }

                // Work blocks with break — commitment level affects break length
                if let deepID = modeMap["Deep Work"], let breakID = modeMap["Break"] {
                    let midWork = profile.workStartHour + (profile.workEndHour - profile.workStartHour) / 2
                    let breakDuration = isStrict ? 0 : (isGentle ? 2 : 1) // hours

                    if breakDuration == 0 {
                        // Strict: no break, continuous deep work
                        blocks.append(TimeBlock(
                            modeID: deepID,
                            dayOfWeek: day,
                            startHour: profile.workStartHour,
                            startMinute: 0,
                            endHour: profile.workEndHour,
                            endMinute: 0
                        ))
                    } else {
                        blocks.append(TimeBlock(
                            modeID: deepID,
                            dayOfWeek: day,
                            startHour: profile.workStartHour,
                            startMinute: 0,
                            endHour: midWork,
                            endMinute: 0
                        ))

                        blocks.append(TimeBlock(
                            modeID: breakID,
                            dayOfWeek: day,
                            startHour: midWork,
                            startMinute: 0,
                            endHour: midWork + breakDuration,
                            endMinute: 0
                        ))

                        blocks.append(TimeBlock(
                            modeID: deepID,
                            dayOfWeek: day,
                            startHour: midWork + breakDuration,
                            startMinute: 0,
                            endHour: profile.workEndHour,
                            endMinute: 0
                        ))
                    }
                }

                // After work: free time until wind down
                let windDownStart = profile.sleepTime - 1
                if profile.workEndHour < windDownStart {
                    if isStrict {
                        // Strict: add a Deep Work block in the evening too, then short free time
                        let eveningFocusEnd = min(profile.workEndHour + 2, windDownStart)
                        if let deepID = modeMap["Deep Work"], eveningFocusEnd > profile.workEndHour {
                            blocks.append(TimeBlock(
                                modeID: deepID,
                                dayOfWeek: day,
                                startHour: profile.workEndHour,
                                startMinute: 0,
                                endHour: eveningFocusEnd,
                                endMinute: 0
                            ))
                        }
                        if eveningFocusEnd < windDownStart, let freeID = modeMap["Free Time"] {
                            blocks.append(TimeBlock(
                                modeID: freeID,
                                dayOfWeek: day,
                                startHour: eveningFocusEnd,
                                startMinute: 0,
                                endHour: windDownStart,
                                endMinute: 0
                            ))
                        }
                    } else if let freeID = modeMap["Free Time"] {
                        blocks.append(TimeBlock(
                            modeID: freeID,
                            dayOfWeek: day,
                            startHour: profile.workEndHour,
                            startMinute: 0,
                            endHour: windDownStart,
                            endMinute: 0
                        ))
                    }
                }
            } else {
                // Weekend / non-work day
                let morningEnd = profile.wakeTime + 1
                let windDownStart = profile.sleepTime - 1

                if isStrict {
                    // Strict: add some focus time even on weekends
                    let focusEnd = min(morningEnd + 2, windDownStart)
                    if let deepID = modeMap["Deep Work"] {
                        blocks.append(TimeBlock(
                            modeID: deepID,
                            dayOfWeek: day,
                            startHour: morningEnd,
                            startMinute: 0,
                            endHour: focusEnd,
                            endMinute: 0
                        ))
                    }
                    if focusEnd < windDownStart, let freeID = modeMap["Free Time"] {
                        blocks.append(TimeBlock(
                            modeID: freeID,
                            dayOfWeek: day,
                            startHour: focusEnd,
                            startMinute: 0,
                            endHour: windDownStart,
                            endMinute: 0
                        ))
                    }
                } else if let freeID = modeMap["Free Time"] {
                    blocks.append(TimeBlock(
                        modeID: freeID,
                        dayOfWeek: day,
                        startHour: morningEnd,
                        startMinute: 0,
                        endHour: windDownStart,
                        endMinute: 0
                    ))
                }
            }

            // Wind Down: 1 hour before sleep
            let windDownStart = profile.sleepTime - 1
            if windDownStart > 0, let windDownID = modeMap["Wind Down"] {
                blocks.append(TimeBlock(
                    modeID: windDownID,
                    dayOfWeek: day,
                    startHour: windDownStart,
                    startMinute: 0,
                    endHour: profile.sleepTime,
                    endMinute: 0
                ))
            }
        }

        // Add exercise blocks based on frequency
        if profile.exerciseFrequency > 0, let exerciseID = modeMap["Exercise"] {
            // Prefer mornings on work days, afternoons on off days
            let exerciseDays = pickExerciseDays(
                frequency: profile.exerciseFrequency,
                workDays: profile.workDays
            )
            for day in exerciseDays {
                let isWorkDay = profile.workDays.contains(day)
                let hour = isWorkDay ? profile.wakeTime + 1 : profile.wakeTime + 2
                // Remove conflicting block at this time slot
                blocks.removeAll { $0.dayOfWeek == day && $0.startHour == hour }
                blocks.append(TimeBlock(
                    modeID: exerciseID,
                    dayOfWeek: day,
                    startHour: hour,
                    startMinute: 0,
                    endHour: hour + 1,
                    endMinute: 0
                ))
            }
        }

        // Apply life area adjustments
        applyLifeAreaAdjustments(
            to: &blocks,
            lifeAreas: profile.selectedLifeAreas,
            profile: profile,
            modeMap: modeMap
        )

        return blocks
    }

    // MARK: - Life Area Adjustments

    private static func applyLifeAreaAdjustments(
        to blocks: inout [TimeBlock],
        lifeAreas: [LifeArea],
        profile: UserProfile,
        modeMap: [String: UUID]
    ) {
        let isStrict = profile.commitmentLevel == "strict"

        for area in lifeAreas {
            switch area {
            case .body:
                // Ensure exercise blocks exist even at low/zero frequency
                if profile.exerciseFrequency == 0, let exerciseID = modeMap["Exercise"] {
                    let offDays = (1...7).filter { !profile.workDays.contains($0) }
                    let days = offDays.isEmpty ? [1, 4] : Array(offDays.prefix(2))
                    for day in days {
                        let hour = profile.wakeTime + 2
                        blocks.removeAll { $0.dayOfWeek == day && $0.startHour == hour }
                        blocks.append(TimeBlock(
                            modeID: exerciseID,
                            dayOfWeek: day,
                            startHour: hour,
                            startMinute: 0,
                            endHour: hour + 1,
                            endMinute: 0
                        ))
                    }
                }

            case .mind:
                // Add evening Deep Work blocks on non-work days for reading/learning
                if let deepID = modeMap["Deep Work"] {
                    let offDays = (1...7).filter { !profile.workDays.contains($0) }
                    for day in offDays {
                        let startHour = profile.sleepTime - 3
                        let endHour = profile.sleepTime - 1
                        guard startHour > profile.wakeTime + 1 else { continue }
                        // Remove any Free Time block in this slot
                        blocks.removeAll {
                            $0.dayOfWeek == day && $0.startHour == startHour &&
                            $0.endHour == endHour
                        }
                        blocks.append(TimeBlock(
                            modeID: deepID,
                            dayOfWeek: day,
                            startHour: startHour,
                            startMinute: 0,
                            endHour: endHour,
                            endMinute: 0
                        ))
                    }
                }

            case .peace:
                // Extend Wind Down by 30 min earlier, extend Morning Routine by 30 min
                if let windDownID = modeMap["Wind Down"] {
                    for i in blocks.indices {
                        if blocks[i].modeID == windDownID {
                            let newStart = blocks[i].startHour * 60 + blocks[i].startMinute - 30
                            blocks[i] = TimeBlock(
                                modeID: windDownID,
                                dayOfWeek: blocks[i].dayOfWeek,
                                startHour: newStart / 60,
                                startMinute: newStart % 60,
                                endHour: blocks[i].endHour,
                                endMinute: blocks[i].endMinute
                            )
                        }
                    }
                }
                if let morningID = modeMap["Morning Routine"] {
                    for i in blocks.indices {
                        if blocks[i].modeID == morningID {
                            let newEnd = blocks[i].endHour * 60 + blocks[i].endMinute + 30
                            blocks[i] = TimeBlock(
                                modeID: morningID,
                                dayOfWeek: blocks[i].dayOfWeek,
                                startHour: blocks[i].startHour,
                                startMinute: blocks[i].startMinute,
                                endHour: newEnd / 60,
                                endMinute: newEnd % 60
                            )
                        }
                    }
                }

            case .career:
                // Extend Deep Work blocks on work days by starting 30 min earlier
                if let deepID = modeMap["Deep Work"] {
                    for i in blocks.indices {
                        let block = blocks[i]
                        guard block.modeID == deepID,
                              profile.workDays.contains(block.dayOfWeek),
                              block.startHour >= profile.workStartHour else { continue }
                        let newEnd = block.endHour * 60 + block.endMinute + 30
                        blocks[i] = TimeBlock(
                            modeID: deepID,
                            dayOfWeek: block.dayOfWeek,
                            startHour: block.startHour,
                            startMinute: block.startMinute,
                            endHour: min(newEnd / 60, 23),
                            endMinute: newEnd % 60
                        )
                    }
                }

            case .creativity:
                // Add a dedicated creative block on weekend afternoons
                if let freeID = modeMap["Free Time"] {
                    let weekendDays = (1...7).filter { !profile.workDays.contains($0) }
                    for day in weekendDays {
                        let startHour = 14
                        let endHour = 16
                        // Replace Free Time in this slot
                        blocks.removeAll {
                            $0.dayOfWeek == day && $0.modeID == freeID &&
                            $0.startHour <= startHour && $0.endHour >= endHour
                        }
                        // Re-add shortened Free Time if needed
                        blocks.append(TimeBlock(
                            modeID: freeID,
                            dayOfWeek: day,
                            startHour: startHour,
                            startMinute: 0,
                            endHour: endHour,
                            endMinute: 0
                        ))
                    }
                }

            case .relationships:
                // Protect evening Free Time — don't fill with focus blocks in strict mode
                if isStrict, let freeID = modeMap["Free Time"], let deepID = modeMap["Deep Work"] {
                    let windDownStart = profile.sleepTime - 1
                    for day in 1...7 {
                        // Remove evening Deep Work blocks that were added by strict mode
                        blocks.removeAll {
                            $0.dayOfWeek == day && $0.modeID == deepID &&
                            $0.startHour >= profile.workEndHour && $0.endHour <= windDownStart
                        }
                        // Ensure Free Time covers the evening
                        if profile.workEndHour < windDownStart {
                            // Remove any existing free time in this slot to avoid duplicates
                            blocks.removeAll {
                                $0.dayOfWeek == day && $0.modeID == freeID &&
                                $0.startHour == profile.workEndHour
                            }
                            blocks.append(TimeBlock(
                                modeID: freeID,
                                dayOfWeek: day,
                                startHour: profile.workEndHour,
                                startMinute: 0,
                                endHour: windDownStart,
                                endMinute: 0
                            ))
                        }
                    }
                }
            }
        }
    }

    private static func pickExerciseDays(frequency: Int, workDays: [Int]) -> [Int] {
        let allDays = Array(1...7)
        let offDays = allDays.filter { !workDays.contains($0) }

        var selected: [Int] = []
        var remaining = frequency

        // Prefer off days first
        for day in offDays where remaining > 0 {
            selected.append(day)
            remaining -= 1
        }

        // Then spread across work days
        if remaining > 0 {
            let spreadDays = workDays.enumerated()
                .filter { $0.offset % max(1, workDays.count / remaining) == 0 }
                .map(\.element)

            for day in spreadDays where remaining > 0 {
                selected.append(day)
                remaining -= 1
            }
        }

        return selected.sorted()
    }
}
