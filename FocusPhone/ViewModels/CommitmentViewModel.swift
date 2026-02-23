import SwiftUI

@MainActor
class CommitmentViewModel: ObservableObject {

    // MARK: - Published State

    @Published var commitments: [Commitment] = []
    @Published var selectedCommitment: Commitment?
    @Published var isShowingVerification = false
    @Published var isShowingCreateSheet = false
    @Published var verificationImage: UIImage?
    @Published var verificationResult: AIVerificationResult?
    @Published var isVerifying = false
    @Published var errorMessage: String?

    // Creation form state
    @Published var newTitle = ""
    @Published var newCategory: CommitmentCategory = .gym
    @Published var newScheduledTime = defaultScheduledTime
    @Published var newSelectedDays: Set<Int> = Set(1...7)
    @Published var newVerificationType: VerificationType = .photo

    init() {
        loadCommitments()
    }

    private static var defaultScheduledTime: Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = 7
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }

    // MARK: - CRUD

    func loadCommitments() {
        commitments = CommitmentStore.commitments
    }

    func createCommitment() {
        let title = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }

        let commitment = Commitment(
            title: title,
            emoji: newCategory.defaultEmoji,
            scheduledTime: newScheduledTime,
            scheduledDays: newSelectedDays,
            verificationType: newVerificationType,
            category: newCategory
        )

        CommitmentStore.addCommitment(commitment)
        CommitmentNotificationService.scheduleNotifications(for: commitment)
        loadCommitments()
        resetForm()
    }

    func toggleActive(_ commitment: Commitment) {
        var updated = commitment
        updated.isActive.toggle()
        CommitmentStore.updateCommitment(updated)

        if updated.isActive {
            CommitmentNotificationService.scheduleNotifications(for: updated)
        } else {
            CommitmentNotificationService.cancelNotifications(for: updated.id)
        }

        loadCommitments()
    }

    func deleteCommitment(_ commitment: Commitment) {
        CommitmentNotificationService.cancelNotifications(for: commitment.id)
        CommitmentStore.deleteCommitment(id: commitment.id)
        loadCommitments()
    }

    // MARK: - Verification

    func startVerification(for commitment: Commitment) {
        selectedCommitment = commitment
        verificationImage = nil
        verificationResult = nil
        errorMessage = nil
        isShowingVerification = true
    }

    func submitVerification() {
        guard let commitment = selectedCommitment,
              let image = verificationImage else { return }

        isVerifying = true
        errorMessage = nil

        if commitment.verificationType == .manual {
            markManualComplete(commitment)
            return
        }

        Task {
            do {
                let result = try await AIVerificationService.shared.verifyPhoto(
                    image: image,
                    commitment: commitment
                )
                verificationResult = result

                if result.isVerified {
                    completeVerification(commitment: commitment, image: image, result: result)
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            isVerifying = false
        }
    }

    func markManualComplete(_ commitment: Commitment) {
        var log = CommitmentStore.todayLog(for: commitment.id) ?? CommitmentLog(commitmentId: commitment.id)
        log.status = .verified
        log.verifiedAt = Date()
        CommitmentStore.saveLog(log)

        CommitmentNotificationService.cancelFailureFollowUp(for: commitment.id)
        grantFreedomWindow()
        isVerifying = false
        loadCommitments()
    }

    func statsFor(_ commitment: Commitment) -> HabitStats {
        CommitmentStore.stats(for: commitment.id)
    }

    func todayStatus(for commitment: Commitment) -> CommitmentLogStatus? {
        CommitmentStore.todayLog(for: commitment.id)?.status
    }

    // MARK: - Mascot State

    var mascotState: MascotState {
        let todayCommitments = commitments.filter { $0.isActive && isScheduledToday($0) }
        guard !todayCommitments.isEmpty else { return .neutral }

        let allVerified = todayCommitments.allSatisfy {
            CommitmentStore.todayLog(for: $0.id)?.status == .verified
        }
        if allVerified { return .proud }

        let anyFailed = todayCommitments.contains {
            CommitmentStore.todayLog(for: $0.id)?.status == .failed
        }
        if anyFailed { return .sideeye }

        return .neutral
    }

    // MARK: - Private

    private func completeVerification(commitment: Commitment, image: UIImage, result: AIVerificationResult) {
        let photoFilename = CommitmentStore.savePhoto(image, for: commitment.id)

        var log = CommitmentStore.todayLog(for: commitment.id) ?? CommitmentLog(commitmentId: commitment.id)
        log.status = .verified
        log.photoFilename = photoFilename
        log.aiVerificationResult = result
        log.verifiedAt = Date()
        CommitmentStore.saveLog(log)

        CommitmentNotificationService.cancelFailureFollowUp(for: commitment.id)

        // Streak milestone notifications (7, 14, 21, 30, 50, 100...)
        let streak = CommitmentStore.stats(for: commitment.id).currentStreak
        let milestones = [7, 14, 21, 30, 50, 75, 100, 150, 200, 365]
        if milestones.contains(streak) {
            CommitmentNotificationService.scheduleStreakMilestone(for: commitment, streak: streak)
        }

        grantFreedomWindow()
        loadCommitments()
    }

    private func grantFreedomWindow() {
        // Grant 45 min freedom for all timed window apps
        for app in AppState.shared.timedWindowStates {
            RestrictionEngine.grantExtension(appID: app.id, minutes: 45)
        }
    }

    private func resetForm() {
        newTitle = ""
        newCategory = .gym
        newScheduledTime = Self.defaultScheduledTime
        newSelectedDays = Set(1...7)
        newVerificationType = .photo
    }

    private func isScheduledToday(_ commitment: Commitment) -> Bool {
        let todayWeekday = Calendar.current.component(.weekday, from: Date())
        return commitment.scheduledDays.contains(todayWeekday)
    }
}
