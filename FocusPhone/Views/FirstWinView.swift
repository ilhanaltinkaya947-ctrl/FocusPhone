import SwiftUI

struct FirstWinView: View {
    let selections: OnboardingSelections
    @Binding var firstCommitment: Commitment?
    let onContinue: () -> Void

    @State private var selectedIndex: Int?

    private var suggestions: [(emoji: String, title: String, category: CommitmentCategory)] {
        selections.suggestedCommitments()
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Text("Pick Your First Win")
                .font(RawDog.Typography.title)
                .foregroundStyle(RawDog.Colors.textPrimary)

            Text("Start with one commitment.\nYou can add more later.")
                .font(RawDog.Typography.subheadline)
                .foregroundStyle(RawDog.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.top, 4)

            VStack(spacing: 12) {
                ForEach(Array(suggestions.enumerated()), id: \.offset) { index, suggestion in
                    let isSelected = selectedIndex == index

                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.spring(response: 0.3)) {
                            selectedIndex = index
                        }
                        // Create the commitment
                        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
                        components.hour = 7
                        components.minute = 0
                        let scheduledTime = Calendar.current.date(from: components) ?? Date()

                        firstCommitment = Commitment(
                            title: suggestion.title,
                            emoji: suggestion.emoji,
                            scheduledTime: scheduledTime,
                            scheduledDays: Set(1...7),
                            category: suggestion.category
                        )
                    } label: {
                        HStack(spacing: 14) {
                            Text(suggestion.emoji)
                                .font(.system(size: 28))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(suggestion.title)
                                    .font(RawDog.Typography.headline)
                                    .foregroundStyle(isSelected ? .black : RawDog.Colors.textPrimary)

                                Text("Daily at 7:00 AM")
                                    .font(RawDog.Typography.caption)
                                    .foregroundStyle(isSelected ? .black.opacity(0.6) : RawDog.Colors.textSecondary)
                            }

                            Spacer()

                            if isSelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundStyle(.black)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(
                            isSelected ? Color.white : RawDog.Colors.cardBackground,
                            in: RoundedRectangle(cornerRadius: 14)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(
                                    isSelected ? Color.clear : RawDog.Colors.borderSubtle,
                                    lineWidth: 1
                                )
                        )
                    }
                }
            }
            .padding(.horizontal, 32)
            .padding(.top, 32)

            Spacer()

            RawDog.OnboardingButton(
                title: "Continue",
                isEnabled: selectedIndex != nil
            ) {
                onContinue()
            }
            .padding(.bottom, 40)
        }
    }
}
