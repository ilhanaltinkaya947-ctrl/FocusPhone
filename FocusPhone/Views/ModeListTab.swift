import SwiftUI

struct ModeListTab: View {
    @StateObject private var viewModel = ModeListViewModel()
    @State private var editingMode: Mode?

    private var systemModes: [Mode] { viewModel.modes.filter(\.isSystem) }
    private var customModes: [Mode] { viewModel.modes.filter { !$0.isSystem } }

    var body: some View {
        NavigationStack {
            List {
                Section("System Modes") {
                    ForEach(systemModes) { mode in
                        ModeRowView(mode: mode, isActive: viewModel.activeModeID == mode.id)
                            .onTapGesture { editingMode = mode }
                    }
                }

                Section("Custom Modes") {
                    ForEach(customModes) { mode in
                        ModeRowView(mode: mode, isActive: viewModel.activeModeID == mode.id)
                            .onTapGesture { editingMode = mode }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    UINotificationFeedbackGenerator().notificationOccurred(.warning)
                                    viewModel.deleteMode(mode)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }

                    if customModes.isEmpty {
                        HStack {
                            Spacer()
                            VStack(spacing: 4) {
                                Text("No custom modes yet")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Text("Tap + to create one")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("Modes")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        let newMode = Mode(name: "New Mode", icon: "circle.fill", colorHex: "#007AFF")
                        viewModel.addMode(newMode)
                        editingMode = newMode
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(item: $editingMode) { mode in
                ModeEditorView(mode: mode) { updated in
                    viewModel.updateMode(updated)
                }
            }
            .onAppear {
                viewModel.loadModes()
            }
        }
    }
}

struct ModeRowView: View {
    let mode: Mode
    var isActive: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: mode.icon)
                .font(.title3)
                .foregroundStyle(ModeColor.adaptive(lightHex: mode.colorHex))
                .frame(width: 36, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(ModeColor.adaptive(lightHex: mode.colorHex).opacity(0.15))
                )

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(mode.name)
                        .fontWeight(.medium)
                    if isActive {
                        Text("ACTIVE")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(ModeColor.adaptive(lightHex: mode.colorHex), in: Capsule())
                    }
                }
                modeSubtitle
            }

            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.quaternary)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(mode.name)\(isActive ? ", active" : "")")
        .accessibilityHint("Tap to edit")
    }

    private var modeSubtitle: some View {
        let parts: [String] = {
            var p: [String] = []
            if !mode.blockedWebsites.isEmpty {
                p.append("\(mode.blockedWebsites.count) site\(mode.blockedWebsites.count == 1 ? "" : "s")")
            }
            if mode.blockAppStore { p.append("No installs") }
            if mode.blockAppDeletion { p.append("No deletion") }
            return p
        }()

        return Group {
            if parts.isEmpty {
                Text("No restrictions")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            } else {
                Text(parts.joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
