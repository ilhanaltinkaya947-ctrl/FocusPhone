import Foundation

enum TimedWindowService {

    /// Generates clock-based time slots for a timed window app throughout the day.
    /// For example: 5 min every 2 hours from 8:00 to 22:00 yields slots at 8:00-8:05, 10:00-10:05, etc.
    static func generateWindowSlots(
        for app: TimedWindowApp,
        wakeHour: Int = 8,
        sleepHour: Int = 22
    ) -> [TimeBlock] {
        let windowMinutes = app.windowDurationMinutes
        let cooldownMinutes = app.cooldownMinutes
        let interval = windowMinutes + cooldownMinutes

        var slots: [TimeBlock] = []
        // Generate for all 7 days (1=Sunday...7=Saturday)
        for dayOfWeek in 1...7 {
            var currentMinute = wakeHour * 60
            let endMinute = sleepHour * 60

            while currentMinute + windowMinutes <= endMinute {
                let startHour = currentMinute / 60
                let startMin = currentMinute % 60
                let endTotal = currentMinute + windowMinutes
                let endHr = endTotal / 60
                let endMn = endTotal % 60

                slots.append(TimeBlock(
                    appID: app.id,
                    dayOfWeek: dayOfWeek,
                    startHour: startHour,
                    startMinute: startMin,
                    endHour: endHr,
                    endMinute: endMn,
                    isRecurring: true
                ))

                currentMinute += interval
            }
        }

        return slots
    }

    /// Generate all window slots for all timed window apps in a profile.
    static func generateAllSlots(for profile: PersonalRestrictionProfile) -> [TimeBlock] {
        profile.timedWindowApps.flatMap { generateWindowSlots(for: $0) }
    }

    /// Check if a window is currently open for a given app.
    static func isWindowOpen(for appID: UUID, in slots: [TimeBlock]) -> Bool {
        let now = Date()
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: now)
        let currentMinutes = calendar.component(.hour, from: now) * 60 + calendar.component(.minute, from: now)

        return slots.contains { slot in
            slot.appID == appID &&
            slot.dayOfWeek == weekday &&
            currentMinutes >= (slot.startHour * 60 + slot.startMinute) &&
            currentMinutes < (slot.endHour * 60 + slot.endMinute)
        }
    }

    /// Returns remaining minutes in the current window, or nil if no window is open.
    static func remainingTime(for appID: UUID, in slots: [TimeBlock]) -> Int? {
        let now = Date()
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: now)
        let currentMinutes = calendar.component(.hour, from: now) * 60 + calendar.component(.minute, from: now)

        guard let activeSlot = slots.first(where: { slot in
            slot.appID == appID &&
            slot.dayOfWeek == weekday &&
            currentMinutes >= (slot.startHour * 60 + slot.startMinute) &&
            currentMinutes < (slot.endHour * 60 + slot.endMinute)
        }) else { return nil }

        let endMinutes = activeSlot.endHour * 60 + activeSlot.endMinute
        return endMinutes - currentMinutes
    }

    /// Returns the Date of the next window opening for a given app.
    static func nextWindowTime(for appID: UUID, in slots: [TimeBlock]) -> Date? {
        let now = Date()
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: now)
        let currentMinutes = calendar.component(.hour, from: now) * 60 + calendar.component(.minute, from: now)

        // Check today's remaining slots first
        let todaySlots = slots
            .filter { $0.appID == appID && $0.dayOfWeek == weekday }
            .sorted { ($0.startHour * 60 + $0.startMinute) < ($1.startHour * 60 + $1.startMinute) }

        for slot in todaySlots {
            let slotStart = slot.startHour * 60 + slot.startMinute
            if slotStart > currentMinutes {
                var comps = calendar.dateComponents([.year, .month, .day], from: now)
                comps.hour = slot.startHour
                comps.minute = slot.startMinute
                return calendar.date(from: comps)
            }
        }

        // Check tomorrow's first slot
        let tomorrowWeekday = (weekday % 7) + 1
        if let firstTomorrow = slots
            .filter({ $0.appID == appID && $0.dayOfWeek == tomorrowWeekday })
            .sorted(by: { ($0.startHour * 60 + $0.startMinute) < ($1.startHour * 60 + $1.startMinute) })
            .first,
           let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) {
            var comps = calendar.dateComponents([.year, .month, .day], from: tomorrow)
            comps.hour = firstTomorrow.startHour
            comps.minute = firstTomorrow.startMinute
            return calendar.date(from: comps)
        }

        return nil
    }
}
