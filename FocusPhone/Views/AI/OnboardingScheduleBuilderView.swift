import SwiftUI

struct OnboardingScheduleBuilderView: View {
    @ObservedObject var viewModel: AIOnboardingViewModel
    var onAccept: () -> Void

    @State private var selectedDay: Int = 2 // Monday
    @State private var editingBlock: TimeBlock?
    @State private var showingAddSheet = false
    @State private var showingRegenerateAlert = false

    private let dayLabels: [(Int, String)] = [
        (2, "Mon"), (3, "Tue"), (4, "Wed"), (5, "Thu"), (6, "Fri"), (7, "Sat"), (1, "Sun"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Your Week")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                Spacer()
                Button {
                    if viewModel.hasUserEdited {
                        showingRegenerateAlert = true
                    } else {
                        viewModel.generateSchedule()
                    }
                } label: {
                    Label("Regenerate", systemImage: "arrow.clockwise")
                        .font(.caption.weight(.medium))
                }
                .disabled(viewModel.isGenerating)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)

            // Day selector with segment bars
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(dayLabels, id: \.0) { day in
                        dayCard(day: day.0, label: day.1)
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.top, 12)

            // Selected day detail
            ScrollView {
                VStack(spacing: 0) {
                    let dayBlocks = blocksForDay(selectedDay)
                    if dayBlocks.isEmpty {
                        Text("No blocks for this day")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.top, 40)
                    } else {
                        DayTimelineView(
                            blocks: dayBlocks,
                            modes: AppState.shared.modes,
                            onEdit: { block in
                                editingBlock = block
                            },
                            onDelete: { block in
                                viewModel.removeBlock(block)
                            }
                        )
                    }
                }
                .padding(.bottom, 80)
            }
            .padding(.top, 8)

            Spacer(minLength: 0)

            // Bottom bar
            VStack(spacing: 12) {
                // Add button
                Button {
                    showingAddSheet = true
                } label: {
                    Label("Add Block", systemImage: "plus.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.blue)
                }

                // Accept button
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    viewModel.applySchedule()
                    onAccept()
                } label: {
                    Text("Looks great, let's go!")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.green)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 20)
        }
        .sheet(item: $editingBlock) { block in
            AddTimeBlockView(
                modes: AppState.shared.modes,
                selectedDayOfWeek: block.dayOfWeek,
                existingBlock: block
            ) { updated in
                viewModel.updateBlock(updated)
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddTimeBlockView(
                modes: AppState.shared.modes,
                selectedDayOfWeek: selectedDay
            ) { newBlock in
                viewModel.addBlock(newBlock)
            }
        }
        .alert("Regenerate Schedule?", isPresented: $showingRegenerateAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Regenerate", role: .destructive) {
                viewModel.hasUserEdited = false
                viewModel.generateSchedule()
            }
        } message: {
            Text("This will replace your edits with a new AI-generated schedule.")
        }
    }

    // MARK: - Day Card

    private func dayCard(day: Int, label: String) -> some View {
        let isSelected = day == selectedDay
        let dayBlocks = blocksForDay(day)
        let modes = AppState.shared.modes
        let maxVisibleBlocks = 6

        return Button {
            withAnimation(.spring(response: 0.3)) {
                selectedDay = day
            }
        } label: {
            VStack(spacing: 6) {
                Text(label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(isSelected ? .blue : .secondary)

                // Segment bar showing block colors — minimum 4pt height per segment
                VStack(spacing: 1) {
                    ForEach(dayBlocks.prefix(maxVisibleBlocks)) { block in
                        if let mode = modes.first(where: { $0.id == block.modeID }) {
                            RoundedRectangle(cornerRadius: 1.5)
                                .fill(Color(hex: mode.colorHex))
                                .frame(height: max(CGFloat(block.durationMinutes) / 60.0 * 6, 4))
                        }
                    }
                }
                .frame(width: 28, height: 48)
                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 4))

                // Show count with overflow indicator
                if dayBlocks.count > maxVisibleBlocks {
                    Text("+\(dayBlocks.count - maxVisibleBlocks)")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(.orange)
                } else {
                    Text("\(dayBlocks.count)")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 44)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(isSelected ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func blocksForDay(_ day: Int) -> [TimeBlock] {
        viewModel.generatedBlocks
            .filter { $0.dayOfWeek == day }
            .sorted { ($0.startHour * 60 + $0.startMinute) < ($1.startHour * 60 + $1.startMinute) }
    }
}
