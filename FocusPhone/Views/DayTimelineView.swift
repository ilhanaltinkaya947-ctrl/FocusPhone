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
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .frame(width: 44, alignment: .trailing)

                        VStack {
                            Divider()
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
                .fill(.red)
                .frame(width: 10, height: 10)
            Rectangle()
                .fill(.red)
                .frame(height: 1.5)
        }
        .padding(.leading, 46)
        .offset(y: offset - 5) // center the dot vertically
    }

    // MARK: - Time Block View

    private func timeBlockView(block: TimeBlock, mode: Mode) -> some View {
        let topOffset = CGFloat(block.startHour * 60 + block.startMinute - startHourDisplay * 60)
            / 60.0 * hourHeight
        let height = CGFloat(block.durationMinutes) / 60.0 * hourHeight
        let color = Color(hex: mode.colorHex)

        return HStack(spacing: 0) {
            // Colored accent strip
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 4)
                .padding(.vertical, 2)

            // Content
            HStack(spacing: 6) {
                Image(systemName: mode.icon)
                    .font(.caption)
                    .foregroundStyle(color)
                Text(mode.name)
                    .font(.caption)
                    .fontWeight(.medium)
                Spacer()
                Text("\(block.startTimeString) – \(block.endTimeString)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
        .frame(height: max(height, 30))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(color.opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(color.opacity(0.3), lineWidth: 1)
        )
        .padding(.leading, 52)
        .offset(y: topOffset)
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
