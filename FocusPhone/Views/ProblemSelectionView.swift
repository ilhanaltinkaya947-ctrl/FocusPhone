import SwiftUI

struct ProblemSelectionView: View {
    @Binding var selectedProblems: [String]
    let onContinue: () -> Void

    private let options: [(id: String, label: String, emoji: String)] = [
        ("social_media", "Social Media", "📱"),
        ("youtube", "YouTube", "📺"),
        ("porn", "Porn", "🔞"),
        ("doom_scrolling", "Doom Scrolling", "📰"),
        ("messaging", "Messaging", "💬"),
        ("gaming", "Gaming", "🎮"),
        ("shopping", "Shopping", "🛒"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Text("What's eating your time?")
                .font(RawDog.Typography.title)
                .foregroundStyle(RawDog.Colors.textPrimary)

            Text("Select all that apply")
                .font(RawDog.Typography.subheadline)
                .foregroundStyle(RawDog.Colors.textSecondary)
                .padding(.top, 4)

            VStack(spacing: 10) {
                ForEach(options, id: \.id) { option in
                    let isSelected = selectedProblems.contains(option.id)

                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.spring(response: 0.3)) {
                            if isSelected {
                                selectedProblems.removeAll { $0 == option.id }
                            } else {
                                selectedProblems.append(option.id)
                            }
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Text(option.emoji)
                                .font(.title3)

                            Text(option.label)
                                .font(RawDog.Typography.headline)
                                .foregroundStyle(isSelected ? .black : RawDog.Colors.textPrimary)

                            Spacer()

                            if isSelected {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(.black)
                            }
                        }
                        .padding(.horizontal, 16)
                        .frame(height: 52)
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
                isEnabled: !selectedProblems.isEmpty
            ) {
                onContinue()
            }
            .padding(.bottom, 40)
        }
    }
}
