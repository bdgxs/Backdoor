import Foundation

class ProcessUtility {
    static let shared = ProcessUtility()

    private init() {}

    /// Executes a shell command on the backend server and returns the output.
    /// - Parameters:
    ///   - command: The shell command to be executed.
    ///   - completion: A closure to be called with the command's output or an error message.
    func executeShellCommand(_ command: String, completion: @escaping (String?) -> Void) {
        // Ensure the URL is valid
        guard let url = URL(string: "https://backdoor-backend.onrender.com/execute-command") else {
            completion("Invalid URL")
            return
        }

        // Create a URL request and set the HTTP method to POST
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Create the request body with the shell command
        let body = ["command": command]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])

        // Create a data task to execute the request
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            // Handle network errors
            guard let data = data, error == nil else {
                print("Network error: \(error?.localizedDescription ?? "Unknown error")")
                completion("Network error: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            // Parse the response data
            let result = String(data: data, encoding: .utf8)
            completion(result)
        }

        // Start the data task
        task.resume()
    }
}