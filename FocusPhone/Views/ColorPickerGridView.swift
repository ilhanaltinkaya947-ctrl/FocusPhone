import SwiftUI

struct ColorPickerGridView: View {
    @Binding var selectedColorHex: String
    @Environment(\.dismiss) private var dismiss

    private static let colors: [String] = [
        "#A8C5A0", "#F0C9A6", "#A0B8D0", "#E8DCC8",
        "#C4B5D4", "#E8B8B8", "#3A3A4A", "#8EBAB8",
        "#B8C9B5", "#D4C4A0", "#C8D8E8", "#E0D0C0",
        "#D8C8E0", "#D0B0B0", "#505060", "#A0C8C8",
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 56))], spacing: 16) {
                    ForEach(Self.colors, id: \.self) { hex in
                        Button {
                            selectedColorHex = hex
                            dismiss()
                        } label: {
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 48, height: 48)
                                .overlay {
                                    if selectedColorHex == hex {
                                        Image(systemName: "checkmark")
                                            .font(.headline)
                                            .fontWeight(.bold)
                                            .foregroundStyle(hex == "#3A3A4A" || hex == "#505060" ? .white : FPTheme.textPrimary)
                                    }
                                }
                                .overlay(
                                    Circle()
                                        .strokeBorder(selectedColorHex == hex ? FPTheme.textPrimary : Color.clear, lineWidth: 2.5)
                                )
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Choose Color")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
