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
            additionalData["currentTab"] = "MainTabBar"
            // Try to determine the selected tab (this might need adjustment based on TabbarView implementation)
            if let tabBarController = vc.rootView as? UITabBarController {
                switch tabBarController.selectedIndex {
                case 0: // Assuming Sources is the first tab
                    additionalData["currentTab"] = "Sources"
                case 1: // Assuming Store/Hub is the second tab
                    additionalData["currentTab"] = "Store"
                case 2: // Assuming Library/Apps is the third tab
                    additionalData["currentTab"] = "Library"
                case 3: // Assuming Signing is the fourth tab
                    additionalData["currentTab"] = "Signing"
                case 4: // Assuming Settings is the fifth tab
                    additionalData["currentTab"] = "Settings"
                default:
                    additionalData["currentTab"] = "Home"
                }
            }
            
        // Add cases for other view controllers if they are presented modally or pushed
        default:
            // If a specific view controller is presented, we can add more context
            let screenName = String(describing: type(of: viewController))
            if screenName.contains("Sources") {
                additionalData["currentScreen"] = "Sources"
                // Add more specific context if needed (e.g., selected source)
            } else if screenName.contains("Hub") || screenName.contains("Store") {
                additionalData["currentScreen"] = "Store"
            } else if screenName.contains("Apps") || screenName.contains("Library") {
                additionalData["currentScreen"] = "Library"
            } else if screenName.contains("Signing") {
                additionalData["currentScreen"] = "Signing"
            } else if screenName.contains("Settings") {
                additionalData["currentScreen"] = "Settings"
            } else if screenName.contains("Home") {
                additionalData["currentScreen"] = "Home"
            }
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
}