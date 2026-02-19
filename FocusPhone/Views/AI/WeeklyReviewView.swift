import SwiftUI

struct WeeklyReviewView: View {
    @ObservedObject var viewModel: WeeklyReviewViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                switch viewModel.currentStep {
                case 0: introStep
                case 1: summaryStep
                case 2: suggestionsStep
                case 3: commitmentStep
                case 4: sealedStep
                default: EmptyView()
                }
            }
            .navigationTitle("Weekly Check-in")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    // MARK: - Step 0: Intro

    private var introStep: some View {
        VStack(spacing: 0) {
            Spacer()

            Image(systemName: "calendar.badge.checkmark")
                .font(.system(size: 60, weight: .light))
                .foregroundStyle(.blue)

            Text("Weekly Check-in")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .padding(.top, 20)

            Text("Let's review your week and\nplan for the next one.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 8)

            Spacer()

            Button {
                withAnimation {
                    viewModel.currentStep = 1
                    viewModel.generateReview()
                }
            } label: {
                Text("Let's Go")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Step 1: Summary

    private var summaryStep: some View {
        VStack(spacing: 0) {
            Spacer()

            if viewModel.isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                    Text("Analyzing your week...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else if let summary = viewModel.summary {
                VStack(spacing: 16) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.blue)

                    Text("Your Week in Review")
                        .font(.headline)

                    Text(summary)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(20)
                        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal, 16)
                }
            }

            Spacer()

            Button {
                withAnimation {
                    viewModel.currentStep = viewModel.suggestions.isEmpty ? 3 : 2
                }
            } label: {
                Text("Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(viewModel.isLoading)
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Step 2: Suggestions

    private var suggestionsStep: some View {
        VStack(spacing: 0) {
            Text("Suggestions for Next Week")
                .font(.headline)
                .padding(.top, 20)

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(Array(viewModel.suggestions.enumerated()), id: \.offset) { index, suggestion in
                        suggestionCard(index: index, suggestion: suggestion)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }

            Button {
                withAnimation { viewModel.currentStep = 3 }
            } label: {
                Text("Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
    }

    private func suggestionCard(index: Int, suggestion: WeeklyReviewSuggestion) -> some View {
        let applied = viewModel.appliedSuggestions.contains(index)
        let dayName = dayNameForWeekday(suggestion.dayOfWeek)
        let time = String(format: "%02d:%02d-%02d:%02d",
                          suggestion.startHour, suggestion.startMinute,
                          suggestion.endHour, suggestion.endMinute)

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: suggestion.type == "add" ? "plus.circle.fill" : suggestion.type == "remove" ? "minus.circle.fill" : "arrow.left.and.right.circle.fill")
                    .foregroundStyle(suggestion.type == "add" ? .green : suggestion.type == "remove" ? .red : .orange)

                Text("\(suggestion.type.capitalized) \(suggestion.modeName)")
                    .font(.subheadline.weight(.semibold))

                Spacer()

                if applied {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    Button("Accept") {
                        withAnimation { viewModel.applySuggestion(at: index) }
                    }
                    .font(.caption.weight(.medium))
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }

            Text("\(dayName) \(time)")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(suggestion.reason)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Step 3: Commitment

    private var commitmentStep: some View {
        VStack(spacing: 0) {
            Spacer()

            Text("Set Your Commitment")
                .font(.system(size: 22, weight: .bold, design: .rounded))

            Text("How strict should next week be?")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top, 4)

            VStack(spacing: 12) {
                commitmentOption(
                    level: "flexible",
                    title: "Flexible",
                    description: "Gentle reminders, easy to dismiss",
                    icon: "leaf.fill",
                    color: .green
                )
                commitmentOption(
                    level: "committed",
                    title: "Committed",
                    description: "Follow the schedule with minor flexibility",
                    icon: "flame.fill",
                    color: .orange
                )
                commitmentOption(
                    level: "hardcore",
                    title: "Hardcore",
                    description: "Strict adherence, no exceptions",
                    icon: "bolt.fill",
                    color: .red
                )
            }
            .padding(.horizontal, 32)
            .padding(.top, 24)

            Spacer()

            Button {
                viewModel.sealWeek()
                withAnimation { viewModel.currentStep = 4 }
            } label: {
                Text("Seal the Week")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
    }

    private func commitmentOption(level: String, title: String, description: String, icon: String, color: Color) -> some View {
        let isSelected = viewModel.commitmentLevel == level
        return Button {
            viewModel.commitmentLevel = level
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.blue)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? color.opacity(0.1) : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isSelected ? color : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Step 4: Sealed

    private var sealedStep: some View {
        VStack(spacing: 0) {
            Spacer()

            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 72, weight: .light))
                .foregroundStyle(.green)
                .scaleEffect(viewModel.sealed ? 1.0 : 0.5)
                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: viewModel.sealed)

            Text("Week Sealed!")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .padding(.top, 20)

            Text("Your \(viewModel.commitmentLevel) schedule\nis locked in. Have a great week!")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 4)

            Spacer()

            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.green)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Helpers

    private func dayNameForWeekday(_ day: Int) -> String {
        switch day {
        case 1: return "Sunday"
        case 2: return "Monday"
        case 3: return "Tuesday"
        case 4: return "Wednesday"
        case 5: return "Thursday"
        case 6: return "Friday"
        case 7: return "Saturday"
        default: return ""
        }
    }
}
