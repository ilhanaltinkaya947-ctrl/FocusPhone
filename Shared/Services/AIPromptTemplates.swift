import Foundation

enum AIPromptTemplates {

    // MARK: - Schedule Builder (Onboarding)

    static func scheduleBuilderSystem(modeNames: [String]) -> String {
        """
        You are a schedule designer for a digital detox app called FocusPhone. \
        The user will describe their lifestyle and you will create a weekly schedule \
        using the available modes.

        Available modes: \(modeNames.joined(separator: ", "))

        Rules:
        - Each day must have at least one block
        - Blocks cannot overlap
        - Use 24-hour format for times
        - dayOfWeek uses 1=Sunday, 2=Monday, 3=Tuesday, 4=Wednesday, 5=Thursday, 6=Friday, 7=Saturday
        - Create a realistic, balanced schedule
        - Include sleep blocks every night
        - Match mode names EXACTLY as listed above

        Respond with ONLY valid JSON in this exact format:
        {
          "blocks": [
            {
              "mode": "Mode Name",
              "day": 2,
              "startHour": 6,
              "startMinute": 0,
              "endHour": 7,
              "endMinute": 30
            }
          ]
        }
        """
    }

    static func scheduleBuilderUser(profile: UserProfile) -> String {
        let areas = profile.selectedLifeAreas.map(\.description).joined(separator: ", ")
        let workDays = profile.workDays.map { dayName(for: $0) }.joined(separator: ", ")
        let wasters = profile.biggestTimeWasters.joined(separator: ", ")

        return """
        Create a weekly schedule for someone with these preferences:
        - Life priorities: \(areas)
        - Wake time: \(profile.wakeTime):00
        - Sleep time: \(profile.sleepTime):00
        - Work hours: \(profile.workStartHour):00 - \(profile.workEndHour):00 on \(workDays)
        - Exercise frequency: \(profile.exerciseFrequency) times per week
        - Biggest time wasters: \(wasters)

        Design a schedule that supports their goals and limits distractions.
        """
    }

    // MARK: - Natural Language Editing

    static func nlCommandSystem(modeNames: [String], currentSchedule: String) -> String {
        """
        You are a schedule editor for a digital detox app. The user will give you a \
        natural language command to modify their weekly schedule.

        Available modes: \(modeNames.joined(separator: ", "))
        dayOfWeek: 1=Sunday, 2=Monday, 3=Tuesday, 4=Wednesday, 5=Thursday, 6=Friday, 7=Saturday

        Current schedule:
        \(currentSchedule)

        Supported change types: add, remove, move, resize
        - "add": creates a new block (requires mode, day, start, end)
        - "remove": deletes an existing block (requires originalBlockID)
        - "move": changes day/time of existing block (requires originalBlockID + new day/time)
        - "resize": changes start/end of existing block (requires originalBlockID + new times)

        When the user says "tomorrow", calculate from today's day. \
        Today is day \(currentDayOfWeek()).

        Respond with ONLY valid JSON:
        {
          "changes": [
            {
              "type": "add",
              "modeName": "Deep Work",
              "dayOfWeek": 2,
              "startHour": 9,
              "startMinute": 0,
              "endHour": 12,
              "endMinute": 0,
              "originalBlockID": null
            }
          ],
          "message": "Added Deep Work on Monday 9:00-12:00"
        }

        If the command is unclear or impossible, respond with:
        {
          "changes": [],
          "message": "I couldn't understand that. Try something like 'Add Deep Work on Monday 9-12'."
        }
        """
    }

    // MARK: - Weekly Review

    static let weeklyReviewSystem = """
        You are a wellness coach reviewing a user's week in a digital detox app. \
        Analyze their schedule adherence and suggest improvements. \
        Be encouraging but honest. Keep suggestions actionable and specific.

        Respond with ONLY valid JSON:
        {
          "summary": "A 2-3 sentence summary of how the week went.",
          "suggestions": [
            {
              "type": "add",
              "modeName": "Deep Work",
              "dayOfWeek": 2,
              "startHour": 9,
              "startMinute": 0,
              "endHour": 11,
              "endMinute": 0,
              "reason": "Brief reason for this suggestion"
            }
          ]
        }

        Limit to 3 suggestions maximum. Each suggestion must use an existing mode name. \
        Suggestion types: add, remove, resize. Include originalBlockID for remove/resize.
        """

    static func weeklyReviewUser(stats: String, schedule: String) -> String {
        """
        Here's my week:

        Schedule:
        \(schedule)

        Stats:
        \(stats)

        How did my week go? Any suggestions for next week?
        """
    }

    // MARK: - Helpers

    private static func dayName(for dayOfWeek: Int) -> String {
        switch dayOfWeek {
        case 1: return "Sunday"
        case 2: return "Monday"
        case 3: return "Tuesday"
        case 4: return "Wednesday"
        case 5: return "Thursday"
        case 6: return "Friday"
        case 7: return "Saturday"
        default: return "Unknown"
        }
    }

    static func currentDayOfWeek() -> Int {
        Calendar.current.component(.weekday, from: Date())
    }

    static func formatScheduleForPrompt(blocks: [TimeBlock], modes: [Mode]) -> String {
        let sorted = blocks.sorted {
            if $0.dayOfWeek != $1.dayOfWeek { return $0.dayOfWeek < $1.dayOfWeek }
            return ($0.startHour * 60 + $0.startMinute) < ($1.startHour * 60 + $1.startMinute)
        }

        var lines: [String] = []
        for block in sorted {
            let modeName = modes.first(where: { $0.id == block.modeID })?.name ?? "Unknown"
            let day = dayName(for: block.dayOfWeek)
            lines.append("[\(block.id.uuidString)] \(day) \(block.startTimeString)-\(block.endTimeString) \(modeName)")
        }
        return lines.joined(separator: "\n")
    }
}
