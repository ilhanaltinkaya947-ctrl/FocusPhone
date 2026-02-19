import SwiftUI

struct CalendarTab: View {
    @StateObject private var viewModel = CalendarViewModel()
    @State private var viewMode: ViewMode = .daily
    @State private var showingAddBlock = false
    @State private var editingBlock: TimeBlock?
    @State private var showingNLCommand = false

    private let calendar = Calendar.current

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: viewModel.selectedDate).uppercased()
    }

    private var dayNumberString: String {
        "\(calendar.component(.day, from: viewModel.selectedDate))"
    }

    private var dayOfWeekString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: viewModel.selectedDate)
    }

    private var weekRangeString: String {
        let dates = viewModel.weekDates()
        guard let first = dates.first, let last = dates.last else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: first)) – \(formatter.string(from: last))"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header area
            VStack(alignment: .leading, spacing: 0) {
                // Top bar: month/year + toggle + add button
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: FPTheme.spacing4) {
                        Text(monthYearString)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(FPTheme.textSecondary)
                            .tracking(1.5)

                        if viewMode == .daily {
                            HStack(alignment: .firstTextBaseline, spacing: FPTheme.spacing12) {
                                Text(dayNumberString)
                                    .font(FPTheme.heroDateFont)
                                    .foregroundStyle(FPTheme.textPrimary)
                                    .minimumScaleFactor(0.7)

                                Text(dayOfWeekString)
                                    .font(.system(size: 20, weight: .regular))
                                    .foregroundStyle(FPTheme.textSecondary)
                            }
                        } else {
                            Text(weekRangeString)
                                .font(.system(size: 20, weight: .regular))
                                .foregroundStyle(FPTheme.textPrimary)
                        }
                    }

                    Spacer()

                    VStack(spacing: FPTheme.spacing8) {
                        ViewModeToggle(mode: $viewMode)

                        Button {
                            showingAddBlock = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(FPTheme.textPrimary)
                                .frame(width: 36, height: 36)
                                .background(
                                    Circle()
                                        .fill(FPTheme.textPrimary.opacity(0.08))
                                )
                        }
                    }
                }
                .padding(.horizontal, FPTheme.spacing20)
                .padding(.top, FPTheme.spacing16)

                // Week day selector (daily mode only)
                if viewMode == .daily {
                    WeekDaySelectorView(selectedDate: $viewModel.selectedDate)
                        .padding(.top, FPTheme.spacing12)
                }
            }
            .background(FPTheme.backgroundPrimary)

            NLCommandBar { showingNLCommand = true }
                .padding(.vertical, FPTheme.spacing8)

            // Thin separator
            FPTheme.divider
                .frame(height: 0.5)

            // Content
            if viewMode == .weekly {
                weeklyContent
            } else {
                dailyContent
            }
        }
        .background(FPTheme.backgroundPrimary)
        .sheet(isPresented: $showingAddBlock) {
            AddTimeBlockView(
                modes: viewModel.modes,
                selectedDayOfWeek: viewModel.selectedWeekday,
                onSave: { block in viewModel.addTimeBlock(block) }
            )
        }
        .sheet(item: $editingBlock) { block in
            AddTimeBlockView(
                modes: viewModel.modes,
                selectedDayOfWeek: viewModel.selectedWeekday,
                existingBlock: block,
                onSave: { updated in viewModel.updateTimeBlock(updated) }
            )
        }
        .sheet(isPresented: $showingNLCommand, onDismiss: {
            viewModel.loadData()
        }) {
            NLCommandSheet()
        }
        .onAppear { viewModel.loadData() }
        .onChange(of: viewModel.selectedDate) {
            viewModel.loadIntention()
            viewModel.updateCurrentMode()
        }
    }

    // MARK: - Weekly Content

    private var weeklyContent: some View {
        WeeklyCalendarView(
            blocks: viewModel.timeBlocks,
            modes: viewModel.modes,
            weekDates: viewModel.weekDates(),
            selectedDate: viewModel.selectedDate,
            onSelectDay: { date in
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    viewModel.selectedDate = date
                    viewMode = .daily
                }
            }
        )
    }

    // MARK: - Daily Content

    @ViewBuilder
    private var dailyContent: some View {
        if viewModel.blocksForSelectedDay.isEmpty {
            emptyState
        } else {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: FPTheme.spacing12) {
                        // Daily intention (only for today)
                        if viewModel.isSelectedDateToday {
                            DailyIntentionView(
                                intention: viewModel.dailyIntention,
                                onSave: { text in viewModel.saveIntention(text) }
                            )
                            .padding(.horizontal, FPTheme.spacing20)
                        }

                        // Current mode card (only when active now)
                        if let modeInfo = viewModel.currentModeInfo, viewModel.isSelectedDateToday {
                            CurrentModeCardView(modeInfo: modeInfo)
                                .padding(.horizontal, FPTheme.spacing20)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }

                        // Day timeline
                        DayTimelineView(
                            blocks: viewModel.blocksForSelectedDay,
                            modes: viewModel.modes,
                            isToday: viewModel.isSelectedDateToday,
                            onEdit: { block in editingBlock = block },
                            onDelete: { block in viewModel.removeTimeBlock(block) }
                        )
                        .padding(.horizontal, FPTheme.spacing4)

                        // Scroll anchor
                        Color.clear
                            .frame(height: 1)
                            .id("currentTime")
                    }
                    .padding(.top, FPTheme.spacing12)
                    .padding(.bottom, FPTheme.spacing32)
                }
                .onAppear {
                    if viewModel.isSelectedDateToday {
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

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: FPTheme.spacing12) {
            Spacer()
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(FPTheme.textSecondary.opacity(0.5))

            Text("No Time Blocks")
                .font(FPTheme.sectionTitleFont)
                .foregroundStyle(FPTheme.textSecondary)

            Text("Tap + to add your first time block for this day.")
                .font(FPTheme.captionFont)
                .foregroundStyle(FPTheme.textSecondary.opacity(0.7))
                .multilineTextAlignment(.center)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, FPTheme.spacing32)
    }
}
