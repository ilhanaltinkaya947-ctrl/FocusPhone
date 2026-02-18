import SwiftUI

struct AddTimeBlockView: View {
    let modes: [Mode]
    let selectedDayOfWeek: Int
    let existingBlock: TimeBlock?
    let onSave: (TimeBlock) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var selectedModeID: UUID?
    @State private var startTime: Date
    @State private var endTime: Date

    private var isEditing: Bool { existingBlock != nil }

    init(modes: [Mode], selectedDayOfWeek: Int, existingBlock: TimeBlock? = nil, onSave: @escaping (TimeBlock) -> Void) {
        self.modes = modes
        self.selectedDayOfWeek = selectedDayOfWeek
        self.existingBlock = existingBlock
        self.onSave = onSave

        if let block = existingBlock {
            _selectedModeID = State(initialValue: block.modeID)
            _startTime = State(initialValue: Calendar.current.date(from: DateComponents(hour: block.startHour, minute: block.startMinute)) ?? Date())
            _endTime = State(initialValue: Calendar.current.date(from: DateComponents(hour: block.endHour, minute: block.endMinute)) ?? Date())
        } else {
            _selectedModeID = State(initialValue: nil)
            _startTime = State(initialValue: Calendar.current.date(from: DateComponents(hour: 9)) ?? Date())
            _endTime = State(initialValue: Calendar.current.date(from: DateComponents(hour: 10)) ?? Date())
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Mode") {
                    ForEach(modes) { mode in
                        HStack {
                            Image(systemName: mode.icon)
                                .foregroundStyle(Color(hex: mode.colorHex))
                                .frame(width: 30)
                            Text(mode.name)
                            Spacer()
                            if selectedModeID == mode.id {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedModeID = mode.id
                        }
                    }
                }

                Section("Time") {
                    DatePicker("Start", selection: $startTime, displayedComponents: .hourAndMinute)
                    DatePicker("End", selection: $endTime, displayedComponents: .hourAndMinute)
                }
            }
            .navigationTitle(isEditing ? "Edit Time Block" : "Add Time Block")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                        dismiss()
                    }
                    .disabled(selectedModeID == nil)
                }
            }
        }
    }

    private func save() {
        guard let modeID = selectedModeID else { return }
        let cal = Calendar.current
        let startComps = cal.dateComponents([.hour, .minute], from: startTime)
        let endComps = cal.dateComponents([.hour, .minute], from: endTime)

        let block = TimeBlock(
            id: existingBlock?.id ?? UUID(),
            modeID: modeID,
            dayOfWeek: selectedDayOfWeek,
            startHour: startComps.hour ?? 9,
            startMinute: startComps.minute ?? 0,
            endHour: endComps.hour ?? 10,
            endMinute: endComps.minute ?? 0
        )
        onSave(block)
    }
}
