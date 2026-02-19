import SwiftUI

struct NLCommandBar: View {
    var onTap: () -> Void

    var body: some View {
        if AppState.shared.aiEnabled && KeychainService.hasKey {
            Button(action: onTap) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 13))
                        .foregroundStyle(FPTheme.textSecondary)

                    Text("Ask AI to edit your schedule...")
                        .font(.system(size: 14))
                        .foregroundStyle(FPTheme.textSecondary)

                    Spacer()

                    Image(systemName: "sparkles")
                        .font(.system(size: 13))
                        .foregroundStyle(.blue.opacity(0.7))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(FPTheme.backgroundSecondary)
                )
                .overlay(
                    Capsule()
                        .strokeBorder(FPTheme.divider, lineWidth: 0.5)
                )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, FPTheme.spacing20)
        }
    }
}
