import Foundation

enum AIServiceError: Error, LocalizedError {
    case networkError(Error)
    case httpError(Int)
    case rateLimited
    case decodingError(Error)
    case emptyResponse
    case allModelsFailed([Error])

    var errorDescription: String? {
        switch self {
        case .networkError(let error): return "Network error: \(error.localizedDescription)"
        case .httpError(let code): return "Server error (HTTP \(code)). Try again shortly."
        case .rateLimited: return "Rate limited — please try again in a minute."
        case .decodingError(let error): return "Failed to parse AI response: \(error.localizedDescription)"
        case .emptyResponse: return "Empty response from AI. Try again."
        case .allModelsFailed(let errors):
            let descriptions = errors.map { $0.localizedDescription }
            return "AI unavailable: \(descriptions.joined(separator: "; "))"
        }
    }

    /// Whether this error is transient and worth retrying with a different model
    var isRetryable: Bool {
        switch self {
        case .rateLimited, .emptyResponse: return true
        case .httpError(let code): return (500...599).contains(code)
        case .decodingError: return true
        default: return false
        }
    }
}

actor AIService {
    static let shared = AIService()

    private let baseURL = URL(string: Constants.aiServiceBaseURL)!
    private let primaryModel = "gemini-2.0-flash"
    private let fallbackModel = "gemini-2.0-flash-lite"
    private let maxRetries = 2

    struct Message: Codable {
        let role: String
        let content: String
    }

    // MARK: - Public API with Fallback

    /// Chat with automatic model fallback: tries primary model, falls back on retryable errors
    func chatWithFallback(
        messages: [Message],
        temperature: Double = 0.7,
        maxTokens: Int = 2048,
        jsonMode: Bool = false
    ) async throws -> String {
        let temp = jsonMode ? min(temperature, 0.3) : temperature
        var errors: [Error] = []

        // Try primary model
        do {
            return try await chat(
                messages: messages,
                temperature: temp,
                maxTokens: maxTokens,
                jsonMode: jsonMode,
                useFallbackModel: false
            )
        } catch let error as AIServiceError where error.isRetryable {
            errors.append(error)
        }

        // Try fallback model
        do {
            return try await chat(
                messages: messages,
                temperature: temp,
                maxTokens: maxTokens,
                jsonMode: jsonMode,
                useFallbackModel: true
            )
        } catch {
            errors.append(error)
            throw AIServiceError.allModelsFailed(errors)
        }
    }

    /// Chat JSON with fallback: tries primary, falls back on rate limit/5xx/decode errors
    func chatJSONWithFallback<T: Decodable>(
        messages: [Message],
        as type: T.Type,
        temperature: Double = 0.3,
        maxTokens: Int = 2048
    ) async throws -> T {
        var errors: [Error] = []

        // Try primary model
        do {
            return try await chatJSONSingle(
                messages: messages,
                as: type,
                temperature: temperature,
                maxTokens: maxTokens,
                useFallbackModel: false
            )
        } catch let error as AIServiceError where error.isRetryable {
            errors.append(error)
        }

        // Try fallback model
        do {
            return try await chatJSONSingle(
                messages: messages,
                as: type,
                temperature: temperature,
                maxTokens: maxTokens,
                useFallbackModel: true
            )
        } catch {
            errors.append(error)
            throw AIServiceError.allModelsFailed(errors)
        }
    }

    // MARK: - Single-Model Methods

    func chat(
        messages: [Message],
        temperature: Double = 0.7,
        maxTokens: Int = 2048,
        jsonMode: Bool = false,
        useFallbackModel: Bool = false
    ) async throws -> String {
        let model = useFallbackModel ? fallbackModel : primaryModel

        var body: [String: Any] = [
            "model": model,
            "messages": messages.map { ["role": $0.role, "content": $0.content] },
            "temperature": temperature,
            "max_tokens": maxTokens,
        ]

        if jsonMode {
            body["response_format"] = ["type": "json_object"]
        }

        let jsonData = try JSONSerialization.data(withJSONObject: body)

        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(Constants.aiServiceToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        request.timeoutInterval = 30

        var lastError: Error = AIServiceError.emptyResponse

        for attempt in 0...maxRetries {
            if attempt > 0 {
                let delay = UInt64(pow(2.0, Double(attempt - 1))) * 1_000_000_000
                try await Task.sleep(nanoseconds: delay)
            }

            do {
                let (data, response) = try await URLSession.shared.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse else {
                    throw AIServiceError.networkError(URLError(.badServerResponse))
                }

                switch httpResponse.statusCode {
                case 200:
                    return try parseResponse(data)
                case 429:
                    lastError = AIServiceError.rateLimited
                    continue
                case 500...599:
                    lastError = AIServiceError.httpError(httpResponse.statusCode)
                    continue
                default:
                    throw AIServiceError.httpError(httpResponse.statusCode)
                }
            } catch let error as AIServiceError {
                lastError = error
                if case .rateLimited = error { continue }
                if case .httpError(let code) = error, (500...599).contains(code) { continue }
                throw error
            } catch {
                throw AIServiceError.networkError(error)
            }
        }

        throw lastError
    }

    func chatJSON<T: Decodable>(messages: [Message], as type: T.Type) async throws -> T {
        let responseString = try await chat(messages: messages, jsonMode: true)

        guard let data = responseString.data(using: .utf8) else {
            throw AIServiceError.emptyResponse
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw AIServiceError.decodingError(error)
        }
    }

    func testConnection() async -> Bool {
        do {
            let messages = [Message(role: "user", content: "Say OK")]
            let response = try await chat(
                messages: messages,
                temperature: 0,
                maxTokens: 4,
                useFallbackModel: true
            )
            return !response.isEmpty
        } catch {
            return false
        }
    }

    // MARK: - Private

    private struct ChatCompletion: Decodable {
        struct Choice: Decodable {
            struct Message: Decodable {
                let content: String?
            }
            let message: Message
        }
        let choices: [Choice]
    }

    private func parseResponse(_ data: Data) throws -> String {
        let completion: ChatCompletion
        do {
            completion = try JSONDecoder().decode(ChatCompletion.self, from: data)
        } catch {
            throw AIServiceError.decodingError(error)
        }

        guard let content = completion.choices.first?.message.content, !content.isEmpty else {
            throw AIServiceError.emptyResponse
        }

        return content
    }

    private func chatJSONSingle<T: Decodable>(
        messages: [Message],
        as type: T.Type,
        temperature: Double,
        maxTokens: Int,
        useFallbackModel: Bool
    ) async throws -> T {
        let responseString = try await chat(
            messages: messages,
            temperature: temperature,
            maxTokens: maxTokens,
            jsonMode: true,
            useFallbackModel: useFallbackModel
        )

        guard let data = responseString.data(using: .utf8) else {
            throw AIServiceError.emptyResponse
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw AIServiceError.decodingError(error)
        }
    }
}
