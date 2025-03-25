import UIKit
import CoreData

/// Manages app context and command execution for Feather
final class AppContextManager {
    static let shared = AppContextManager()
    private var currentState: AppContext?
    private var commandHandlers: [String: (String) -> Void] = [:]
    
    private init() {}
    
    /// Updates the current app context based on the view controller
    func updateContext(_ viewController: UIViewController) {
        var additionalData: [String: Any] = [:]
        
        // Add Feather-specific context
        switch viewController {
        case let vc as UIHostingController<TabbarView>:
            additionalData["currentTab"] = "MainTabBar"
            additionalData["sources"] = CoreDataManager.shared.fetchSources().map { $0.name ?? "Unnamed" }
            additionalData["signingOptions"] = Preferences.signingOptions?.description ?? "Default"
            additionalData["installedApps"] = fetchInstalledApps() // Assuming a method to list installed apps
            additionalData["certificates"] = listCertificates()
            
        // Add cases for other view controllers in Feather if they exist
        default:
            additionalData["sources"] = CoreDataManager.shared.fetchSources().map { $0.name ?? "Unnamed" }
            additionalData["signingOptions"] = Preferences.signingOptions?.description ?? "Default"
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
            Debug.shared.log(message: "Unknown command: \(command)", type: .warning)
        }
    }
    
    /// Returns all available commands
    func availableCommands() -> [String] {
        return Array(commandHandlers.keys)
    }
    
    // MARK: - Private Helper Methods
    
    /// Fetches a list of installed apps (placeholder - implement based on your app's logic)
    private func fetchInstalledApps() -> [String] {
        // This is a placeholder - Feather doesn't explicitly track installed apps
        // You might need to implement this based on how Feather manages installations
        let documentsURL = getDocumentsDirectory().appendingPathComponent("Apps")
        let fileManager = FileManager.default
        if let appFiles = try? fileManager.contentsOfDirectory(atPath: documentsURL.path) {
            return appFiles.filter { $0.hasSuffix(".ipa") }.map { String($0.dropLast(4)) }
        }
        return []
    }
    
    /// Lists available certificates
    private func listCertificates() -> [String] {
        let documentsURL = getDocumentsDirectory().appendingPathComponent("Certificates")
        let fileManager = FileManager.default
        if let certFiles = try? fileManager.contentsOfDirectory(atPath: documentsURL.path) {
            return certFiles
        }
        return []
    }
}