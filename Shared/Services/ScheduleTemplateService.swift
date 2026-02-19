import Foundation

enum ScheduleTemplateService {

    static func generateSchedule(from profile: UserProfile, modes: [Mode]) -> [TimeBlock] {
        var blocks: [TimeBlock] = []

        let modeMap = Dictionary(uniqueKeysWithValues: modes.map { ($0.name, $0.id) })

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

                // Work blocks with break
                if let deepID = modeMap["Deep Work"], let breakID = modeMap["Break"] {
                    let midWork = profile.workStartHour + (profile.workEndHour - profile.workStartHour) / 2

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
                        endHour: midWork + 1,
                        endMinute: 0
                    ))

                    blocks.append(TimeBlock(
                        modeID: deepID,
                        dayOfWeek: day,
                        startHour: midWork + 1,
                        startMinute: 0,
                        endHour: profile.workEndHour,
                        endMinute: 0
                    ))
                }

                // After work: free time until wind down
                let windDownStart = profile.sleepTime - 1
                if profile.workEndHour < windDownStart {
                    if let freeID = modeMap["Free Time"] {
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

                if let freeID = modeMap["Free Time"] {
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

        return blocks
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
