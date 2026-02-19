import SwiftUI

struct LifeAreaPickerView: View {
    @ObservedObject var viewModel: AIOnboardingViewModel
    var onContinue: () -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Text("Who do you want\nto become?")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)

            Text("Choose 3-5 areas that matter most")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top, 4)

            Spacer().frame(height: 32)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(LifeArea.allCases) { area in
                    let isSelected = viewModel.selectedLifeAreas.contains(area)
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            viewModel.toggleLifeArea(area)
                        }
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: area.icon)
                                .font(.system(size: 28))
                                .foregroundStyle(Color(hex: area.colorHex))

                            Text(area.displayName)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)

                            Text(area.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(isSelected ? Color(hex: area.colorHex).opacity(0.15) : Color(.systemGray6))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(
                                    isSelected ? Color(hex: area.colorHex) : Color.clear,
                                    lineWidth: 2
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 32)

            Spacer()

            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                onContinue()
            } label: {
                Text("Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(viewModel.selectedLifeAreas.count >= 3 ? Color.blue : Color.gray.opacity(0.3))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(viewModel.selectedLifeAreas.count < 3)
            .padding(.horizontal, 32)
        }
    }
}
