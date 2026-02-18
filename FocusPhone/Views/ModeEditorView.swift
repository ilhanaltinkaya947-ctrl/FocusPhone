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
                Section("Appearance") {
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
                                .foregroundStyle(.secondary)
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
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Blocked Apps & Categories") {
                    Button {
                        showingAppPicker = true
                    } label: {
                        HStack {
                            Text("Select Apps & Categories")
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                    }
                }

                Section("Blocked Websites") {
                    ForEach(mode.blockedWebsites, id: \.self) { website in
                        Text(website)
                    }
                    .onDelete { indexSet in
                        mode.blockedWebsites.remove(atOffsets: indexSet)
                    }

                    HStack {
                        TextField("Add domain (e.g. twitter.com)", text: $newWebsite)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.URL)
                        Button {
                            addWebsite()
                        } label: {
                            Image(systemName: "plus.circle.fill")
                        }
                        .disabled(newWebsite.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }

                Section("Restrictions") {
                    Toggle("Block App Store", isOn: $mode.blockAppStore)
                    Toggle("Block App Deletion", isOn: $mode.blockAppDeletion)
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
    }
}
