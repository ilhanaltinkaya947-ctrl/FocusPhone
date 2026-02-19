import SwiftUI

struct DayTimelineView: View {
    let blocks: [TimeBlock]
    let modes: [Mode]
    let isToday: Bool
    var onEdit: ((TimeBlock) -> Void)?
    var onDelete: ((TimeBlock) -> Void)?

    private let hourHeight: CGFloat = 60
    private let startHourDisplay = 5
    private let endHourDisplay = 24
    private let leftMargin: CGFloat = 52

    init(blocks: [TimeBlock], modes: [Mode], isToday: Bool = false,
         onEdit: ((TimeBlock) -> Void)? = nil, onDelete: ((TimeBlock) -> Void)? = nil) {
        self.blocks = blocks
        self.modes = modes
        self.isToday = isToday
        self.onEdit = onEdit
        self.onDelete = onDelete
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Hour grid
            VStack(spacing: 0) {
                ForEach(startHourDisplay..<endHourDisplay, id: \.self) { hour in
                    HStack(alignment: .top) {
                        Text(hourLabel(hour))
                            .font(FPTheme.timelineHourFont)
                            .foregroundStyle(FPTheme.textSecondary)
                            .frame(width: 44, alignment: .trailing)

                        VStack {
                            FPTheme.divider
                                .frame(height: 0.5)
                            Spacer()
                        }
                        .frame(height: hourHeight)
                    }
                }
            }

            // Time blocks
            ForEach(blocks) { block in
                if let mode = modes.first(where: { $0.id == block.modeID }) {
                    timeBlockView(block: block, mode: mode)
                }
            }

            // Current time indicator
            if isToday {
                currentTimeIndicator
            }
        }
    }

    // MARK: - Current Time Indicator

    private var currentTimeIndicator: some View {
        let now = Date()
        let calendar = Calendar.current
        let currentMinutes = calendar.component(.hour, from: now) * 60 + calendar.component(.minute, from: now)
        let offset = CGFloat(currentMinutes - startHourDisplay * 60) / 60.0 * hourHeight

        return HStack(spacing: 0) {
            Circle()
                .fill(FPTheme.currentTimeIndicator)
                .frame(width: 10, height: 10)
            Rectangle()
                .fill(FPTheme.currentTimeIndicator)
                .frame(height: 1.5)
        }
        .padding(.leading, leftMargin - 6)
        .offset(y: offset - 5)
    }

    // MARK: - Time Block View

    private func timeBlockView(block: TimeBlock, mode: Mode) -> some View {
        let topOffset = CGFloat(block.startHour * 60 + block.startMinute - startHourDisplay * 60)
            / 60.0 * hourHeight
        let height = CGFloat(block.durationMinutes) / 60.0 * hourHeight

        return HStack(spacing: FPTheme.spacing8) {
            Image(systemName: mode.icon)
                .font(.caption)
                .foregroundStyle(ModeColor.blockForeground(lightHex: mode.colorHex))

            Text(mode.name)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(ModeColor.blockForeground(lightHex: mode.colorHex))

            Spacer()

            Text("\(block.startTimeString) – \(block.endTimeString)")
                .font(.system(size: 11, weight: .regular, design: .monospaced))
                .foregroundStyle(ModeColor.blockForeground(lightHex: mode.colorHex).opacity(0.7))
        }
        .padding(.horizontal, FPTheme.spacing16)
        .padding(.vertical, FPTheme.spacing8)
        .frame(height: max(height, 36))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: FPTheme.cardRadius)
                .fill(ModeColor.blockBackground(lightHex: mode.colorHex))
        )
        .padding(.leading, leftMargin)
        .offset(y: topOffset)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(mode.name), \(block.startTimeString) to \(block.endTimeString)")
        .accessibilityHint("Tap to edit, long press for options")
        .onTapGesture { onEdit?(block) }
        .contextMenu {
            Button { onEdit?(block) } label: {
                Label("Edit", systemImage: "pencil")
            }
            Button(role: .destructive) { onDelete?(block) } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func hourLabel(_ hour: Int) -> String {
        let h = hour % 24
        if h == 0 { return "12 AM" }
        if h < 12 { return "\(h) AM" }
        if h == 12 { return "12 PM" }
        return "\(h - 12) PM"
    }
}
