import SwiftUI

struct GoalSelectionView: View {
    let onGoalSelected: (String) -> Void
    let onContinue: () -> Void

    @State private var selectedGoal: String?
    @State private var mascotState: MascotState = .listening

    private let goals: [(emoji: String, label: String, presetID: String)] = [
        ("📱", "Stop social media addiction", "social_media_addict"),
        ("🔞", "Break free from porn", "porn_addiction_recovery"),
        ("📰", "End doom scrolling", "doom_scrolling_recovery"),
        ("💼", "Focus while working from home", "work_from_home_focus"),
        ("📚", "Focus on studying", "student_focus"),
        ("🧘", "Full digital minimalism", "digital_minimalist"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            AnimatedMascot(state: mascotState, size: 100)
                .padding(.bottom, 8)

            Text("What's your goal?")
                .font(RawDog.Typography.title2)
                .foregroundStyle(RawDog.Colors.textPrimary)

            Text("Pick the one that hits closest to home.")
                .font(RawDog.Typography.subheadline)
                .foregroundStyle(RawDog.Colors.textSecondary)
                .padding(.top, 4)

            VStack(spacing: 8) {
                ForEach(goals, id: \.presetID) { goal in
                    goalRow(goal)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)

            Spacer()

            if selectedGoal != nil {
                RawDog.PillButton(title: "Continue") {
                    onContinue()
                }
                .transition(.opacity)
                .padding(.bottom, 40)
            }
        }
    }

    private func goalRow(_ goal: (emoji: String, label: String, presetID: String)) -> some View {
        let isSelected = selectedGoal == goal.presetID

        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.3)) {
                selectedGoal = goal.presetID
                mascotState = .proud
            }
            onGoalSelected(goal.presetID)
        } label: {
            HStack(spacing: 12) {
                Text(goal.emoji)
                    .font(.title3)

                Text(goal.label)
                    .font(RawDog.Typography.subheadline)
                    .foregroundStyle(RawDog.Colors.textPrimary)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(RawDog.Colors.background)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                isSelected ? RawDog.Colors.accent : RawDog.Colors.surface,
                in: RoundedRectangle(cornerRadius: 12)
            )
            .foregroundStyle(isSelected ? RawDog.Colors.background : RawDog.Colors.textPrimary)
        }
    }
}
