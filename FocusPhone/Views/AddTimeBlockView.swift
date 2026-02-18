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
    @State private var showingOverlapAlert = false

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

    private var startMinutes: Int {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: startTime)
        return (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
    }

    private var endMinutes: Int {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: endTime)
        return (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
    }

    private var isValidTimeRange: Bool {
        endMinutes > startMinutes
    }

    private var hasOverlap: Bool {
        let existing = AppState.shared.timeBlocks(forDay: selectedDayOfWeek)
        let newStart = startMinutes
        let newEnd = endMinutes
        return existing.contains { block in
            guard block.id != existingBlock?.id else { return false }
            let bStart = block.startHour * 60 + block.startMinute
            let bEnd = block.endHour * 60 + block.endMinute
            return newStart < bEnd && newEnd > bStart
        }
    }

    private var canSave: Bool {
        selectedModeID != nil && isValidTimeRange
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

                Section {
                    DatePicker("Start", selection: $startTime, displayedComponents: .hourAndMinute)
                    DatePicker("End", selection: $endTime, displayedComponents: .hourAndMinute)
                } header: {
                    Text("Time")
                } footer: {
                    if !isValidTimeRange {
                        Text("End time must be after start time.")
                            .foregroundStyle(.red)
                    } else if hasOverlap {
                        Text("This overlaps with an existing time block.")
                            .foregroundStyle(.orange)
                    }
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
                        if hasOverlap {
                            showingOverlapAlert = true
                        } else {
                            save()
                            dismiss()
                        }
                    }
                    .disabled(!canSave)
                }
            }
            .alert("Overlapping Block", isPresented: $showingOverlapAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Save Anyway") {
                    save()
                    dismiss()
                }
            } message: {
                Text("This time block overlaps with an existing one. Save anyway?")
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
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        onSave(block)
    }
}
