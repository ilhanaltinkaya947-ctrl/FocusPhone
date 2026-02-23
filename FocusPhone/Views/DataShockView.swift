import SwiftUI

struct DataShockView: View {
    let onReactionSelected: (String) -> Void
    let onContinue: () -> Void

    @State private var revealedCards = 0
    @State private var mascotState: MascotState = .neutral
    @State private var selectedReaction: String?

    // TODO: Replace with real DeviceActivityReport data when extension target is added
    private let mockStats: [(icon: String, label: String, value: String, color: Color)] = [
        ("clock.fill", "Daily Average", "4h 23m", RawDog.Colors.destructive),
        ("hand.tap.fill", "Daily Pickups", "96 times", RawDog.Colors.windowClosed),
        ("app.fill", "Top App Time", "2h 11m", RawDog.Colors.destructive),
        ("bell.fill", "Notifications", "247 / day", RawDog.Colors.windowClosed),
    ]

    private let reactionChips = ["That's brutal", "Sounds about right", "It's worse than I thought", "I don't care, help me fix it"]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            AnimatedMascot(state: mascotState, size: 100)
                .padding(.bottom, 8)

            Text("Let's face it.")
                .font(RawDog.Typography.title2)
                .foregroundStyle(RawDog.Colors.textPrimary)

            Text("This is what your phone is doing to you.")
                .font(RawDog.Typography.subheadline)
                .foregroundStyle(RawDog.Colors.textSecondary)
                .padding(.top, 4)

            // Stats grid with staggered reveal
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(Array(mockStats.enumerated()), id: \.offset) { index, stat in
                    statCard(icon: stat.icon, label: stat.label, value: stat.value, color: stat.color)
                        .opacity(revealedCards > index ? 1 : 0)
                        .offset(y: revealedCards > index ? 0 : 20)
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.7).delay(Double(index) * 0.3),
                            value: revealedCards
                        )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)

            Spacer().frame(height: 24)

            // Reaction chips
            if revealedCards >= mockStats.count {
                SuggestionChipsView(chips: reactionChips) { chip in
                    selectedReaction = chip
                    onReactionSelected(chip)
                    mascotState = chip.contains("worse") ? .concerned : .amused
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            Spacer()

            if selectedReaction != nil {
                RawDog.PillButton(title: "Continue") {
                    onContinue()
                }
                .transition(.opacity)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            // Staggered card reveal
            revealedCards = mockStats.count
            // Mascot reacts after all cards shown
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(mockStats.count) * 0.3 + 0.3) {
                withAnimation { mascotState = .sideeye }
            }
        }
    }

    private func statCard(icon: String, label: String, value: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundStyle(color)

            Text(value)
                .font(RawDog.Typography.title2)
                .foregroundStyle(RawDog.Colors.textPrimary)

            Text(label)
                .font(RawDog.Typography.caption)
                .foregroundStyle(RawDog.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(RawDog.Colors.surface, in: RoundedRectangle(cornerRadius: RawDog.Radius.card))
    }
}
