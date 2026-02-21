import Foundation

enum AIPromptTemplates {

    // MARK: - Schedule Builder (Onboarding)

    static func scheduleBuilderSystem(modeNames: [String], commitmentLevel: String = "balanced") -> String {
        let densityGuidance: String
        switch commitmentLevel {
        case "gentle":
            densityGuidance = """
            The user prefers a GENTLE approach. Create a flexible schedule with:
            - Fewer focus blocks, more free time
            - Shorter Deep Work sessions (1-2 hours max)
            - Generous breaks between blocks
            - Prioritize suggestions over strict blocking
            """
        case "strict":
            densityGuidance = """
            The user wants STRICT mode. Create a tight, productive schedule with:
            - Many focus blocks covering most of the day
            - Long Deep Work sessions (2-4 hours)
            - Minimal free time during work hours
            - Lock down distractions aggressively
            """
        default:
            densityGuidance = """
            The user prefers a BALANCED approach. Create a moderate schedule with:
            - Focused work blocks during productive hours
            - Reasonable breaks and free time
            - Block distractions during focus periods
            """
        }

        return """
        You are a schedule designer for a digital detox app called FocusPhone. \
        The user will describe their lifestyle and you will create a weekly schedule \
        using the available modes.

        Available modes (use these EXACT names): \(modeNames.joined(separator: ", "))

        \(densityGuidance)

        STRICT RULES — violations will cause errors:
        - hours must be 0-23, minutes must be 0 or 30 (no other values)
        - startHour:startMinute must be BEFORE endHour:endMinute (no midnight-crossing blocks)
        - Blocks on the same day MUST NOT overlap
        - dayOfWeek uses 1=Sunday, 2=Monday, 3=Tuesday, 4=Wednesday, 5=Thursday, 6=Friday, 7=Saturday
        - Use mode names EXACTLY as listed above (case-sensitive match required)
        - Each day must have at least 3 blocks
        - Include a Sleep block every night
        - Include a Morning Routine block every day
        - If the user has fixed commitments, NEVER schedule over them — leave those time slots as Break

        Example valid Monday schedule:
        {"mode": "Sleep", "day": 2, "startHour": 0, "startMinute": 0, "endHour": 7, "endMinute": 0}
        {"mode": "Morning Routine", "day": 2, "startHour": 7, "startMinute": 0, "endHour": 8, "endMinute": 0}
        {"mode": "Deep Work", "day": 2, "startHour": 8, "startMinute": 0, "endHour": 12, "endMinute": 0}
        {"mode": "Break", "day": 2, "startHour": 12, "startMinute": 0, "endHour": 13, "endMinute": 0}
        {"mode": "Deep Work", "day": 2, "startHour": 13, "startMinute": 0, "endHour": 17, "endMinute": 0}
        {"mode": "Free Time", "day": 2, "startHour": 17, "startMinute": 0, "endHour": 22, "endMinute": 0}
        {"mode": "Wind Down", "day": 2, "startHour": 22, "startMinute": 0, "endHour": 23, "endMinute": 0}
        {"mode": "Sleep", "day": 2, "startHour": 23, "startMinute": 0, "endHour": 23, "endMinute": 59}

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

        var prompt = """
        Create a weekly schedule for someone with these preferences:
        - Life priorities: \(areas)
        - Wake time: \(profile.wakeTime):00
        - Sleep time: \(profile.sleepTime):00
        - Work hours: \(profile.workStartHour):00 - \(profile.workEndHour):00 on \(workDays)
        - Exercise frequency: \(profile.exerciseFrequency) times per week
        - Biggest time wasters: \(wasters)
        - Commitment level: \(profile.commitmentLevel)
        """

        // Energy pattern
        switch profile.energyPattern {
        case "morning_person":
            prompt += "\n- Energy pattern: Morning person — schedule Deep Work before noon"
        case "night_owl":
            prompt += "\n- Energy pattern: Night owl — schedule Deep Work in the evening/after work hours"
        default:
            prompt += "\n- Energy pattern: Steady throughout the day"
        }

        // Daily phone goal
        prompt += "\n- Daily phone goal: Max \(profile.dailyPhoneGoal) hours — "
        if profile.dailyPhoneGoal <= 2 {
            prompt += "schedule aggressive blocking with minimal free time"
        } else if profile.dailyPhoneGoal <= 4 {
            prompt += "moderate blocking schedule"
        } else {
            prompt += "light blocking, more free time"
        }

        // Distraction trigger
        switch profile.distractionTrigger {
        case "boredom":
            prompt += "\n- Main distraction trigger: Boredom — add varied blocks, avoid long monotonous stretches"
        case "stress":
            prompt += "\n- Main distraction trigger: Stress — add extra Wind Down blocks around work, include breaks"
        case "social_pressure":
            prompt += "\n- Main distraction trigger: FOMO/social pressure — block social media aggressively during focus time"
        default:
            prompt += "\n- Main distraction trigger: Habit — consistent blocking structure to break routines"
        }

        // Fixed commitments
        if !profile.fixedCommitments.isEmpty {
            prompt += "\n- Fixed commitments (DO NOT schedule over these):"
            for c in profile.fixedCommitments {
                prompt += "\n  - \(c.name): \(dayName(for: c.dayOfWeek)) \(c.startHour):00-\(c.endHour):00"
            }
        }

        if !profile.weeklyGoalText.isEmpty {
            prompt += "\n- Weekly goal: \(profile.weeklyGoalText)"
        }

        if !profile.customBlockedWebsites.isEmpty {
            prompt += "\n- Custom blocked websites: \(profile.customBlockedWebsites.joined(separator: ", "))"
        }

        prompt += "\n\nDesign a schedule that supports their goals and limits distractions."

        return prompt
    }

    // MARK: - Natural Language Editing

    static func nlCommandSystem(modeNames: [String], currentSchedule: String) -> String {
        """
        You are a schedule editor for a digital detox app. The user will give you a \
        natural language command to modify their weekly schedule.

        Available modes (use EXACT names): \(modeNames.joined(separator: ", "))
        dayOfWeek: 1=Sunday, 2=Monday, 3=Tuesday, 4=Wednesday, 5=Thursday, 6=Friday, 7=Saturday

        Current schedule (each line: [UUID] Day StartTime-EndTime ModeName):
        \(currentSchedule)

        Supported change types: add, remove, move, resize
        - "add": creates a new block (requires modeName, dayOfWeek, startHour, startMinute, endHour, endMinute)
        - "remove": deletes an existing block (requires originalBlockID — use EXACT UUID from schedule above)
        - "move": changes day/time of existing block (requires originalBlockID + new day/time)
        - "resize": changes start/end of existing block (requires originalBlockID + new times)

        IMPORTANT: Use EXACT UUIDs from the schedule above. Do NOT fabricate block IDs. \
        If a block doesn't exist in the schedule, you cannot remove/move/resize it.

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

    static func weeklyReviewSystem(modeNames: [String]) -> String {
        """
        You are a wellness coach reviewing a user's week in a digital detox app. \
        Analyze their schedule adherence and suggest improvements. \
        Be encouraging but honest. Keep suggestions actionable and specific.

        Available modes (use EXACT names): \(modeNames.joined(separator: ", "))

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

        Limit to 3 suggestions maximum. Each suggestion must use an EXACT mode name from above. \
        Suggestion types: add, remove, resize. \
        For remove/resize, include originalBlockID using the EXACT UUID from the schedule. \
        Only reference block IDs that appear in the schedule provided.
        """
    }

    static func weeklyReviewUser(stats: String, schedule: String) -> String {
        """
        Here's my week:

        Schedule (each line: [UUID] Day StartTime-EndTime ModeName):
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
