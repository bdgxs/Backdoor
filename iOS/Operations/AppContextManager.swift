import UIKit
import CoreData
import SwiftUI

final class AppContextManager {
    static let shared = AppContextManager()
    private var currentState: AppContext?
    private var commandHandlers: [String: (String) -> Void] = [:]
    
    private init() {}
    
    func updateContext(_ viewController: UIViewController) {
        var additionalData: [String: Any] = [:]
        
        let sources = CoreDataManager.shared.getAZSources()
        let downloadedApps = CoreDataManager.shared.getDatedDownloadedApps()
        let signedApps = CoreDataManager.shared.getDatedSignedApps()
        let certificates = CoreDataManager.shared.getDatedCertificate()
        let currentCertificate = CoreDataManager.shared.getCurrentCertificate()
        
        additionalData["sources"] = sources.map { $0.name ?? "Unnamed" }
        additionalData["downloadedApps"] = downloadedApps.map { "\($0.name ?? "Unnamed") (\($0.version ?? "Unknown"))" }
        additionalData["signedApps"] = signedApps.map { "\($0.name ?? "Unnamed") (\($0.bundleidentifier ?? "Unknown")) - Team: \($0.teamName ?? "N/A")" }
        additionalData["certificates"] = certificates.map { $0.certData?.name ?? "Unnamed" }
        additionalData["currentCertificate"] = currentCertificate?.certData?.name ?? "None"
        additionalData["signingOptions"] = Preferences.signingOptions.description // Fixed line
        
        // Rest of the method remains unchanged
        switch viewController {
        case _ as UIHostingController<TabbarView>: // Updated line
            let selectedTab = UserDefaults.standard.string(forKey: "selectedTab") ?? "home"
            additionalData["currentTab"] = selectedTab
            switch selectedTab {
            case "home":
                additionalData["currentScreen"] = "Home"
            case "sources":
                additionalData["currentScreen"] = "Sources"
            case "library":
                additionalData["currentScreen"] = "Library"
            case "settings":
                additionalData["currentScreen"] = "Settings"
            case "bdgHub":
                additionalData["currentScreen"] = "BDG Hub"
            default:
                additionalData["currentScreen"] = "Unknown"
            }
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
    
    // Rest of the class remains unchanged
    func currentContext() -> AppContext {
        return currentState ?? AppContext(currentScreen: "Unknown", additionalData: [:])
    }
    
    func registerCommand(_ command: String, handler: @escaping (String) -> Void) {
        commandHandlers[command.lowercased()] = handler
    }
    
    func executeCommand(_ command: String, parameter: String) {
        let commandKey = command.lowercased()
        if let handler = commandHandlers[commandKey] {
            handler(parameter)
        } else {
            Debug.shared.log(message: "Unknown command: \(command)", type: .warning)
        }
    }
    
    func availableCommands() -> [String] {
        return Array(commandHandlers.keys)
    }
}