import SwiftUI

struct SuggestionChipsView: View {
    let chips: [String]
    let onSelect: (String) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(chips, id: \.self) { chip in
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        onSelect(chip)
                    } label: {
                        Text(chip)
                            .font(RawDog.Typography.caption)
                            .foregroundStyle(RawDog.Colors.accent)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(RawDog.Colors.accent.opacity(0.1))
                            .overlay(
                                Capsule()
                                    .stroke(RawDog.Colors.accent.opacity(0.2), lineWidth: 1)
                            )
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

#Preview("Suggestion Chips") {
    SuggestionChipsView(
        chips: ["That's crazy", "Makes sense", "Tell me more"],
        onSelect: { _ in }
    )
    .padding(.vertical)
    .background(Color.black)
}
