import SwiftUI

struct GoalsRevealView: View {
    let selections: OnboardingSelections
    let onContinue: () -> Void

    @State private var revealedItems = 0

    private var personalizedGoals: [(emoji: String, text: String)] {
        var goals: [(String, String)] = []

        // Derive from problems
        if selections.problems.contains("social_media") {
            goals.append(("📵", "Reclaim \(selections.yearsPhoneWillSteal() / 3) years from social media"))
        }
        if selections.problems.contains("porn") {
            goals.append(("🧠", "Rewire your brain's reward system"))
        }
        if selections.problems.contains("doom_scrolling") {
            goals.append(("🎯", "Replace scrolling with intentional action"))
        }

        // Derive from goals
        if selections.goals.contains("gym") {
            goals.append(("💪", "Build a consistent gym routine"))
        }
        if selections.goals.contains("study") {
            goals.append(("📚", "Deep focus study sessions daily"))
        }
        if selections.goals.contains("business") {
            goals.append(("🚀", "Channel energy into building"))
        }

        // Take top 3
        if goals.count > 3 { goals = Array(goals.prefix(3)) }

        // Fallback
        if goals.isEmpty {
            goals = [
                ("🎯", "Take control of your screen time"),
                ("⏰", "Build productive daily habits"),
                ("🏆", "Prove to yourself you can do it"),
            ]
        }

        return goals
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Text("Your Personalized Goals")
                .font(RawDog.Typography.title)
                .foregroundStyle(RawDog.Colors.textPrimary)
                .padding(.bottom, RawDog.Spacing.xl)

            VStack(spacing: RawDog.Spacing.md) {
                ForEach(Array(personalizedGoals.enumerated()), id: \.offset) { index, goal in
                    HStack(spacing: 16) {
                        Text(goal.emoji)
                            .font(.system(size: 32))

                        Text(goal.text)
                            .font(RawDog.Typography.headline)
                            .foregroundStyle(RawDog.Colors.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(16)
                    .background(RawDog.Colors.cardBackground, in: RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(RawDog.Colors.borderSubtle, lineWidth: 1)
                    )
                    .opacity(revealedItems > index ? 1 : 0)
                    .offset(y: revealedItems > index ? 0 : 20)
                    .animation(
                        .spring(response: 0.5, dampingFraction: 0.7).delay(Double(index) * 0.5),
                        value: revealedItems
                    )
                }
            }
            .padding(.horizontal, 32)

            Spacer()

            RawDog.OnboardingButton(title: "Continue", isEnabled: revealedItems >= personalizedGoals.count) {
                onContinue()
            }
            .padding(.bottom, 40)
        }
        .onAppear {
            revealedItems = personalizedGoals.count
        }
    }
}
