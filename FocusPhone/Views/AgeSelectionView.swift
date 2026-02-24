import SwiftUI

struct AgeSelectionView: View {
    @Binding var selectedAge: String?
    let onContinue: () -> Void

    private let ageOptions = ["13-17", "18-24", "25-34", "35-44", "45+"]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Text("How old are you?")
                .font(RawDog.Typography.title)
                .foregroundStyle(RawDog.Colors.textPrimary)

            Text("This helps us personalize your experience")
                .font(RawDog.Typography.subheadline)
                .foregroundStyle(RawDog.Colors.textSecondary)
                .padding(.top, 4)

            VStack(spacing: 10) {
                ForEach(ageOptions, id: \.self) { age in
                    selectionPill(title: age, isSelected: selectedAge == age) {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.spring(response: 0.3)) {
                            selectedAge = age
                        }
                        // Auto-advance after delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            onContinue()
                        }
                    }
                }
            }
            .padding(.horizontal, 32)
            .padding(.top, 32)

            Spacer()
        }
    }

    private func selectionPill(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(RawDog.Typography.headline)
                .foregroundStyle(isSelected ? .black : RawDog.Colors.textPrimary)
                .frame(maxWidth: .infinity)
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
