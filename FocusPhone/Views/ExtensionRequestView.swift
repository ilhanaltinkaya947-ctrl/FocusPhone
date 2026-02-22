import SwiftUI

struct ExtensionRequestView: View {
    @StateObject private var viewModel: ExtensionRequestViewModel
    @Environment(\.dismiss) private var dismiss

    init(appName: String) {
        _viewModel = StateObject(wrappedValue: ExtensionRequestViewModel(appName: appName))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                RawDog.Colors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: RawDog.Spacing.lg) {
                        // Mascot — sideeye when asking, changes on result
                        mascotSection

                        // App name
                        appNameCard

                        // Daily allowance
                        dailyAllowanceCard

                        // Request form or result
                        if viewModel.isCapReached {
                            capReachedCard
                        } else if let result = viewModel.result {
                            resultCard(result)
                        } else {
                            requestFormCard
                        }

                        // Error
                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(RawDog.Typography.caption)
                                .foregroundStyle(RawDog.Colors.destructive)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.vertical, RawDog.Spacing.lg)
                }
            }
            .navigationTitle("Request Extension")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(RawDog.Colors.textSecondary)
                }

                if viewModel.result != nil {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { dismiss() }
                            .foregroundStyle(RawDog.Colors.accent)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Mascot

    private var mascotSection: some View {
        VStack(spacing: RawDog.Spacing.sm) {
            RawDogMascot(
                state: mascotState,
                size: 90
            )

            Text(mascotMessage)
                .font(RawDog.Typography.caption)
                .foregroundStyle(RawDog.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    private var mascotState: MascotState {
        if let result = viewModel.result {
            switch result {
            case .approved: return .proud
            case .denied: return .sideeye
            }
        }
        if viewModel.isCapReached { return .sideeye }
        return .sideeye  // default skeptical when requesting
    }

    private var mascotMessage: String {
        if let result = viewModel.result {
            switch result {
            case .approved: return "Fine. Use it wisely."
            case .denied: return "Not this time. Stay strong."
            }
        }
        if viewModel.isCapReached { return "You've used all your extensions today." }
        return "This better be important..."
    }

    // MARK: - Cards

    private var appNameCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "app.fill")
                .foregroundStyle(RawDog.Colors.accent)
            Text(viewModel.appName)
                .font(RawDog.Typography.headline)
                .foregroundStyle(RawDog.Colors.textPrimary)
            Spacer()
        }
        .padding(RawDog.Spacing.md)
        .background(RawDog.Colors.surface, in: RoundedRectangle(cornerRadius: RawDog.Radius.card))
        .padding(.horizontal)
    }

    private var dailyAllowanceCard: some View {
        VStack(alignment: .leading, spacing: RawDog.Spacing.sm) {
            HStack {
                Text("Daily Extension Time")
                    .font(RawDog.Typography.subheadline)
                    .foregroundStyle(RawDog.Colors.textPrimary)
                Spacer()
                Text("\(viewModel.dailyUsed)/\(viewModel.dailyCap) min")
                    .font(RawDog.Typography.subheadline.weight(.medium))
                    .foregroundStyle(viewModel.isCapReached ? RawDog.Colors.destructive : RawDog.Colors.textSecondary)
            }
            ProgressView(value: viewModel.usageProgress)
                .tint(viewModel.isCapReached ? RawDog.Colors.destructive : RawDog.Colors.accent)
        }
        .padding(RawDog.Spacing.md)
        .background(RawDog.Colors.surface, in: RoundedRectangle(cornerRadius: RawDog.Radius.card))
        .padding(.horizontal)
    }

    private var capReachedCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(RawDog.Colors.windowClosed)
            Text("Daily cap reached. No more extensions today.")
                .font(RawDog.Typography.caption)
                .foregroundStyle(RawDog.Colors.textSecondary)
        }
        .padding(RawDog.Spacing.md)
        .background(RawDog.Colors.surface, in: RoundedRectangle(cornerRadius: RawDog.Radius.card))
        .padding(.horizontal)
    }

    private var requestFormCard: some View {
        VStack(alignment: .leading, spacing: RawDog.Spacing.md) {
            Text("Why do you need this?")
                .font(RawDog.Typography.subheadline.weight(.medium))
                .foregroundStyle(RawDog.Colors.textPrimary)

            TextField("Be specific and honest...", text: $viewModel.reason, axis: .vertical)
                .lineLimit(3...6)
                .padding(12)
                .background(RawDog.Colors.surfaceElevated, in: RoundedRectangle(cornerRadius: RawDog.Radius.small))
                .foregroundStyle(RawDog.Colors.textPrimary)

            HStack {
                Text("Duration")
                    .font(RawDog.Typography.subheadline)
                    .foregroundStyle(RawDog.Colors.textSecondary)
                Spacer()
                Picker("Duration", selection: $viewModel.requestedMinutes) {
                    Text("5 min").tag(5)
                    Text("10 min").tag(10)
                    Text("15 min").tag(15)
                    Text("20 min").tag(20)
                    Text("30 min").tag(30)
                }
                .pickerStyle(.menu)
                .tint(RawDog.Colors.accent)
            }

            if viewModel.isLoading {
                ProgressView()
                    .tint(RawDog.Colors.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, RawDog.Spacing.sm)
            } else {
                RawDog.PillButton(title: "Submit Request") {
                    viewModel.submitRequest()
                }
                .disabled(viewModel.reason.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(RawDog.Spacing.md)
        .background(RawDog.Colors.surface, in: RoundedRectangle(cornerRadius: RawDog.Radius.card))
        .padding(.horizontal)
    }

    private func resultCard(_ result: ExtensionRequestViewModel.RequestResult) -> some View {
        VStack(spacing: RawDog.Spacing.md) {
            switch result {
            case .approved(let minutes):
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(RawDog.Colors.approved)
                Text("Approved")
                    .font(RawDog.Typography.title2)
                    .foregroundStyle(RawDog.Colors.textPrimary)
                Text("\(minutes) minutes granted")
                    .font(RawDog.Typography.subheadline)
                    .foregroundStyle(RawDog.Colors.textSecondary)

            case .denied:
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(RawDog.Colors.denied)
                Text("Denied")
                    .font(RawDog.Typography.title2)
                    .foregroundStyle(RawDog.Colors.textPrimary)
                Text("You chose these restrictions for a reason.")
                    .font(RawDog.Typography.subheadline)
                    .foregroundStyle(RawDog.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, RawDog.Spacing.lg)
        .padding(.horizontal)
        .background(RawDog.Colors.surface, in: RoundedRectangle(cornerRadius: RawDog.Radius.card))
        .padding(.horizontal)
    }
}
