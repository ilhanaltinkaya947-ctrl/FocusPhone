import SwiftUI

struct WhatRawDogDoesView: View {
    let onContinue: () -> Void

    @State private var revealedItems = 0

    private let items = [
        (number: "1", text: "Blocks your worst apps"),
        (number: "2", text: "Builds real habits"),
        (number: "3", text: "Holds you accountable"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Text("What RawDog Does")
                .font(RawDog.Typography.title)
                .foregroundStyle(RawDog.Colors.textPrimary)
                .padding(.bottom, RawDog.Spacing.xl)

            // 3 items with vertical connecting line
            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    HStack(spacing: 16) {
                        // Number circle + line
                        VStack(spacing: 0) {
                            ZStack {
                                Circle()
                                    .fill(RawDog.Colors.accentIce)
                                    .frame(width: 36, height: 36)

                                Text(item.number)
                                    .font(RawDog.Typography.headline)
                                    .foregroundStyle(.black)
                            }

                            if index < items.count - 1 {
                                Rectangle()
                                    .fill(RawDog.Colors.trackBackground)
                                    .frame(width: 2, height: 32)
                            }
                        }

                        Text(item.text)
                            .font(RawDog.Typography.title2)
                            .foregroundStyle(RawDog.Colors.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .opacity(revealedItems > index ? 1 : 0)
                    .offset(y: revealedItems > index ? 0 : 20)
                    .animation(
                        .spring(response: 0.5, dampingFraction: 0.7).delay(Double(index) * 0.4),
                        value: revealedItems
                    )
                }
            }
            .padding(.horizontal, 40)

            Spacer()

            RawDog.OnboardingButton(title: "Continue", isEnabled: revealedItems >= items.count) {
                onContinue()
            }
            .padding(.bottom, 40)
        }
        .onAppear {
            revealedItems = items.count
        }
    }
}
