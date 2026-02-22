import SwiftUI
import PhotosUI

struct VerificationView: View {
    @ObservedObject var viewModel: CommitmentViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showCamera = false
    @State private var showPhotoPicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?

    private var commitment: Commitment? { viewModel.selectedCommitment }

    var body: some View {
        ZStack {
            RawDog.Colors.background.ignoresSafeArea()

            VStack(spacing: RawDog.Spacing.lg) {
                // Header
                if let commitment {
                    Text("\(commitment.emoji) \(commitment.title)")
                        .font(RawDog.Typography.title)
                        .foregroundStyle(RawDog.Colors.textPrimary)
                }

                Spacer()

                if let result = viewModel.verificationResult {
                    resultView(result)
                } else if viewModel.isVerifying {
                    loadingView
                } else if let image = viewModel.verificationImage {
                    previewView(image)
                } else {
                    captureView
                }

                Spacer()

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(RawDog.Typography.caption)
                        .foregroundStyle(RawDog.Colors.destructive)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            .padding()
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraRepresentable(image: $viewModel.verificationImage)
                .ignoresSafeArea()
        }
        .onChange(of: selectedPhotoItem) {
            loadPhoto()
        }
    }

    // MARK: - Sub Views

    private var captureView: some View {
        VStack(spacing: RawDog.Spacing.md) {
            RawDogMascot(state: .neutral, size: 100)

            Text("Take a photo to prove it")
                .font(RawDog.Typography.headline)
                .foregroundStyle(RawDog.Colors.textSecondary)

            RawDog.PillButton(title: "Open Camera") {
                showCamera = true
            }

            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                Text("Choose from Library")
                    .font(RawDog.Typography.headline)
                    .foregroundStyle(RawDog.Colors.accent)
            }
        }
    }

    private func previewView(_ image: UIImage) -> some View {
        VStack(spacing: RawDog.Spacing.md) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 300)
                .clipShape(RoundedRectangle(cornerRadius: RawDog.Radius.card))

            RawDog.PillButton(title: "Submit for Verification") {
                viewModel.submitVerification()
            }

            Button("Retake") {
                viewModel.verificationImage = nil
            }
            .font(RawDog.Typography.subheadline)
            .foregroundStyle(RawDog.Colors.textSecondary)
        }
    }

    private var loadingView: some View {
        VStack(spacing: RawDog.Spacing.md) {
            RawDogMascot(state: .neutral, size: 100)

            Text("RawDog is reviewing your evidence...")
                .font(RawDog.Typography.headline)
                .foregroundStyle(RawDog.Colors.textSecondary)

            ProgressView()
                .tint(RawDog.Colors.accent)
        }
    }

    private func resultView(_ result: AIVerificationResult) -> some View {
        VStack(spacing: RawDog.Spacing.md) {
            if result.isVerified {
                RawDogMascot(state: .proud, size: 120)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(RawDog.Colors.approved)

                Text("Verified!")
                    .font(RawDog.Typography.title)
                    .foregroundStyle(RawDog.Colors.approved)

                Text("\(Int(result.confidence * 100))% confidence")
                    .font(RawDog.Typography.caption)
                    .foregroundStyle(RawDog.Colors.textSecondary)

                Text("45 min freedom granted!")
                    .font(RawDog.Typography.headline)
                    .foregroundStyle(RawDog.Colors.accent)

                RawDog.PillButton(title: "Done") {
                    dismiss()
                }
            } else {
                RawDogMascot(state: .sideeye, size: 120)

                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(RawDog.Colors.destructive)

                Text("Not Verified")
                    .font(RawDog.Typography.title)
                    .foregroundStyle(RawDog.Colors.destructive)

                if let reason = result.failureReason {
                    Text(reason)
                        .font(RawDog.Typography.subheadline)
                        .foregroundStyle(RawDog.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }

                RawDog.PillButton(title: "Try Again") {
                    viewModel.verificationImage = nil
                    viewModel.verificationResult = nil
                }
            }
        }
    }

    // MARK: - Helpers

    private func loadPhoto() {
        guard let item = selectedPhotoItem else { return }
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                viewModel.verificationImage = image
            }
        }
    }
}
