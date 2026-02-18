import SwiftUI

struct ModeListTab: View {
    @StateObject private var viewModel = ModeListViewModel()
    @State private var editingMode: Mode?

    var body: some View {
        NavigationStack {
            List {
                Section("System Modes") {
                    ForEach(viewModel.modes.filter(\.isSystem)) { mode in
                        ModeRowView(mode: mode)
                            .onTapGesture { editingMode = mode }
                    }
                }

                Section("Custom Modes") {
                    ForEach(viewModel.modes.filter { !$0.isSystem }) { mode in
                        ModeRowView(mode: mode)
                            .onTapGesture { editingMode = mode }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    viewModel.deleteMode(mode)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }

                    if viewModel.modes.filter({ !$0.isSystem }).isEmpty {
                        Text("No custom modes yet.")
                            .foregroundStyle(.secondary)
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

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: mode.icon)
                .font(.title3)
                .foregroundStyle(Color(hex: mode.colorHex))
                .frame(width: 36, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: mode.colorHex).opacity(0.15))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(mode.name)
                    .fontWeight(.medium)
                if mode.isSystem {
                    Text("System")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .contentShape(Rectangle())
    }
}
