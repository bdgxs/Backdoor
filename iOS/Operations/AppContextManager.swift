import UIKit

/// Manages app context and command execution
final class AppContextManager {
    static let shared = AppContextManager()
    private var currentState: AppContext?
    private var commandHandlers: [String: (String) -> Void] = [:]
    
    private init() {}
    
    /// Updates the current app context based on the view controller
    func updateContext(_ viewController: UIViewController) {
        var additionalData: [String: Any] = [:]
        
        // TODO: Add your app-specific context here
        switch viewController {
        default:
            break
        }
        
        currentState = AppContext(currentScreen: String(describing: type(of: viewController)),
                                additionalData: additionalData)
    }
    
    /// Returns the current app context
    func currentContext() -> AppContext {
        return currentState ?? AppContext(currentScreen: "Unknown", additionalData: [:])
    }
    
    /// Registers a command handler
    func registerCommand(_ command: String, handler: @escaping (String) -> Void) {
        commandHandlers[command.lowercased()] = handler
    }
    
    /// Executes a registered command
    func executeCommand(_ command: String, parameter: String) {
        let commandKey = command.lowercased()
        if let handler = commandHandlers[commandKey] {
            handler(parameter)
        } else {
            NSLog("Unknown command: \(command)")
        }
    }
    
    /// Returns all available commands
    func availableCommands() -> [String] {
        return Array(commandHandlers.keys)
    }
}