import Foundation

// MARK: - Commitment

struct Commitment: Codable, Identifiable, Equatable {
    let id: UUID
    var title: String
    var emoji: String
    var scheduledTime: Date
    var scheduledDays: Set<Int> // 1=Sun, 2=Mon, ... 7=Sat (Calendar weekday)
    var reminderMinutesBefore: Int
    var verificationType: VerificationType
    var category: CommitmentCategory
    var isActive: Bool
    let createdAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        emoji: String,
        scheduledTime: Date,
        scheduledDays: Set<Int> = Set(1...7),
        reminderMinutesBefore: Int = 30,
        verificationType: VerificationType = .photo,
        category: CommitmentCategory,
        isActive: Bool = true,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.emoji = emoji
        self.scheduledTime = scheduledTime
        self.scheduledDays = scheduledDays
        self.reminderMinutesBefore = reminderMinutesBefore
        self.verificationType = verificationType
        self.category = category
        self.isActive = isActive
        self.createdAt = createdAt
    }

    var isDailyCommitment: Bool {
        scheduledDays.count == 7
    }

    var scheduledHour: Int {
        Calendar.current.component(.hour, from: scheduledTime)
    }

    var scheduledMinute: Int {
        Calendar.current.component(.minute, from: scheduledTime)
    }
}

// MARK: - Enums

enum VerificationType: String, Codable, CaseIterable {
    case photo
    case manual
}

enum CommitmentCategory: String, Codable, CaseIterable, Identifiable {
    case gym
    case study
    case work
    case outdoor
    case meditation
    case custom

    var id: String { rawValue }

    var defaultEmoji: String {
        switch self {
        case .gym: return "💪"
        case .study: return "📚"
        case .work: return "💻"
        case .outdoor: return "🌿"
        case .meditation: return "🧘"
        case .custom: return "🎯"
        }
    }

    var displayName: String {
        switch self {
        case .gym: return "Gym"
        case .study: return "Study"
        case .work: return "Deep Work"
        case .outdoor: return "Outdoor"
        case .meditation: return "Meditation"
        case .custom: return "Custom"
        }
    }
}

// MARK: - Commitment Log

struct CommitmentLog: Codable, Identifiable, Equatable {
    let id: UUID
    let commitmentId: UUID
    let date: Date
    var status: CommitmentLogStatus
    var photoFilename: String?
    var aiVerificationResult: AIVerificationResult?
    var verifiedAt: Date?

    init(
        id: UUID = UUID(),
        commitmentId: UUID,
        date: Date = Date(),
        status: CommitmentLogStatus = .pending,
        photoFilename: String? = nil,
        aiVerificationResult: AIVerificationResult? = nil,
        verifiedAt: Date? = nil
    ) {
        self.id = id
        self.commitmentId = commitmentId
        self.date = date
        self.status = status
        self.photoFilename = photoFilename
        self.aiVerificationResult = aiVerificationResult
        self.verifiedAt = verifiedAt
    }
}

enum CommitmentLogStatus: String, Codable {
    case pending
    case verified
    case failed
    case skipped
}

// MARK: - AI Verification Result

struct AIVerificationResult: Codable, Equatable {
    let isVerified: Bool
    let confidence: Double
    let detectedContext: String?
    let failureReason: String?
}

// MARK: - Habit Stats

struct HabitStats: Equatable {
    let totalScheduled: Int
    let totalVerified: Int
    let currentStreak: Int
    let bestStreak: Int
    let completionRate: Double
    let weekdayBreakdown: [Int: Int] // weekday -> count verified
    let trend: HabitTrend

    static let empty = HabitStats(
        totalScheduled: 0,
        totalVerified: 0,
        currentStreak: 0,
        bestStreak: 0,
        completionRate: 0,
        weekdayBreakdown: [:],
        trend: .steady
    )
}

enum HabitTrend: String {
    case improving
    case declining
    case steady
}
