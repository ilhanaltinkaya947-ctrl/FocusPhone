import SwiftUI

struct CommitmentListView: View {
    @StateObject private var viewModel = CommitmentViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                RawDog.Colors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: RawDog.Spacing.md) {
                        // Mascot
                        RawDogMascot(state: viewModel.mascotState, size: 80)
                            .padding(.top, RawDog.Spacing.sm)

                        mascotMessage
                            .padding(.bottom, RawDog.Spacing.sm)

                        if viewModel.commitments.isEmpty {
                            emptyState
                        } else {
                            ForEach(viewModel.commitments) { commitment in
                                NavigationLink {
                                    CommitmentDetailView(commitment: commitment, viewModel: viewModel)
                                } label: {
                                    commitmentRow(commitment)
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Commitments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.isShowingCreateSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(RawDog.Colors.accent)
                    }
                }
            }
            .sheet(isPresented: $viewModel.isShowingCreateSheet) {
                CreateCommitmentView(viewModel: viewModel)
            }
            .fullScreenCover(isPresented: $viewModel.isShowingVerification) {
                VerificationView(viewModel: viewModel)
            }
            .onAppear {
                viewModel.loadCommitments()
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Views

    private var mascotMessage: some View {
        Group {
            switch viewModel.mascotState {
            case .proud, .amused:
                Text("All verified today. Good boy.")
                    .foregroundStyle(RawDog.Colors.approved)
            case .sideeye, .concerned:
                Text("You missed something today...")
                    .foregroundStyle(RawDog.Colors.windowClosed)
            case .neutral, .listening, .thinking:
                Text("What are you committing to?")
                    .foregroundStyle(RawDog.Colors.textSecondary)
            }
        }
        .font(RawDog.Typography.caption)
    }

    private var emptyState: some View {
        VStack(spacing: RawDog.Spacing.md) {
            Text("No commitments yet")
                .font(RawDog.Typography.headline)
                .foregroundStyle(RawDog.Colors.textSecondary)

            Text("Add your first commitment and RawDog will hold you accountable.")
                .font(RawDog.Typography.caption)
                .foregroundStyle(RawDog.Colors.textSecondary)
                .multilineTextAlignment(.center)

            RawDog.PillButton(title: "Add Commitment") {
                viewModel.isShowingCreateSheet = true
            }
        }
        .padding(.top, RawDog.Spacing.xl)
    }

    private func commitmentRow(_ commitment: Commitment) -> some View {
        let isVerified = viewModel.todayStatus(for: commitment) == .verified

        return RawDog.GlowCard(accentColor: isVerified ? RawDog.Colors.approved : RawDog.Colors.accent) {
            HStack(spacing: RawDog.Spacing.md) {
                // Emoji
                Text(commitment.emoji)
                    .font(.system(size: 32))

                // Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(commitment.title)
                        .font(RawDog.Typography.headline)
                        .foregroundStyle(RawDog.Colors.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        Text(timeString(commitment))
                            .font(RawDog.Typography.caption)
                            .foregroundStyle(RawDog.Colors.textSecondary)

                        let streak = viewModel.statsFor(commitment).currentStreak
                        if streak > 0 {
                            Text("\(streak)d")
                                .font(RawDog.Typography.caption2)
                                .foregroundStyle(RawDog.Colors.accent)
                        }
                    }
                }

                Spacer()

                // Today status + action
                todayStatusView(commitment)
            }
        }
    }

    @ViewBuilder
    private func todayStatusView(_ commitment: Commitment) -> some View {
        let status = viewModel.todayStatus(for: commitment)

        switch status {
        case .verified:
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundStyle(RawDog.Colors.approved)
        case .failed:
            Image(systemName: "xmark.circle.fill")
                .font(.title2)
                .foregroundStyle(RawDog.Colors.destructive)
        default:
            if commitment.isActive {
                Button {
                    viewModel.startVerification(for: commitment)
                } label: {
                    Image(systemName: commitment.verificationType == .photo ? "camera.fill" : "checkmark.circle")
                        .font(.title2)
                        .foregroundStyle(RawDog.Colors.accent)
                        .padding(8)
                        .background(RawDog.Colors.surfaceElevated, in: Circle())
                }
            } else {
                Text("OFF")
                    .font(RawDog.Typography.caption2)
                    .foregroundStyle(RawDog.Colors.textSecondary)
            }
        }
    }

    private func timeString(_ commitment: Commitment) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let time = formatter.string(from: commitment.scheduledTime)

        if commitment.isDailyCommitment {
            return "\(time) daily"
        }

        let dayNames = ["", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        let days = commitment.scheduledDays.sorted().compactMap { dayNames[safe: $0] }.joined(separator: ", ")
        return "\(time) \(days)"
    }
}

// Safe array subscript
private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
