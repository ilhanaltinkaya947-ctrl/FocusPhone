import SwiftUI

struct StrictnessPickerView: View {
    let onStrictnessSelected: (String) -> Void
    let onContinue: () -> Void

    @State private var selectedLevel: String?
    @State private var mascotState: MascotState = .neutral

    private let levels: [(id: String, icon: String, title: String, description: String)] = [
        ("moderate", "dial.low.fill", "Moderate", "Block the worst offenders. Keep some access with time windows."),
        ("strict", "dial.medium.fill", "Strict", "Block most distractions. Tight time windows. No App Store."),
        ("nuclear", "dial.high.fill", "Nuclear", "Everything locked. Bare minimum access. Full discipline mode."),
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            AnimatedMascot(state: mascotState, size: 100)
                .padding(.bottom, 8)

            Text("How strict?")
                .font(RawDog.Typography.title2)
                .foregroundStyle(RawDog.Colors.textPrimary)

            Text("You can always adjust later. But start honest.")
                .font(RawDog.Typography.subheadline)
                .foregroundStyle(RawDog.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.top, 4)
                .padding(.horizontal, 40)

            VStack(spacing: 10) {
                ForEach(levels, id: \.id) { level in
                    levelRow(level)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)

            Spacer()

            if selectedLevel != nil {
                RawDog.PillButton(title: "Continue") {
                    onContinue()
                }
                .transition(.opacity)
                .padding(.bottom, 40)
            }
        }
    }

    private func levelRow(_ level: (id: String, icon: String, title: String, description: String)) -> some View {
        let isSelected = selectedLevel == level.id

        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.3)) {
                selectedLevel = level.id
                switch level.id {
                case "moderate": mascotState = .amused
                case "strict": mascotState = .proud
                case "nuclear": mascotState = .sideeye
                default: break
                }
            }
            onStrictnessSelected(level.id)
        } label: {
            HStack(spacing: 14) {
                Image(systemName: level.icon)
                    .font(.system(size: 22))
                    .foregroundStyle(isSelected ? RawDog.Colors.background : RawDog.Colors.accent)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(level.title)
                        .font(RawDog.Typography.headline)
                        .foregroundStyle(isSelected ? RawDog.Colors.background : RawDog.Colors.textPrimary)

                    Text(level.description)
                        .font(RawDog.Typography.caption)
                        .foregroundStyle(isSelected ? RawDog.Colors.background.opacity(0.7) : RawDog.Colors.textSecondary)
                        .lineLimit(2)
                }

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
        }
    }
}
