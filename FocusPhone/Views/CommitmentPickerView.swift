import SwiftUI

struct CommitmentPickerView: View {
    let onCommitmentSet: (Int) -> Void
    let onContinue: () -> Void

    @State private var selectedDays: Int?
    @State private var mascotState: MascotState = .neutral

    private let options: [(days: Int, label: String, subtitle: String)] = [
        (3, "3 days", "Just testing the waters"),
        (7, "1 week", "Solid starting point"),
        (14, "2 weeks", "Now we're talking"),
        (30, "30 days", "Full reset mode"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            AnimatedMascot(state: mascotState, size: 100)
                .padding(.bottom, 8)

            Text("How long are you committing?")
                .font(RawDog.Typography.title2)
                .foregroundStyle(RawDog.Colors.textPrimary)

            Text(mascotCommentary)
                .font(RawDog.Typography.subheadline)
                .foregroundStyle(RawDog.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.top, 4)
                .padding(.horizontal, 40)
                .animation(.easeInOut(duration: 0.2), value: selectedDays)

            HStack(spacing: 10) {
                ForEach(options, id: \.days) { option in
                    durationButton(option)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 32)

            Spacer()

            if selectedDays != nil {
                RawDog.PillButton(title: "Continue") {
                    onContinue()
                }
                .transition(.opacity)
                .padding(.bottom, 40)
            }
        }
    }

    private var mascotCommentary: String {
        switch selectedDays {
        case 3: "better than nothing i guess"
        case 7: "a week's enough to feel the difference"
        case 14: "two weeks. you mean business"
        case 30: "full month. respect."
        default: "Pick a commitment length."
        }
    }

    private func durationButton(_ option: (days: Int, label: String, subtitle: String)) -> some View {
        let isSelected = selectedDays == option.days

        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.3)) {
                selectedDays = option.days
                mascotState = option.days >= 14 ? .proud : .amused
            }
            onCommitmentSet(option.days)
        } label: {
            VStack(spacing: 4) {
                Text(option.label)
                    .font(RawDog.Typography.headline)
                    .foregroundStyle(isSelected ? RawDog.Colors.background : RawDog.Colors.textPrimary)

                Text(option.subtitle)
                    .font(RawDog.Typography.caption)
                    .foregroundStyle(isSelected ? RawDog.Colors.background.opacity(0.7) : RawDog.Colors.textSecondary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                isSelected ? RawDog.Colors.accent : RawDog.Colors.surface,
                in: RoundedRectangle(cornerRadius: 12)
            )
        }
    }
}
