import SwiftUI

struct QuickQuestionsView: View {
    @ObservedObject var viewModel: AIOnboardingViewModel
    var onContinue: () -> Void

    @State private var visibleQuestions = 1
    @State private var isAnimating = false

    private let dayLabels: [(Int, String)] = [
        (2, "Mon"), (3, "Tue"), (4, "Wed"), (5, "Thu"), (6, "Fri"), (7, "Sat"), (1, "Sun"),
    ]

    private let commitmentOptions: [(String, String, String)] = [
        ("gentle", "Gentle", "Suggest, but keep me flexible"),
        ("balanced", "Balanced", "Block distractions during focus"),
        ("strict", "Strict", "Lock me out \u{2014} I mean it"),
    ]

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Q1: Wake time
                    questionBubble(id: 1, question: "What time do you usually wake up?") {
                        Picker("Wake time", selection: $viewModel.wakeTime) {
                            ForEach(5...11, id: \.self) { hour in
                                Text("\(hour):00 AM").tag(hour)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 100)
                        .onChange(of: viewModel.wakeTime) {
                            revealNext(2, proxy: proxy)
                        }
                    }

                    // Q2: Sleep time — restricted to 20-24 to avoid wrap-around bugs
                    if visibleQuestions >= 2 {
                        questionBubble(id: 2, question: "What time do you go to sleep?") {
                            Picker("Sleep time", selection: $viewModel.sleepTime) {
                                Text("8:00 PM").tag(20)
                                Text("9:00 PM").tag(21)
                                Text("10:00 PM").tag(22)
                                Text("11:00 PM").tag(23)
                                Text("Midnight").tag(24)
                            }
                            .pickerStyle(.wheel)
                            .frame(height: 100)
                            .onChange(of: viewModel.sleepTime) {
                                revealNext(3, proxy: proxy)
                            }
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    // Q3: Work schedule
                    if visibleQuestions >= 3 {
                        questionBubble(id: 3, question: "What's your work schedule?") {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Picker("Start", selection: $viewModel.workStartHour) {
                                        ForEach(6...12, id: \.self) { h in
                                            Text("\(h):00").tag(h)
                                        }
                                    }
                                    .pickerStyle(.menu)

                                    Text("to")
                                        .foregroundStyle(.secondary)

                                    Picker("End", selection: $viewModel.workEndHour) {
                                        ForEach(14...22, id: \.self) { h in
                                            Text("\(h):00").tag(h)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                }

                                // Day selector
                                HStack(spacing: 6) {
                                    ForEach(dayLabels, id: \.0) { day in
                                        let isSelected = viewModel.workDays.contains(day.0)
                                        Button {
                                            viewModel.toggleWorkDay(day.0)
                                        } label: {
                                            Text(day.1)
                                                .font(.caption2.weight(.medium))
                                                .frame(width: 36, height: 32)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .fill(isSelected ? Color.blue.opacity(0.2) : Color(.systemGray5))
                                                )
                                                .foregroundStyle(isSelected ? .blue : .secondary)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                            .onChange(of: viewModel.workDays) {
                                revealNext(4, proxy: proxy)
                            }
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    // Q4: Exercise
                    if visibleQuestions >= 4 {
                        questionBubble(id: 4, question: "How often do you exercise?") {
                            VStack(spacing: 8) {
                                Picker("Frequency", selection: $viewModel.exerciseFrequency) {
                                    Text("Never").tag(0)
                                    Text("1-2x").tag(2)
                                    Text("3-4x").tag(3)
                                    Text("5-6x").tag(5)
                                    Text("Daily").tag(7)
                                }
                                .pickerStyle(.segmented)
                            }
                            .onChange(of: viewModel.exerciseFrequency) {
                                revealNext(5, proxy: proxy)
                            }
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    // Q5: Commitment level
                    if visibleQuestions >= 5 {
                        questionBubble(id: 5, question: "How strict should we be?") {
                            VStack(spacing: 8) {
                                ForEach(commitmentOptions, id: \.0) { option in
                                    let isSelected = viewModel.commitmentLevel == option.0
                                    Button {
                                        withAnimation(.spring(response: 0.3)) {
                                            viewModel.commitmentLevel = option.0
                                        }
                                    } label: {
                                        HStack(spacing: 12) {
                                            Image(systemName: commitmentIcon(option.0))
                                                .font(.title3)
                                                .foregroundStyle(isSelected ? .blue : .secondary)
                                                .frame(width: 28)

                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(option.1)
                                                    .font(.subheadline.weight(.semibold))
                                                    .foregroundStyle(.primary)
                                                Text(option.2)
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }

                                            Spacer()

                                            if isSelected {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundStyle(.blue)
                                            }
                                        }
                                        .padding(12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(isSelected ? Color.blue.opacity(0.08) : Color(.systemGray6))
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .strokeBorder(isSelected ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 1.5)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))

                        // Continue button
                        Button {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            onContinue()
                        } label: {
                            Text("Continue")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.blue)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .padding(.top, 8)
                        .transition(.opacity)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.top, 24)
                .padding(.bottom, 40)
            }
        }
    }

    // MARK: - Components

    private func commitmentIcon(_ level: String) -> String {
        switch level {
        case "gentle": return "hand.raised"
        case "balanced": return "scale.3d"
        case "strict": return "lock.shield"
        default: return "scale.3d"
        }
    }

    private func questionBubble<Content: View>(
        id: Int,
        question: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Question bubble
            Text(question)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color(.systemGray5), in: RoundedRectangle(cornerRadius: 16))
                .id(id)

            // Answer area
            content()
                .padding(.leading, 8)
        }
    }

    private func revealNext(_ nextIndex: Int, proxy: ScrollViewProxy) {
        guard visibleQuestions < nextIndex else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                visibleQuestions = nextIndex
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation {
                    proxy.scrollTo(nextIndex, anchor: .top)
                }
            }
        }
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            totalHeight = y + rowHeight
        }

        return (CGSize(width: maxWidth, height: totalHeight), positions)
    }
}
