import Foundation
import UIKit

enum CommitmentStore {

    private static let commitmentsKey = "commitments"
    private static let commitmentLogsKey = "commitmentLogs"

    // MARK: - Commitments CRUD

    static var commitments: [Commitment] {
        get { AppState.shared.load(forKey: commitmentsKey) ?? [] }
        set { AppState.shared.save(newValue, forKey: commitmentsKey) }
    }

    static func addCommitment(_ commitment: Commitment) {
        var list = commitments
        list.append(commitment)
        commitments = list
    }

    static func updateCommitment(_ commitment: Commitment) {
        var list = commitments
        if let index = list.firstIndex(where: { $0.id == commitment.id }) {
            list[index] = commitment
            commitments = list
        }
    }

    static func deleteCommitment(id: UUID) {
        var list = commitments
        list.removeAll { $0.id == id }
        commitments = list

        // Clean up logs
        var allLogs = logs
        allLogs.removeAll { $0.commitmentId == id }
        logs = allLogs
    }

    // MARK: - Logs

    static var logs: [CommitmentLog] {
        get { AppState.shared.load(forKey: commitmentLogsKey) ?? [] }
        set { AppState.shared.save(newValue, forKey: commitmentLogsKey) }
    }

    static func saveLog(_ log: CommitmentLog) {
        var allLogs = logs
        if let index = allLogs.firstIndex(where: { $0.id == log.id }) {
            allLogs[index] = log
        } else {
            allLogs.append(log)
        }
        logs = allLogs
    }

    static func logsForCommitment(id: UUID) -> [CommitmentLog] {
        logs.filter { $0.commitmentId == id }
            .sorted { $0.date > $1.date }
    }

    static func todayLog(for commitmentId: UUID) -> CommitmentLog? {
        let calendar = Calendar.current
        return logs.first {
            $0.commitmentId == commitmentId && calendar.isDateInToday($0.date)
        }
    }

    // MARK: - Stats

    static func stats(for commitmentId: UUID) -> HabitStats {
        let commitmentLogs = logsForCommitment(id: commitmentId)
        guard !commitmentLogs.isEmpty else { return .empty }

        let totalScheduled = commitmentLogs.count
        let verifiedLogs = commitmentLogs.filter { $0.status == .verified }
        let totalVerified = verifiedLogs.count

        let completionRate = totalScheduled > 0
            ? Double(totalVerified) / Double(totalScheduled)
            : 0

        // Streak calculation (most recent consecutive verified days)
        let calendar = Calendar.current
        let sortedByDate = commitmentLogs.sorted { $0.date > $1.date }
        var currentStreak = 0
        var bestStreak = 0
        var tempStreak = 0
        var lastDate: Date?

        for log in sortedByDate {
            let logDay = calendar.startOfDay(for: log.date)
            if log.status == .verified {
                if let prev = lastDate {
                    let diff = calendar.dateComponents([.day], from: logDay, to: prev).day ?? 0
                    if diff <= 1 {
                        tempStreak += 1
                    } else {
                        bestStreak = max(bestStreak, tempStreak)
                        tempStreak = 1
                    }
                } else {
                    tempStreak = 1
                }
                lastDate = logDay
            } else {
                if currentStreak == 0 { currentStreak = tempStreak }
                bestStreak = max(bestStreak, tempStreak)
                tempStreak = 0
                lastDate = calendar.startOfDay(for: log.date)
            }
        }
        if currentStreak == 0 { currentStreak = tempStreak }
        bestStreak = max(bestStreak, tempStreak)

        // Weekday breakdown
        var weekdayBreakdown: [Int: Int] = [:]
        for log in verifiedLogs {
            let weekday = calendar.component(.weekday, from: log.date)
            weekdayBreakdown[weekday, default: 0] += 1
        }

        // Trend: compare last 7 days vs previous 7 days
        let now = Date()
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: now)!
        let fourteenDaysAgo = calendar.date(byAdding: .day, value: -14, to: now)!

        let recentVerified = verifiedLogs.filter { $0.date >= sevenDaysAgo }.count
        let previousVerified = verifiedLogs.filter { $0.date >= fourteenDaysAgo && $0.date < sevenDaysAgo }.count

        let trend: HabitTrend
        if recentVerified > previousVerified {
            trend = .improving
        } else if recentVerified < previousVerified {
            trend = .declining
        } else {
            trend = .steady
        }

        return HabitStats(
            totalScheduled: totalScheduled,
            totalVerified: totalVerified,
            currentStreak: currentStreak,
            bestStreak: bestStreak,
            completionRate: completionRate,
            weekdayBreakdown: weekdayBreakdown,
            trend: trend
        )
    }

    // MARK: - Photo Storage

    static var photosDirectory: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("CommitmentPhotos", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static func savePhoto(_ image: UIImage, for commitmentId: UUID) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.5) else { return nil }

        // Compress further if needed to stay under 500KB
        var compressedData = data
        var quality: CGFloat = 0.4
        while compressedData.count > 500_000, quality > 0.1 {
            compressedData = image.jpegData(compressionQuality: quality) ?? data
            quality -= 0.1
        }

        let filename = "\(commitmentId.uuidString)_\(Int(Date().timeIntervalSince1970)).jpg"
        let fileURL = photosDirectory.appendingPathComponent(filename)

        do {
            try compressedData.write(to: fileURL)
            return filename
        } catch {
            return nil
        }
    }

    static func loadPhoto(filename: String) -> UIImage? {
        let fileURL = photosDirectory.appendingPathComponent(filename)
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return UIImage(data: data)
    }

    static func deletePhoto(filename: String) {
        let fileURL = photosDirectory.appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: fileURL)
    }

    static func cleanupOldPhotos(olderThan days: Int = 30) {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(at: photosDirectory, includingPropertiesForKeys: [.creationDateKey]) else { return }

        for fileURL in files {
            guard let attrs = try? fm.attributesOfItem(atPath: fileURL.path),
                  let created = attrs[.creationDate] as? Date,
                  created < cutoff else { continue }
            try? fm.removeItem(at: fileURL)
        }
    }
}
