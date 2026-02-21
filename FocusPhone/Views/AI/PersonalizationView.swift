import SwiftUI

struct PersonalizationView: View {
    @ObservedObject var viewModel: AIOnboardingViewModel
    var onContinue: () -> Void

    @State private var showAddCommitment = false
    @State private var newCommitmentName = ""
    @State private var newCommitmentDay = 2
    @State private var newCommitmentStart = 9
    @State private var newCommitmentEnd = 10

    private let dayNames = [
        (1, "Sun"), (2, "Mon"), (3, "Tue"),
        (4, "Wed"), (5, "Thu"), (6, "Fri"), (7, "Sat"),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                // Header
                VStack(spacing: 6) {
                    Text("Personalize Your Schedule")
                        .font(.title2.bold())
                    Text("Help us build a schedule that fits your life")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 20)

                // 1. Energy Pattern
                energyPatternSection

                // 2. Daily Phone Goal
                phoneGoalSection

                // 3. Distraction Trigger
                distractionTriggerSection

                // 4. Fixed Commitments
                fixedCommitmentsSection

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
                .padding(.horizontal, 32)
                .padding(.bottom, 20)
            }
        }
    }

    // MARK: - Energy Pattern

    private var energyPatternSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("When do you have the most energy?")
                .font(.subheadline.weight(.medium))

            HStack(spacing: 12) {
                energyButton(
                    icon: "sunrise.fill",
                    label: "Morning",
                    value: "morning_person",
                    color: .orange
                )
                energyButton(
                    icon: "moon.fill",
                    label: "Night",
                    value: "night_owl",
                    color: .indigo
                )
                energyButton(
                    icon: "clock.fill",
                    label: "Steady",
                    value: "steady",
                    color: .teal
                )
            }
        }
        .padding(.horizontal, 24)
    }

    private func energyButton(icon: String, label: String, value: String, color: Color) -> some View {
        let selected = viewModel.energyPattern == value
        return Button {
            viewModel.energyPattern = value
        } label: {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                Text(label)
                    .font(.caption.weight(.medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(selected ? color.opacity(0.15) : Color(.systemGray6))
            .foregroundStyle(selected ? color : .secondary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(selected ? color : .clear, lineWidth: 2)
            )
        }
    }

    // MARK: - Phone Goal

    private var phoneGoalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Daily phone time target?")
                .font(.subheadline.weight(.medium))

            HStack {
                Button {
                    if viewModel.dailyPhoneGoal > 1 {
                        viewModel.dailyPhoneGoal -= 1
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.blue)
                }

                Spacer()

                Text("\(viewModel.dailyPhoneGoal) hour\(viewModel.dailyPhoneGoal == 1 ? "" : "s")")
                    .font(.title3.weight(.semibold))
                    .monospacedDigit()

                Spacer()

                Button {
                    if viewModel.dailyPhoneGoal < 6 {
                        viewModel.dailyPhoneGoal += 1
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.blue)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Distraction Trigger

    private var distractionTriggerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What makes you reach for your phone?")
                .font(.subheadline.weight(.medium))

            let triggers: [(String, String, String)] = [
                ("boredom", "Boredom", "sparkles"),
                ("stress", "Stress", "flame.fill"),
                ("habit", "Habit", "arrow.triangle.2.circlepath"),
                ("social_pressure", "FOMO", "person.3.fill"),
            ]

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(triggers, id: \.0) { value, label, icon in
                    let selected = viewModel.distractionTrigger == value
                    Button {
                        viewModel.distractionTrigger = value
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: icon)
                                .font(.subheadline)
                            Text(label)
                                .font(.subheadline.weight(.medium))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(selected ? Color.blue.opacity(0.12) : Color(.systemGray6))
                        .foregroundStyle(selected ? .blue : .secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(selected ? Color.blue : .clear, lineWidth: 2)
                        )
                    }
                }
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Fixed Commitments

    private var fixedCommitmentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recurring events to schedule around?")
                .font(.subheadline.weight(.medium))

            if !viewModel.fixedCommitments.isEmpty {
                ForEach(viewModel.fixedCommitments) { commitment in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(commitment.name)
                                .font(.subheadline.weight(.medium))
                            Text("\(dayNames.first { $0.0 == commitment.dayOfWeek }?.1 ?? "") \(commitment.startHour):00-\(commitment.endHour):00")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button {
                            viewModel.fixedCommitments.removeAll { $0.id == commitment.id }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(12)
                    .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 10))
                }
            }

            if showAddCommitment {
                VStack(spacing: 10) {
                    TextField("Event name", text: $newCommitmentName)
                        .textFieldStyle(.roundedBorder)

                    HStack {
                        Picker("Day", selection: $newCommitmentDay) {
                            ForEach(dayNames, id: \.0) { day in
                                Text(day.1).tag(day.0)
                            }
                        }
                        .labelsHidden()

                        Picker("Start", selection: $newCommitmentStart) {
                            ForEach(0..<24, id: \.self) { h in
                                Text("\(h):00").tag(h)
                            }
                        }
                        .labelsHidden()

                        Text("-")

                        Picker("End", selection: $newCommitmentEnd) {
                            ForEach(1..<25, id: \.self) { h in
                                Text("\(h == 24 ? 0 : h):00").tag(h == 24 ? 0 : h)
                            }
                        }
                        .labelsHidden()
                    }

                    HStack(spacing: 12) {
                        Button("Cancel") {
                            showAddCommitment = false
                            newCommitmentName = ""
                        }
                        .foregroundStyle(.secondary)

                        Spacer()

                        Button("Add") {
                            guard !newCommitmentName.isEmpty else { return }
                            let commitment = FixedCommitment(
                                name: newCommitmentName,
                                dayOfWeek: newCommitmentDay,
                                startHour: newCommitmentStart,
                                endHour: newCommitmentEnd
                            )
                            viewModel.fixedCommitments.append(commitment)
                            showAddCommitment = false
                            newCommitmentName = ""
                        }
                        .fontWeight(.medium)
                    }
                }
                .padding(12)
                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 10))
            } else {
                Button {
                    showAddCommitment = true
                } label: {
                    Label("Add Event", systemImage: "plus.circle")
                        .font(.subheadline)
                }
            }
        }
        .padding(.horizontal, 24)
    }
}
