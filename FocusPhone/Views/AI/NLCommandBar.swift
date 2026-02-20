import SwiftUI

struct NLCommandBar: View {
    var onTap: () -> Void

    var body: some View {
        if AppState.shared.aiEnabled {
            if KeychainService.hasKey {
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
            } else {
                // AI enabled but no API key — show setup prompt
                Button(action: onTap) {
                    HStack(spacing: 8) {
                        Image(systemName: "key")
                            .font(.system(size: 13))
                            .foregroundStyle(.orange)

                        Text("Set up AI to edit your schedule")
                            .font(.system(size: 14))
                            .foregroundStyle(FPTheme.textSecondary)

                        Spacer()

                        Image(systemName: "arrow.right")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(Color.orange.opacity(0.08))
                    )
                    .overlay(
                        Capsule()
                            .strokeBorder(Color.orange.opacity(0.3), lineWidth: 0.5)
                    )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, FPTheme.spacing20)
            }
        }
    }
}
