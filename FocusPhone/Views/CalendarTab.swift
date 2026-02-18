import SwiftUI

struct CalendarTab: View {
    @StateObject private var viewModel = CalendarViewModel()
    @State private var showingAddBlock = false
    @State private var editingBlock: TimeBlock?

    private var isToday: Bool {
        Calendar.current.isDateInToday(viewModel.selectedDate)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                WeekDaySelectorView(selectedDate: $viewModel.selectedDate)
                    .padding(.vertical, 8)

                Divider()

                if viewModel.blocksForSelectedDay.isEmpty {
                    ContentUnavailableView {
                        Label("No Time Blocks", systemImage: "calendar.badge.plus")
                    } description: {
                        Text("Tap + to add your first time block for this day.")
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            DayTimelineView(
                                blocks: viewModel.blocksForSelectedDay,
                                modes: viewModel.modes,
                                isToday: isToday,
                                onEdit: { block in editingBlock = block },
                                onDelete: { block in viewModel.removeTimeBlock(block) }
                            )
                            .padding()

                            // Anchor for scrolling to current time area
                            Color.clear
                                .frame(height: 1)
                                .id("currentTime")
                        }
                        .onAppear {
                            if isToday {
                                // Slight delay to let layout complete
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    withAnimation(.easeOut(duration: 0.4)) {
                                        proxy.scrollTo("currentTime", anchor: .center)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Schedule")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddBlock = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddBlock) {
                AddTimeBlockView(
                    modes: viewModel.modes,
                    selectedDayOfWeek: viewModel.selectedWeekday,
                    onSave: { block in
                        viewModel.addTimeBlock(block)
                    }
                )
            }
            .sheet(item: $editingBlock) { block in
                AddTimeBlockView(
                    modes: viewModel.modes,
                    selectedDayOfWeek: viewModel.selectedWeekday,
                    existingBlock: block,
                    onSave: { updated in
                        viewModel.updateTimeBlock(updated)
                    }
                )
            }
            .onAppear {
                viewModel.loadData()
            }
        }
    }
}
