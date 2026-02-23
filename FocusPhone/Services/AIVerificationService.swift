import Foundation
import UIKit
import Vision

actor AIVerificationService {
    static let shared = AIVerificationService()

    enum AIVerificationError: Error, LocalizedError {
        case imageConversionFailed
        case classificationFailed(Error)
        case noResults

        var errorDescription: String? {
            switch self {
            case .imageConversionFailed: return "Failed to process image"
            case .classificationFailed(let error): return "Classification failed: \(error.localizedDescription)"
            case .noResults: return "Could not classify image"
            }
        }
    }

    // MARK: - Category Label Mappings

    private static let categoryLabels: [CommitmentCategory: Set<String>] = [
        .gym: [
            "exercise", "gym", "weight_training", "dumbbell", "barbell",
            "treadmill", "fitness", "sport", "workout", "push-up",
            "squat", "bench_press", "exercise_equipment", "weights",
            "running", "jogging", "yoga", "stretching", "muscle",
            "athletic", "sports_equipment", "health_club"
        ],
        .study: [
            "book", "library", "desk", "laptop", "notebook",
            "writing", "reading", "pen", "pencil", "paper",
            "textbook", "study", "classroom", "school", "education",
            "computer", "keyboard", "monitor", "homework", "note"
        ],
        .work: [
            "computer", "desk", "office", "keyboard", "monitor",
            "laptop", "screen", "workspace", "chair", "table",
            "meeting", "whiteboard", "document", "typing", "desktop"
        ],
        .outdoor: [
            "sky", "nature", "street", "park", "outdoor",
            "tree", "grass", "cloud", "sun", "mountain",
            "beach", "river", "lake", "forest", "garden",
            "sidewalk", "trail", "path", "road", "landscape",
            "flower", "plant", "hill", "field", "ocean"
        ],
        .meditation: [
            "candle", "mat", "yoga", "meditation", "cushion",
            "incense", "calm", "sitting", "floor", "rug",
            "pillow", "blanket", "peaceful", "room", "quiet",
            "zen", "temple", "mindfulness", "breathing", "relaxation"
        ]
    ]

    // MARK: - Verify Photo

    func verifyPhoto(image: UIImage, commitment: Commitment) async throws -> AIVerificationResult {
        guard let cgImage = image.cgImage else {
            throw AIVerificationError.imageConversionFailed
        }

        let observations = try await classifyImage(cgImage)

        guard !observations.isEmpty else {
            throw AIVerificationError.noResults
        }

        return matchObservations(observations, for: commitment)
    }

    // MARK: - On-Device Classification

    private func classifyImage(_ cgImage: CGImage) async throws -> [VNClassificationObservation] {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNClassifyImageRequest { request, error in
                if let error {
                    continuation.resume(throwing: AIVerificationError.classificationFailed(error))
                    return
                }
                let results = (request.results as? [VNClassificationObservation]) ?? []
                // Only keep observations with meaningful confidence
                let filtered = results.filter { $0.confidence > 0.05 }
                continuation.resume(returning: filtered)
            }

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: AIVerificationError.classificationFailed(error))
            }
        }
    }

    // MARK: - Match Observations to Commitment

    private func matchObservations(_ observations: [VNClassificationObservation], for commitment: Commitment) -> AIVerificationResult {
        let targetLabels = Self.categoryLabels[commitment.category] ?? []
        let topLabels = observations.prefix(20)

        // For custom category, be lenient — any real photo passes
        if commitment.category == .custom {
            let topConfidence = observations.first?.confidence ?? 0
            let detectedItems = topLabels.prefix(3).map { $0.identifier.replacingOccurrences(of: "_", with: " ") }
            let context = detectedItems.joined(separator: ", ")

            return AIVerificationResult(
                isVerified: topConfidence > 0.1,
                confidence: Double(min(topConfidence * 2, 1.0)),
                detectedContext: context,
                failureReason: topConfidence <= 0.1 ? "Could not identify activity in photo" : nil
            )
        }

        // Find matching labels and sum their confidence
        var matchedConfidence: Float = 0
        var matchedLabels: [String] = []

        for observation in topLabels {
            let label = observation.identifier.lowercased()
            let matches = targetLabels.contains(where: { label.contains($0) || $0.contains(label) })
            if matches {
                matchedConfidence += observation.confidence
                matchedLabels.append(observation.identifier.replacingOccurrences(of: "_", with: " "))
            }
        }

        // Normalize confidence (cap at 1.0)
        let confidence = Double(min(matchedConfidence, 1.0))
        let detectedContext = matchedLabels.isEmpty
            ? topLabels.prefix(3).map { $0.identifier.replacingOccurrences(of: "_", with: " ") }.joined(separator: ", ")
            : matchedLabels.prefix(3).joined(separator: ", ")

        let isVerified = confidence >= 0.15

        return AIVerificationResult(
            isVerified: isVerified,
            confidence: isVerified ? max(confidence, 0.65) : confidence,
            detectedContext: detectedContext,
            failureReason: isVerified ? nil : "Doesn't look like \(commitment.category.displayName.lowercased()). Try again with a clearer photo."
        )
    }
}
