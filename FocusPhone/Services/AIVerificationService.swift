import Foundation
import UIKit

actor AIVerificationService {
    static let shared = AIVerificationService()

    enum AIVerificationError: Error, LocalizedError {
        case imageCompressionFailed
        case networkError(Error)
        case httpError(Int, String)
        case invalidResponse
        case parseFailed

        var errorDescription: String? {
            switch self {
            case .imageCompressionFailed: return "Failed to process image"
            case .networkError(let error): return "Network error: \(error.localizedDescription)"
            case .httpError(let code, let msg): return "Server error (\(code)): \(msg)"
            case .invalidResponse: return "Invalid response from AI"
            case .parseFailed: return "Could not parse verification result"
            }
        }
    }

    func verifyPhoto(image: UIImage, commitment: Commitment) async throws -> AIVerificationResult {
        // Compress to JPEG < 500KB
        guard let imageData = compressImage(image) else {
            throw AIVerificationError.imageCompressionFailed
        }

        let base64Image = imageData.base64EncodedString()
        let systemPrompt = verificationPrompt(for: commitment)

        // Build Claude Messages API body
        let body: [String: Any] = [
            "model": "claude-sonnet-4-6-20250514",
            "max_tokens": 300,
            "system": systemPrompt,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "image",
                            "source": [
                                "type": "base64",
                                "media_type": "image/jpeg",
                                "data": base64Image
                            ]
                        ],
                        [
                            "type": "text",
                            "text": "Verify this photo for my \(commitment.category.displayName.lowercased()) commitment: \"\(commitment.title)\". Respond with JSON only."
                        ]
                    ]
                ]
            ]
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            throw AIVerificationError.imageCompressionFailed
        }

        guard let url = URL(string: Constants.aiVisionBaseURL) else {
            throw AIVerificationError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(Constants.aiServiceToken)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw AIVerificationError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIVerificationError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AIVerificationError.httpError(httpResponse.statusCode, body)
        }

        return try parseResponse(data)
    }

    // MARK: - Private

    private func compressImage(_ image: UIImage) -> Data? {
        var quality: CGFloat = 0.5
        var data = image.jpegData(compressionQuality: quality)

        while let d = data, d.count > 500_000, quality > 0.1 {
            quality -= 0.1
            data = image.jpegData(compressionQuality: quality)
        }

        return data
    }

    private func parseResponse(_ data: Data) throws -> AIVerificationResult {
        // Claude Messages API response format:
        // { "content": [{ "type": "text", "text": "..." }] }
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let firstBlock = content.first,
              let text = firstBlock["text"] as? String else {
            throw AIVerificationError.invalidResponse
        }

        // Extract JSON from response (handle markdown code blocks)
        let jsonString = extractJSON(from: text)

        guard let resultData = jsonString.data(using: .utf8),
              let resultJSON = try? JSONSerialization.jsonObject(with: resultData) as? [String: Any] else {
            throw AIVerificationError.parseFailed
        }

        let isVerified = resultJSON["isVerified"] as? Bool ?? false
        let confidence = resultJSON["confidence"] as? Double ?? 0.0
        let detectedContext = resultJSON["detectedContext"] as? String
        let failureReason = resultJSON["failureReason"] as? String

        // Apply confidence threshold
        if confidence < 0.65 {
            return AIVerificationResult(
                isVerified: false,
                confidence: confidence,
                detectedContext: detectedContext,
                failureReason: failureReason ?? "Photo unclear, try again"
            )
        }

        return AIVerificationResult(
            isVerified: isVerified,
            confidence: confidence,
            detectedContext: detectedContext,
            failureReason: isVerified ? nil : (failureReason ?? "Verification failed")
        )
    }

    private func extractJSON(from text: String) -> String {
        // Try to find JSON between ```json and ``` or { and }
        if let jsonStart = text.range(of: "```json"),
           let jsonEnd = text.range(of: "```", range: jsonStart.upperBound..<text.endIndex) {
            return String(text[jsonStart.upperBound..<jsonEnd.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if let start = text.firstIndex(of: "{"),
           let end = text.lastIndex(of: "}") {
            return String(text[start...end])
        }

        return text
    }

    private func verificationPrompt(for commitment: Commitment) -> String {
        let categoryPrompt: String
        switch commitment.category {
        case .gym:
            categoryPrompt = """
            You are verifying a GYM commitment. Look for: gym equipment, workout area, \
            exercise clothing, sweating, gym mirrors, weight racks, treadmills, or any \
            indication the person is at a gym or working out.
            """
        case .study:
            categoryPrompt = """
            You are verifying a STUDY commitment. Look for: books, notebooks, laptop with \
            study material, desk setup, library, notes, textbooks, or any indication the \
            person is studying or doing academic work.
            """
        case .work:
            categoryPrompt = """
            You are verifying a DEEP WORK commitment. Look for: computer screen with work \
            content, office setup, desk, professional tools, code editor, design tools, \
            or any indication the person is doing focused work.
            """
        case .outdoor:
            categoryPrompt = """
            You are verifying an OUTDOOR commitment. Look for: natural scenery, parks, \
            streets, sky, trees, outdoor lighting, sidewalks, trails, or any indication \
            the person is outside.
            """
        case .custom:
            categoryPrompt = """
            You are verifying a custom commitment titled "\(commitment.title)". \
            Look for any visual evidence that matches this activity.
            """
        }

        return """
        \(categoryPrompt)

        Analyze the photo and respond with ONLY a JSON object (no other text):
        {
          "isVerified": true/false,
          "confidence": 0.0-1.0,
          "detectedContext": "brief description of what you see",
          "failureReason": "reason if not verified, null otherwise"
        }

        Be fair but not easily fooled. A genuine attempt should pass. \
        Stock photos, screenshots of gyms, or clearly fake images should fail.
        """
    }
}
