import SwiftUI
import FamilyControls

struct ModeEditorView: View {
    @State private var mode: Mode
    let onSave: (Mode) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showingAppPicker = false
    @State private var showingIconPicker = false
    @State private var showingColorPicker = false
    @State private var activitySelection: FamilyActivitySelection
    @State private var newWebsite = ""

    init(mode: Mode, onSave: @escaping (Mode) -> Void) {
        _mode = State(initialValue: mode)
        _activitySelection = State(initialValue: mode.familyActivitySelection ?? FamilyActivitySelection())
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $mode.name)
                    Button { showingIconPicker = true } label: {
                        HStack {
                            Text("Icon")
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: mode.icon)
                                .foregroundStyle(Color(hex: mode.colorHex))
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    Button { showingColorPicker = true } label: {
                        HStack {
                            Text("Color")
                                .foregroundStyle(.primary)
                            Spacer()
                            Circle()
                                .fill(Color(hex: mode.colorHex))
                                .frame(width: 24, height: 24)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                } header: {
                    Text("Appearance")
                }

                Section {
                    Button {
                        showingAppPicker = true
                    } label: {
                        HStack {
                            Text("Select Apps & Categories")
                                .foregroundStyle(.primary)
                            Spacer()
                            let count = appSelectionCount
                            if count > 0 {
                                Text("\(count) selected")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                } header: {
                    Text("Blocked Apps")
                } footer: {
                    Text("Choose which apps and categories to block when this mode is active.")
                }

                Section {
                    ForEach(mode.blockedWebsites, id: \.self) { website in
                        HStack {
                            Image(systemName: "globe")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(website)
                                .font(.subheadline)
                        }
                    }
                    .onDelete { indexSet in
                        mode.blockedWebsites.remove(atOffsets: indexSet)
                    }

                    HStack {
                        TextField("Add domain (e.g. twitter.com)", text: $newWebsite)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.URL)
                            .font(.subheadline)
                        Button {
                            addWebsite()
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(Color(hex: mode.colorHex))
                        }
                        .disabled(newWebsite.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                } header: {
                    Text("Blocked Websites")
                } footer: {
                    Text("Websites are blocked via Safari Content Blocker when this mode is active.")
                }

                Section {
                    Toggle(isOn: $mode.blockAppStore) {
                        Label {
                            Text("Block App Store")
                        } icon: {
                            Image(systemName: "bag.fill")
                                .foregroundStyle(.blue)
                        }
                    }
                    Toggle(isOn: $mode.blockAppDeletion) {
                        Label {
                            Text("Block App Deletion")
                        } icon: {
                            Image(systemName: "trash.slash.fill")
                                .foregroundStyle(.red)
                        }
                    }
                } header: {
                    Text("Restrictions")
                } footer: {
                    Text("Prevent installing new apps or removing existing ones while this mode is active.")
                }
            }
            .navigationTitle("Edit Mode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        mode.setFamilyActivitySelection(activitySelection)
                        onSave(mode)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .familyActivityPicker(
                isPresented: $showingAppPicker,
                selection: $activitySelection
            )
            .sheet(isPresented: $showingIconPicker) {
                IconPickerView(selectedIcon: $mode.icon)
            }
            .sheet(isPresented: $showingColorPicker) {
                ColorPickerGridView(selectedColorHex: $mode.colorHex)
            }
        }
    }

    private var appSelectionCount: Int {
        activitySelection.applicationTokens.count + activitySelection.categoryTokens.count
    }

    private func addWebsite() {
        var domain = newWebsite
            .trimmingCharacters(in: .whitespaces)
            .lowercased()

        if domain.hasPrefix("https://") {
            domain = String(domain.dropFirst(8))
        } else if domain.hasPrefix("http://") {
            domain = String(domain.dropFirst(7))
        }

        if domain.hasSuffix("/") {
            domain = String(domain.dropLast())
        }

        if domain.hasPrefix("www.") {
            domain = String(domain.dropFirst(4))
        }

        guard !domain.isEmpty, !mode.blockedWebsites.contains(domain) else {
            newWebsite = ""
            return
        }

        mode.blockedWebsites.append(domain)
        newWebsite = ""
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}
