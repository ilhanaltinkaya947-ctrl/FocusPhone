import SwiftUI

@MainActor
final class StatsViewModel: ObservableObject {
    @Published var todaySessions: [ModeSession] = []
    @Published var weekSessions: [ModeSession] = []
    @Published var activeMode: Mode?
    @Published var streakDays: Int = 0

    private let appState = AppState.shared

    func refresh() {
        todaySessions = appState.sessionsToday()
        weekSessions = appState.sessionsForWeek()
        activeMode = appState.activeMode
        streakDays = calculateStreak()
    }

    var todayTotalDuration: TimeInterval {
        todaySessions.reduce(0) { $0 + $1.duration }
    }

    var todayUsageByMode: [(modeName: String, colorHex: String, duration: TimeInterval)] {
        var usage: [UUID: (name: String, hex: String, duration: TimeInterval)] = [:]
        for session in todaySessions {
            let existing = usage[session.modeID] ?? (session.modeName, session.modeColorHex, 0)
            usage[session.modeID] = (existing.name, existing.hex, existing.duration + session.duration)
        }
        return usage.values.map { ($0.name, $0.hex, $0.duration) }
            .sorted { $0.duration > $1.duration }
    }

    var weeklyData: [(date: Date, totalMinutes: Double, segments: [(colorHex: String, minutes: Double)])] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return (0..<7).reversed().map { daysAgo in
            guard let day = calendar.date(byAdding: .day, value: -daysAgo, to: today) else {
                return (today, 0.0, [(colorHex: String, minutes: Double)]())
            }
            let nextDay = calendar.date(byAdding: .day, value: 1, to: day)!
            let daySessions = weekSessions.filter { $0.startDate >= day && $0.startDate < nextDay }

            var segments: [String: Double] = [:]
            var total: Double = 0
            for session in daySessions {
                let mins = session.duration / 60
                segments[session.modeColorHex, default: 0] += mins
                total += mins
            }

            let sortedSegments = segments.map { (colorHex: $0.key, minutes: $0.value) }
                .sorted { $0.minutes > $1.minutes }

            return (day, total, sortedSegments)
        }
    }

    private func calculateStreak() -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var streak = 0

        for daysAgo in 0..<365 {
            guard let day = calendar.date(byAdding: .day, value: -daysAgo, to: today) else { break }
            let nextDay = calendar.date(byAdding: .day, value: 1, to: day)!
            let hasSessions = appState.modeSessions.contains {
                $0.startDate >= day && $0.startDate < nextDay
            }
            if hasSessions {
                streak += 1
            } else if daysAgo > 0 {
                break
            }
        }

        return streak
    }

    func formatDuration(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}
