import SwiftUI

struct AISchedulePreviewView: View {
    @ObservedObject var viewModel: AIOnboardingViewModel
    var onAccept: () -> Void
    var onAdjust: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Your Schedule")
                    .font(.system(size: 22, weight: .bold, design: .rounded))

                Spacer()

                Button {
                    viewModel.generateSchedule()
                } label: {
                    Label("Regenerate", systemImage: "arrow.clockwise")
                        .font(.caption.weight(.medium))
                }
                .disabled(viewModel.isGenerating)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)

            // Calendar preview
            WeeklyCalendarView(
                blocks: viewModel.generatedBlocks,
                modes: AppState.shared.modes,
                weekDates: currentWeekDates(),
                selectedDate: Date(),
                onSelectDay: { _ in }
            )

            // Buttons
            VStack(spacing: 12) {
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    viewModel.applySchedule()
                    onAccept()
                } label: {
                    Text("Looks Good!")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.green)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    viewModel.applySchedule()
                    onAdjust()
                } label: {
                    Text("Let me adjust")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .foregroundStyle(.blue)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.blue, lineWidth: 2)
                        )
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 20)
        }
    }

    private func currentWeekDates() -> [Date] {
        let cal = Calendar.current
        let startOfWeek = cal.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: startOfWeek) }
    }
}
