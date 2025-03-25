import Foundation

/// Represents the current state of the app for AI context
struct AppContext {
    let currentScreen: String
    let additionalData: [String: Any]
    
    func toString() -> String {
        var result = "Current Screen: \(currentScreen)\n"
        result += "App Data:\n"
        for (key, value) in additionalData {
            result += "- \(key): \(value)\n"
        }
        return result
    }
}