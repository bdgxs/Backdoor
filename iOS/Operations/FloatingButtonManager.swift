import UIKit
import SwiftUI

/// Manages the floating AI button across the app
final class FloatingButtonManager {
    static let shared = FloatingButtonManager()
    private let aiService: OpenAIService
    private let floatingButton: FloatingAIButton
    private var window: UIWindow?
    
    private init() {
        aiService = OpenAIService(apiKey: "sk-proj-P6BYXJlsZ0oAhG1G9TRmQaSzFSdg0CfwMMz6BEXgpmgEieQl2QBNcbKhr8C5o314orxOa_0S7vT3BlbkFJD5cQCpc5d8bK2GvswZNCPRQ8AIqtlujlLiC8Blj72r5_3d6YWlOEq23QyddeMZF[...]")
        floatingButton = FloatingAIButton()
        setupWindow()
        setupAIInteraction()
    }
    
    private func setupWindow() {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        window = UIWindow(windowScene: scene)
        window?.windowLevel = .alert
        window?.rootViewController = UIViewController()
        window?.isHidden = false
        window?.addSubview(floatingButton)
        
        let safeArea = window?.safeAreaInsets ?? .zero
        floatingButton.center = CGPoint(x: scene.coordinateSpace.bounds.width - 40 - safeArea.right,
                                      y: scene.coordinateSpace.bounds.height - 100 - safeArea.bottom)
        
        NotificationCenter.default.addObserver(self,
                                             selector: #selector(handleOrientationChange),
                                             name: UIDevice.orientationDidChangeNotification,
                                             object: nil)
    }
    
    @objc private func handleOrientationChange() {
        guard let scene = window?.windowScene else { return }
        let safeArea = window?.safeAreaInsets ?? .zero
        UIView.animate(withDuration: 0.3) {
            self.floatingButton.center = CGPoint(x: scene.coordinateSpace.bounds.width - 40 - safeArea.right,
                                              y: scene.coordinateSpace.bounds.height - 100 - safeArea.bottom)
        }
    }
    
    func show() {
        floatingButton.isHidden = false
    }
    
    func hide() {
        floatingButton.isHidden = true
    }
    
    private func setupAIInteraction() {
        NotificationCenter.default.addObserver(self,
                                             selector: #selector(handleAIRequest),
                                             name: .showAIAssistant,
                                             object: nil)
        
        // Register Feather-specific commands with completion handlers
        AppContextManager.shared.registerCommand("add source") { sourceURL, completion in
            if URL(string: sourceURL) != nil {
                CoreDataManager.shared.saveSource(name: "Custom Source", id: UUID().uuidString, iconURL: nil, url: sourceURL) { error in
                    if let error = error {
                        Debug.shared.log(message: "Failed to add source: \(error)", type: .error)
                        completion("Failed to add source: \(error.localizedDescription)")
                    } else {
                        Debug.shared.log(message: "Added source: \(sourceURL)", type: .success)
                        completion("Source added successfully")
                    }
                }
            } else {
                Debug.shared.log(message: "Invalid source URL: \(sourceURL)", type: .error)
                completion("Invalid source URL")
            }
        }
        
        AppContextManager.shared.registerCommand("list sources") { _, completion in
            let sources = CoreDataManager.shared.getAZSources()
            let sourceNames = sources.map { $0.name ?? "Unnamed" }.joined(separator: "\n")
            completion(sourceNames.isEmpty ? "No sources available" : sourceNames)
        }
        
        AppContextManager.shared.registerCommand("list downloaded apps") { _, completion in
            let apps = CoreDataManager.shared.getDatedDownloadedApps()
            let appNames = apps.map { "\($0.name ?? "Unnamed") (\($0.version ?? "Unknown"))" }.joined(separator: "\n")
            completion(appNames.isEmpty ? "No downloaded apps" : appNames)
        }
        
        AppContextManager.shared.registerCommand("list signed apps") { _, completion in
            let apps = CoreDataManager.shared.getDatedSignedApps()
            let appNames = apps.map { "\($0.name ?? "Unnamed") (\($0.bundleidentifier ?? "Unknown"))" }.joined(separator: "\n")
            completion(appNames.isEmpty ? "No signed apps" : appNames)
        }
        
        AppContextManager.shared.registerCommand("list certificates") { _, completion in
            let certificates = CoreDataManager.shared.getDatedCertificate()
            let certNames = certificates.map { $0.certData?.name ?? "Unnamed" }.joined(separator: "\n")
            completion(certNames.isEmpty ? "No certificates" : certNames)
        }
        
        AppContextManager.shared.registerCommand("navigate to") { screen, completion in
            guard let _ = UIApplication.shared.topMostViewController() as? UIHostingController<TabbarView> else {
                Debug.shared.log(message: "Cannot navigate: Not on main tab bar", type: .error)
                completion("Cannot navigate: Not on main screen")
                return
            }
            
            var targetTab: String
            switch screen.lowercased() {
            case "home":
                targetTab = "home"
            case "sources":
                targetTab = "sources"
            case "library":
                targetTab = "library"
            case "settings":
                targetTab = "settings"
            case "bdg hub", "bdghub", "hub":
                targetTab = "bdgHub"
            default:
                Debug.shared.log(message: "Unknown screen: \(screen)", type: .warning)
                completion("Unknown screen: \(screen)")
                return
            }
            
            UserDefaults.standard.set(targetTab, forKey: "selectedTab")
            NotificationCenter.default.post(name: .changeTab, object: nil, userInfo: ["tab": targetTab])
            completion("Navigated to \(screen)")
        }
    }
    
    @objc private func handleAIRequest() {
        let chatVC = ChatViewController()
        let navController = UINavigationController(rootViewController: chatVC)
        if let topVC = UIApplication.shared.topMostViewController() {
            topVC.present(navController, animated: true)
        }
    }
}