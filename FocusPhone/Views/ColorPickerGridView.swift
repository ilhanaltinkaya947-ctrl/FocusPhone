import SwiftUI

struct ColorPickerGridView: View {
    @Binding var selectedColorHex: String
    @Environment(\.dismiss) private var dismiss

    private static let colors: [String] = [
        "#F5A623", "#E74C3C", "#FF6B6B", "#FF9500",
        "#FF2D55", "#AF52DE", "#9B59B6", "#5856D6",
        "#4A90D9", "#007AFF", "#30B0C7", "#00C7BE",
        "#34C759", "#7ED321", "#8E8E93", "#1C1C1E",
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
                                            .foregroundStyle(.white)
                                    }
                                }
                                .overlay(
                                    Circle()
                                        .strokeBorder(selectedColorHex == hex ? Color.primary : Color.clear, lineWidth: 3)
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
