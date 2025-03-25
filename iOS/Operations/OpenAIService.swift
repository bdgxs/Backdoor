import Foundation

/// Service for interacting with OpenAI API
final class OpenAIService {
    private let apiKey: String
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    private let session: URLSession
    
    init(apiKey: String) {
        self.apiKey = apiKey
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config)
    }
    
    enum ServiceError: Error, LocalizedError {
        case invalidURL
        case networkError(Error)
        case decodingError(Error)
        case noData
        
        var errorDescription: String? {
            switch self {
            case .invalidURL: return "Invalid API URL"
            case .networkError(let error): return "Network error: \(error.localizedDescription)"
            case .decodingError(let error): return "Decoding error: \(error.localizedDescription)"
            case .noData: return "No response data received"
            }
        }
    }
    
    func getAIResponse(prompt: String, context: AppContext, completion: @escaping (Result<String, ServiceError>) -> Void) {
        guard let url = URL(string: baseURL) else {
            completion(.failure(.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let fullPrompt = """
        App Context:
        \(context.toString())
        
        Available Commands:
        \(AppContextManager.shared.availableCommands().joined(separator: "\n"))
        
        User Request:
        \(prompt)
        
        Respond with either:
        1. A command in format [command:parameter]
        2. Helpful information based on context
        """
        
        let body: [String: Any] = [
            "model": "gpt-4",
            "messages": [
                ["role": "system", "content": "You are a highly capable app assistant"],
                ["role": "user", "content": fullPrompt]
            ],
            "temperature": 0.7,
            "max_tokens": 500
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(.failure(.decodingError(error)))
            return
        }
        
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(.networkError(error)))
                return
            }
            
            guard let data = data else {
                completion(.failure(.noData))
                return
            }
            
            do {
                let result = try JSONDecoder().decode(OpenAIResponse.self, from: data)
                if let content = result.choices.first?.message.content {
                    completion(.success(content))
                } else {
                    completion(.failure(.noData))
                }
            } catch {
                completion(.failure(.decodingError(error)))
            }
        }
        task.resume()
    }
}