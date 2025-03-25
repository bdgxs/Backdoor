import UIKit
import CoreData
import SwiftUI

/// Manages app context and command execution for Feather
final class AppContextManager {
    static let shared = AppContextManager()
    private var currentState: AppContext?
    private var commandHandlers: [String: (String) -> Void] = [:]
    
    private init() {}
    
    /// Updates the current app context based on the view controller
    func updateContext(_ viewController: UIViewController) {
        var additionalData: [String: Any] = [:]
        
        // Fetch data from CoreDataManager
        let sources = CoreDataManager.shared.getAZSources()
        let downloadedApps = CoreDataManager.shared.getDatedDownloadedApps()
        let signedApps = CoreDataManager.shared.getDatedSignedApps()
        let certificates = CoreDataManager.shared.getDatedCertificate()
        let currentCertificate = CoreDataManager.shared.getCurrentCertificate()
        
        // Base context available on all screens
        additionalData["sources"] = sources.map { $0.name ?? "Unnamed" }
        additionalData["downloadedApps"] = downloadedApps.map { "\($0.name ?? "Unnamed") (\($0.version ?? "Unknown"))" }
        additionalData["signedApps"] = signedApps.map { "\($0.name ?? "Unnamed") (\($0.bundleidentifier ?? "Unknown")) - Team: \($0.teamName ?? "N/A")" }
        additionalData["certificates"] = certificates.map { $0.certData?.name ?? "Unnamed" }
        additionalData["currentCertificate"] = currentCertificate?.certData?.name ?? "None"
        additionalData["signingOptions"] = Preferences.signingOptions?.description ?? "Default"
        
        // Add screen-specific context
        switch viewController {
        case let vc as UIHostingController<TabbarView>:
            // Determine the current tab from UserDefaults
            let selectedTab = UserDefaults.standard.string(forKey: "selectedTab") ?? "home"
            additionalData["currentTab"] = selectedTab
            
            // Add tab-specific context
            switch selectedTab {
            case "home":
                additionalData["currentScreen"] = "Home"
                // Add more specific context if needed (e.g., featured apps)
            case "sources":
                additionalData["currentScreen"] = "Sources"
                // Add more specific context if needed (e.g., selected source)
            case "library":
                additionalData["currentScreen"] = "Library"
                // Add more specific context if needed (e.g., selected app)
            case "settings":
                additionalData["currentScreen"] = "Settings"
                // Add more specific context if needed (e.g., current settings)
            case "bdgHub":
                additionalData["currentScreen"] = "BDG Hub"
                // Add more specific context if needed (e.g., current URL in WebView)
            default:
                additionalData["currentScreen"] = "Unknown"
            }
            
        // Handle other view controllers (e.g., if a modal or pushed view is presented)
        default:
            let screenName = String(describing: type(of: viewController))
            if screenName.contains("Home") {
                additionalData["currentScreen"] = "Home"
            } else if screenName.contains("Sources") {
                additionalData["currentScreen"] = "Sources"
            } else if screenName.contains("Library") {
                additionalData["currentScreen"] = "Library"
            } else if screenName.contains("Settings") {
                additionalData["currentScreen"] = "Settings"
            } else if screenName.contains("WebView") || screenName.contains("BDGHub") {
                additionalData["currentScreen"] = "BDG Hub"
            } else {
                additionalData["currentScreen"] = "Unknown"
            }
        }
        
        currentState = AppContext(currentScreen: additionalData["currentScreen"] as? String ?? "Unknown",
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
}