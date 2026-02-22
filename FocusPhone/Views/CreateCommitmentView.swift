import SwiftUI

struct CreateCommitmentView: View {
    @ObservedObject var viewModel: CommitmentViewModel
    @Environment(\.dismiss) private var dismiss

    private let weekdays = [
        (2, "M"), (3, "T"), (4, "W"), (5, "T"), (6, "F"), (7, "S"), (1, "S")
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                RawDog.Colors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: RawDog.Spacing.lg) {
                        titleSection
                        categorySection
                        timeSection
                        daysSection
                        verificationSection
                    }
                    .padding()
                }
            }
            .navigationTitle("New Commitment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(RawDog.Colors.textSecondary)
                }
            }
            .safeAreaInset(edge: .bottom) {
                RawDog.PillButton(title: "Create Commitment") {
                    viewModel.createCommitment()
                    dismiss()
                }
                .disabled(viewModel.newTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .padding(.bottom)
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Sections

    private var titleSection: some View {
        RawDog.Card {
            Text("What's the commitment?")
                .font(RawDog.Typography.headline)
                .foregroundStyle(RawDog.Colors.textPrimary)

            TextField("e.g. Morning gym session", text: $viewModel.newTitle)
                .font(RawDog.Typography.body)
                .padding(12)
                .background(RawDog.Colors.surfaceElevated, in: RoundedRectangle(cornerRadius: RawDog.Radius.small))
                .foregroundStyle(RawDog.Colors.textPrimary)
        }
    }

    private var categorySection: some View {
        RawDog.Card {
            Text("Category")
                .font(RawDog.Typography.headline)
                .foregroundStyle(RawDog.Colors.textPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: RawDog.Spacing.sm) {
                    ForEach(CommitmentCategory.allCases) { category in
                        Button {
                            viewModel.newCategory = category
                        } label: {
                            HStack(spacing: 6) {
                                Text(category.defaultEmoji)
                                Text(category.displayName)
                                    .font(RawDog.Typography.caption)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                viewModel.newCategory == category
                                    ? RawDog.Colors.accent
                                    : RawDog.Colors.surfaceElevated,
                                in: Capsule()
                            )
                            .foregroundStyle(
                                viewModel.newCategory == category
                                    ? RawDog.Colors.background
                                    : RawDog.Colors.textPrimary
                            )
                        }
                    }
                }
            }
        }
    }

    private var timeSection: some View {
        RawDog.Card {
            Text("Scheduled Time")
                .font(RawDog.Typography.headline)
                .foregroundStyle(RawDog.Colors.textPrimary)

            DatePicker("Time", selection: $viewModel.newScheduledTime, displayedComponents: .hourAndMinute)
                .datePickerStyle(.wheel)
                .labelsHidden()
                .frame(maxWidth: .infinity)
                .colorScheme(.dark)
        }
    }

    private var daysSection: some View {
        RawDog.Card {
            Text("Days")
                .font(RawDog.Typography.headline)
                .foregroundStyle(RawDog.Colors.textPrimary)

            HStack(spacing: RawDog.Spacing.sm) {
                ForEach(weekdays, id: \.0) { weekday, label in
                    Button {
                        if viewModel.newSelectedDays.contains(weekday) {
                            viewModel.newSelectedDays.remove(weekday)
                        } else {
                            viewModel.newSelectedDays.insert(weekday)
                        }
                    } label: {
                        Text(label)
                            .font(RawDog.Typography.caption2)
                            .frame(width: 36, height: 36)
                            .background(
                                viewModel.newSelectedDays.contains(weekday)
                                    ? RawDog.Colors.accent
                                    : RawDog.Colors.surfaceElevated,
                                in: Circle()
                            )
                            .foregroundStyle(
                                viewModel.newSelectedDays.contains(weekday)
                                    ? RawDog.Colors.background
                                    : RawDog.Colors.textSecondary
                            )
                    }
                }
            }
        }
    }

    private var verificationSection: some View {
        RawDog.Card {
            Text("Verification")
                .font(RawDog.Typography.headline)
                .foregroundStyle(RawDog.Colors.textPrimary)

            Picker("Type", selection: $viewModel.newVerificationType) {
                Text("Photo (AI)").tag(VerificationType.photo)
                Text("Manual").tag(VerificationType.manual)
            }
            .pickerStyle(.segmented)
        }
    }
}
