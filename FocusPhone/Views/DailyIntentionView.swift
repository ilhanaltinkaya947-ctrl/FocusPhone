import SwiftUI

struct DailyIntentionView: View {
    let intention: DailyIntention?
    let onSave: (String) -> Void

    @State private var isEditing = false
    @State private var editText = ""
    @FocusState private var textFieldFocused: Bool

    private var hasIntention: Bool {
        guard let intention else { return false }
        return !intention.text.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: FPTheme.spacing8) {
            HStack {
                Text("TODAY'S INTENTION")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(FPTheme.textSecondary)
                    .tracking(1.0)

                Spacer()

                if hasIntention && !isEditing {
                    Button {
                        isEditing = true
                        textFieldFocused = true
                    } label: {
                        Image(systemName: "pencil")
                            .font(.caption)
                            .foregroundStyle(FPTheme.textSecondary)
                    }
                }
            }

            if isEditing || !hasIntention {
                HStack(spacing: FPTheme.spacing8) {
                    TextField("What's your focus today?", text: $editText)
                        .font(FPTheme.bodyFont)
                        .focused($textFieldFocused)
                        .onSubmit { commitIntention() }

                    Button { commitIntention() } label: {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(
                                editText.trimmingCharacters(in: .whitespaces).isEmpty
                                    ? FPTheme.textSecondary.opacity(0.4)
                                    : FPTheme.textSecondary
                            )
                    }
                    .disabled(editText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            } else {
                Text(intention?.text ?? "")
                    .font(.system(size: 17, weight: .medium, design: .serif))
                    .foregroundStyle(FPTheme.textPrimary)
                    .italic()
            }
        }
        .padding(FPTheme.spacing16)
        .background(
            RoundedRectangle(cornerRadius: FPTheme.cardRadius)
                .fill(FPTheme.backgroundSecondary)
        )
        .onAppear {
            editText = intention?.text ?? ""
        }
    }

    private func commitIntention() {
        let trimmed = editText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        onSave(trimmed)
        isEditing = false
        textFieldFocused = false
    }
}
