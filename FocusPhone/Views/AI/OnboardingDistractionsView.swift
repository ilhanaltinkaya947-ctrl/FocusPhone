import SwiftUI
import FamilyControls

struct OnboardingDistractionsView: View {
    @ObservedObject var viewModel: AIOnboardingViewModel
    var onContinue: () -> Void

    @State private var showingAppPicker = false
    @State private var websiteText: String = ""

    private let timeWasterOptions = [
        "Social Media", "YouTube", "News", "Gaming", "Shopping", "Streaming",
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(spacing: 4) {
                    Text("What Distracts You?")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                    Text("We'll block these during focus time")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 8)

                // Section A: Time waster chips
                VStack(alignment: .leading, spacing: 10) {
                    Text("Common distractions")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)

                    FlowLayout(spacing: 8) {
                        ForEach(timeWasterOptions, id: \.self) { waster in
                            let isSelected = viewModel.biggestTimeWasters.contains(waster)
                            Button {
                                viewModel.toggleTimeWaster(waster)
                            } label: {
                                Text(waster)
                                    .font(.subheadline)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 9)
                                    .background(
                                        Capsule()
                                            .fill(isSelected ? Color.blue.opacity(0.2) : Color(.systemGray5))
                                    )
                                    .foregroundStyle(isSelected ? .blue : .primary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // Section B: App picker
                VStack(alignment: .leading, spacing: 10) {
                    Text("Apps to block")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)

                    Button {
                        showingAppPicker = true
                    } label: {
                        HStack {
                            Image(systemName: "app.badge")
                                .foregroundStyle(.blue)
                            Text(appSelectionLabel)
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(14)
                        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .familyActivityPicker(
                        isPresented: $showingAppPicker,
                        selection: $viewModel.onboardingAppSelection
                    )
                }

                // Section C: Custom websites
                VStack(alignment: .leading, spacing: 10) {
                    Text("Websites to block")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)

                    TextField("e.g. reddit.com, twitter.com", text: $websiteText)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .onChange(of: websiteText) {
                            viewModel.customBlockedWebsites = websiteText
                                .split(separator: ",")
                                .map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
                                .filter { !$0.isEmpty }
                        }

                    if !viewModel.customBlockedWebsites.isEmpty {
                        FlowLayout(spacing: 6) {
                            ForEach(viewModel.customBlockedWebsites, id: \.self) { site in
                                Text(site)
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.blue.opacity(0.1), in: Capsule())
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }

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
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
    }

    private var appSelectionLabel: String {
        let count = viewModel.onboardingAppSelection.applicationTokens.count
            + viewModel.onboardingAppSelection.categoryTokens.count
        if count == 0 {
            return "Choose apps to block..."
        }
        return "\(count) app\(count == 1 ? "" : "s")/categor\(count == 1 ? "y" : "ies") selected"
    }
}
