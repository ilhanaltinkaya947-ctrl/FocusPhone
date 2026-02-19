import Foundation

enum GroqError: Error, LocalizedError {
    case noAPIKey
    case networkError(Error)
    case httpError(Int)
    case rateLimited
    case decodingError(Error)
    case emptyResponse

    var errorDescription: String? {
        switch self {
        case .noAPIKey: return "No API key configured"
        case .networkError(let error): return "Network error: \(error.localizedDescription)"
        case .httpError(let code): return "Server error (HTTP \(code))"
        case .rateLimited: return "Rate limited — please try again shortly"
        case .decodingError(let error): return "Failed to parse response: \(error.localizedDescription)"
        case .emptyResponse: return "Empty response from AI"
        }
    }
}

actor GroqService {
    static let shared = GroqService()

    private let baseURL = URL(string: "https://api.groq.com/openai/v1/chat/completions")!
    private let primaryModel = "llama-3.3-70b-versatile"
    private let fallbackModel = "llama-3.1-8b-instant"
    private let maxRetries = 2

    struct Message: Codable {
        let role: String
        let content: String
    }

    func chat(
        messages: [Message],
        temperature: Double = 0.7,
        maxTokens: Int = 2048,
        jsonMode: Bool = false,
        useFallbackModel: Bool = false
    ) async throws -> String {
        guard let apiKey = KeychainService.getAPIKey() else {
            throw GroqError.noAPIKey
        }

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
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        request.timeoutInterval = 30

        var lastError: Error = GroqError.emptyResponse

        for attempt in 0...maxRetries {
            if attempt > 0 {
                let delay = UInt64(pow(2.0, Double(attempt - 1))) * 1_000_000_000
                try await Task.sleep(nanoseconds: delay)
            }

            do {
                let (data, response) = try await URLSession.shared.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse else {
                    throw GroqError.networkError(URLError(.badServerResponse))
                }

                switch httpResponse.statusCode {
                case 200:
                    return try parseResponse(data)
                case 429:
                    lastError = GroqError.rateLimited
                    continue
                case 500...599:
                    lastError = GroqError.httpError(httpResponse.statusCode)
                    continue
                default:
                    throw GroqError.httpError(httpResponse.statusCode)
                }
            } catch let error as GroqError {
                lastError = error
                if case .rateLimited = error { continue }
                if case .httpError(let code) = error, (500...599).contains(code) { continue }
                throw error
            } catch {
                throw GroqError.networkError(error)
            }
        }

        throw lastError
    }

    func chatJSON<T: Decodable>(messages: [Message], as type: T.Type) async throws -> T {
        let responseString = try await chat(messages: messages, jsonMode: true)

        guard let data = responseString.data(using: .utf8) else {
            throw GroqError.emptyResponse
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw GroqError.decodingError(error)
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
            throw GroqError.decodingError(error)
        }

        guard let content = completion.choices.first?.message.content, !content.isEmpty else {
            throw GroqError.emptyResponse
        }

        return content
    }
}
