import SwiftUI

struct IconPickerView: View {
    @Binding var selectedIcon: String
    @Environment(\.dismiss) private var dismiss

    private static let icons: [String] = [
        "sunrise.fill", "sun.max.fill", "moon.fill", "clock.fill",
        "hourglass", "timer", "alarm.fill", "calendar",
        "brain.head.profile", "book.fill", "pencil", "doc.text.fill",
        "laptopcomputer", "desktopcomputer", "keyboard",
        "figure.run", "figure.walk", "heart.fill", "bed.double.fill",
        "cup.and.saucer.fill", "fork.knife", "drop.fill",
        "car.fill", "bus.fill", "bicycle", "airplane",
        "person.2.fill", "phone.fill", "message.fill", "envelope.fill",
        "gamecontroller.fill", "music.note", "tv.fill", "headphones",
        "leaf.fill", "flame.fill", "bolt.fill", "wind",
        "star.fill", "circle.fill", "shield.fill", "lock.fill",
        "eye.slash.fill", "bell.slash.fill", "nosign", "hand.raised.fill",
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 56))], spacing: 16) {
                    ForEach(Self.icons, id: \.self) { icon in
                        Button {
                            selectedIcon = icon
                            dismiss()
                        } label: {
                            Image(systemName: icon)
                                .font(.title2)
                                .frame(width: 48, height: 48)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedIcon == icon ? Color.blue.opacity(0.15) : Color(.systemGray6))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(selectedIcon == icon ? Color.blue : Color.clear, lineWidth: 2)
                                )
                        }
                        .foregroundStyle(selectedIcon == icon ? .blue : .primary)
                    }
                }
                .padding()
            }
            .navigationTitle("Choose Icon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
