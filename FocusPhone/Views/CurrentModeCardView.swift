import SwiftUI

struct CurrentModeCardView: View {
    let modeInfo: CalendarViewModel.CurrentModeInfo

    @State private var remainingSeconds: Int

    init(modeInfo: CalendarViewModel.CurrentModeInfo) {
        self.modeInfo = modeInfo
        _remainingSeconds = State(initialValue: modeInfo.remainingSeconds)
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { _ in
            HStack(spacing: FPTheme.spacing12) {
                Image(systemName: modeInfo.mode.icon)
                    .font(.title3)
                    .foregroundStyle(ModeColor.blockForeground(lightHex: modeInfo.mode.colorHex))
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(ModeColor.blockBackground(lightHex: modeInfo.mode.colorHex))
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text("NOW")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(FPTheme.textSecondary)
                        .tracking(1.2)
                    Text(modeInfo.mode.name)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(FPTheme.textPrimary)
                }

                Spacer()

                Text(formatCountdown(currentRemaining()))
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .foregroundStyle(ModeColor.adaptive(lightHex: modeInfo.mode.colorHex))
                    .contentTransition(.numericText())
            }
            .padding(FPTheme.spacing16)
            .background(
                RoundedRectangle(cornerRadius: FPTheme.cardRadius)
                    .fill(FPTheme.backgroundSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: FPTheme.cardRadius)
                            .strokeBorder(
                                ModeColor.adaptive(lightHex: modeInfo.mode.colorHex).opacity(0.25),
                                lineWidth: 1
                            )
                    )
            )
        }
    }

    private func currentRemaining() -> Int {
        let end = modeInfo.block.endHour * 3600 + modeInfo.block.endMinute * 60
        let cal = Calendar.current
        let now = Date()
        let current = cal.component(.hour, from: now) * 3600
            + cal.component(.minute, from: now) * 60
            + cal.component(.second, from: now)
        return max(0, end - current)
    }

    private func formatCountdown(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%02d:%02d", m, s)
    }
}
