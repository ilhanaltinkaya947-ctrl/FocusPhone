import SwiftUI

struct ProfileSelectionView: View {
    let onProfilesSelected: ([String]) -> Void
    let onContinue: () -> Void

    @State private var selectedIDs: Set<String> = []
    @State private var mascotState: MascotState = .listening

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                AnimatedMascot(state: mascotState, size: 80)
                    .padding(.top, 20)
                    .padding(.bottom, 8)

                Text("What's your biggest trap?")
                    .font(RawDog.Typography.title2)
                    .foregroundStyle(RawDog.Colors.textPrimary)

                Text("Pick one or more. We'll set it up automatically.")
                    .font(RawDog.Typography.subheadline)
                    .foregroundStyle(RawDog.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
                    .padding(.horizontal, 40)

                VStack(spacing: 10) {
                    ForEach(PrebuiltProfiles.all) { profile in
                        profileCard(profile)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                if !selectedIDs.isEmpty {
                    RawDog.PillButton(title: "Continue") {
                        onContinue()
                    }
                    .padding(.top, 24)
                    .padding(.bottom, 40)
                }
            }
        }
    }

    private func profileCard(_ profile: EnhancedProfile) -> some View {
        let isSelected = selectedIDs.contains(profile.id)

        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.3)) {
                if isSelected {
                    selectedIDs.remove(profile.id)
                } else {
                    selectedIDs.insert(profile.id)
                }
                mascotState = selectedIDs.isEmpty ? .listening : .proud
                onProfilesSelected(Array(selectedIDs))
            }
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    Image(systemName: profile.icon)
                        .font(.system(size: 22))
                        .foregroundStyle(isSelected ? RawDog.Colors.background : RawDog.Colors.accent)
                        .frame(width: 32)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(profile.name)
                            .font(RawDog.Typography.headline)
                            .foregroundStyle(isSelected ? RawDog.Colors.background : RawDog.Colors.textPrimary)

                        Text(profile.description)
                            .font(RawDog.Typography.caption)
                            .foregroundStyle(isSelected ? RawDog.Colors.background.opacity(0.7) : RawDog.Colors.textSecondary)
                            .lineLimit(2)
                    }

                    Spacer()

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(RawDog.Colors.background)
                    }
                }

                // What stays / what goes
                if isSelected {
                    HStack(alignment: .top, spacing: 16) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("STAYS")
                                .font(.caption2.bold())
                                .foregroundStyle(RawDog.Colors.background.opacity(0.5))
                            ForEach(profile.stays.prefix(3), id: \.self) { item in
                                Text("+ \(item)")
                                    .font(RawDog.Typography.caption)
                                    .foregroundStyle(RawDog.Colors.background.opacity(0.8))
                            }
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("GOES")
                                .font(.caption2.bold())
                                .foregroundStyle(RawDog.Colors.background.opacity(0.5))
                            ForEach(profile.goes.prefix(3), id: \.self) { item in
                                Text("- \(item)")
                                    .font(RawDog.Typography.caption)
                                    .foregroundStyle(RawDog.Colors.background.opacity(0.8))
                            }
                        }
                    }
                    .padding(.top, 4)
                }
            }
            .padding(16)
            .background(
                isSelected ? RawDog.Colors.accent : RawDog.Colors.surface,
                in: RoundedRectangle(cornerRadius: RawDog.Radius.card)
            )
        }
    }
}
