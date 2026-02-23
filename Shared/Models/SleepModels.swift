import Foundation

// MARK: - Simple Time

/// Simple hour:minute representation for Codable persistence
struct SimpleTime: Codable, Equatable {
    var hour: Int
    var minute: Int

    var totalMinutes: Int { hour * 60 + minute }

    init(hour: Int, minute: Int) {
        self.hour = ((hour % 24) + 24) % 24
        self.minute = ((minute % 60) + 60) % 60
    }

    init(totalMinutes: Int) {
        let normalized = ((totalMinutes % 1440) + 1440) % 1440
        self.hour = normalized / 60
        self.minute = normalized % 60
    }

    var dateComponents: DateComponents {
        DateComponents(hour: hour, minute: minute)
    }

    var formatted: String {
        String(format: "%02d:%02d", hour, minute)
    }
}

// MARK: - Sleep Schedule

struct SleepSchedule: Codable, Equatable {
    var bedtime: SimpleTime        // e.g. 22:30
    var wakeTime: SimpleTime       // e.g. 05:30
    var sleepDays: [Int]           // 1=Sunday..7=Saturday, default all
    var morningNoPhoneMinutes: Int // phone-free after wake
    var nightNoPhoneMinutes: Int   // phone-free before sleep (wind-down)

    init(
        bedtime: SimpleTime = SimpleTime(hour: 22, minute: 30),
        wakeTime: SimpleTime = SimpleTime(hour: 6, minute: 0),
        sleepDays: [Int] = [1, 2, 3, 4, 5, 6, 7],
        morningNoPhoneMinutes: Int = 30,
        nightNoPhoneMinutes: Int = 30
    ) {
        self.bedtime = bedtime
        self.wakeTime = wakeTime
        self.sleepDays = sleepDays
        self.morningNoPhoneMinutes = morningNoPhoneMinutes
        self.nightNoPhoneMinutes = nightNoPhoneMinutes
    }

    /// Wind-down start time (nightNoPhoneMinutes before bedtime)
    var windDownTime: SimpleTime {
        let totalMinutes = bedtime.totalMinutes - nightNoPhoneMinutes
        return SimpleTime(totalMinutes: totalMinutes)
    }

    /// Morning routine end time (morningNoPhoneMinutes after wake)
    var morningRoutineEndTime: SimpleTime {
        let totalMinutes = wakeTime.totalMinutes + morningNoPhoneMinutes
        return SimpleTime(totalMinutes: totalMinutes)
    }

    var sleepReminderTime: SimpleTime {
        let totalMinutes = bedtime.totalMinutes - 15
        return SimpleTime(totalMinutes: totalMinutes)
    }
}
