import SwiftUI

struct OccupationView: View {
    @Binding var selectedOccupation: String?
    let onContinue: () -> Void

    private let options: [(id: String, label: String, emoji: String)] = [
        ("student", "Student", "📚"),
        ("employee", "Employee", "💼"),
        ("freelance", "Freelancer", "🎨"),
        ("entrepreneur", "Entrepreneur", "🚀"),
        ("creative", "Creative", "🎬"),
        ("unemployed", "Between Jobs", "🔍"),
        ("other", "Other", "🌐"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Text("What do you do?")
                .font(RawDog.Typography.title)
                .foregroundStyle(RawDog.Colors.textPrimary)

            Text("We'll tailor restrictions to your lifestyle")
                .font(RawDog.Typography.subheadline)
                .foregroundStyle(RawDog.Colors.textSecondary)
                .padding(.top, 4)

            VStack(spacing: 10) {
                ForEach(options, id: \.id) { option in
                    let isSelected = selectedOccupation == option.id

                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.spring(response: 0.3)) {
                            selectedOccupation = option.id
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            onContinue()
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
        }
    }
}
