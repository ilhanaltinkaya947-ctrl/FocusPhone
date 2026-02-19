import SwiftUI

struct WeekDaySelectorView: View {
    @Binding var selectedDate: Date

    private let calendar = Calendar.current

    private var weekDates: [Date] {
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: selectedDate)?.start ?? selectedDate
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfWeek) }
    }

    var body: some View {
        HStack(spacing: 4) {
            ForEach(weekDates, id: \.self) { date in
                let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
                let isToday = calendar.isDateInToday(date)

                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        selectedDate = date
                    }
                } label: {
                    VStack(spacing: 6) {
                        Text(dayAbbreviation(date))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(isSelected ? FPTheme.textPrimary : FPTheme.textSecondary)

                        Text("\(calendar.component(.day, from: date))")
                            .font(isSelected
                                ? .system(size: 20, weight: .bold)
                                : .system(size: 17, weight: .medium))
                            .foregroundStyle(
                                isSelected ? FPTheme.textPrimary
                                    : (isToday ? FPTheme.textPrimary : FPTheme.textSecondary)
                            )
                            .frame(width: 36, height: 36)
                            .background(
                                Circle()
                                    .fill(isSelected ? FPTheme.textPrimary.opacity(0.1) : Color.clear)
                            )
                            .overlay(
                                Circle()
                                    .strokeBorder(
                                        isSelected ? FPTheme.textPrimary.opacity(0.3) : Color.clear,
                                        lineWidth: 1.5
                                    )
                            )

                        // Today dot
                        Circle()
                            .fill(isToday ? FPTheme.currentTimeIndicator : Color.clear)
                            .frame(width: 5, height: 5)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, FPTheme.spacing8)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(accessibilityLabel(for: date, isSelected: isSelected, isToday: isToday))
            }
        }
        .padding(.horizontal, FPTheme.spacing16)
    }

    private func dayAbbreviation(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).uppercased()
    }

    private func accessibilityLabel(for date: Date, isSelected: Bool, isToday: Bool) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        var label = formatter.string(from: date)
        if isToday { label += ", today" }
        if isSelected { label += ", selected" }
        return label
    }
}
