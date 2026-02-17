import SwiftUI

struct ScheduleSetupView: View {
    @ObservedObject var viewModel: ScheduleViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var label = "Freedom Window"
    @State private var selectedDays: Set<Weekday> = []
    @State private var startTime = Calendar.current.date(
        from: DateComponents(hour: 12, minute: 0)
    ) ?? Date()
    @State private var endTime = Calendar.current.date(
        from: DateComponents(hour: 13, minute: 0)
    ) ?? Date()

    var body: some View {
        NavigationStack {
            Form {
                Section("Label") {
                    TextField("Window name", text: $label)
                }

                Section("Days") {
                    ForEach(Weekday.allCases) { day in
                        Toggle(day.shortName, isOn: Binding(
                            get: { selectedDays.contains(day) },
                            set: { isOn in
                                if isOn {
                                    selectedDays.insert(day)
                                } else {
                                    selectedDays.remove(day)
                                }
                            }
                        ))
                    }
                }

                Section("Time") {
                    DatePicker("Start", selection: $startTime, displayedComponents: .hourAndMinute)
                    DatePicker("End", selection: $endTime, displayedComponents: .hourAndMinute)
                }
            }
            .navigationTitle("New Freedom Window")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveWindow()
                        dismiss()
                    }
                    .disabled(selectedDays.isEmpty)
                }
            }
        }
    }

    private func saveWindow() {
        let startComponents = Calendar.current.dateComponents([.hour, .minute], from: startTime)
        let endComponents = Calendar.current.dateComponents([.hour, .minute], from: endTime)

        let window = FreedomWindow(
            label: label,
            days: selectedDays,
            startHour: startComponents.hour ?? 12,
            startMinute: startComponents.minute ?? 0,
            endHour: endComponents.hour ?? 13,
            endMinute: endComponents.minute ?? 0
        )

        viewModel.addWindow(window)
    }
}
