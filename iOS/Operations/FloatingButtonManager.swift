import UIKit
import SwiftUI

/// Manages the floating AI button across the app
final class FloatingButtonManager {
    static let shared = FloatingButtonManager()
    private let aiService: OpenAIService
    private let floatingButton: FloatingAIButton
    private var window: UIWindow?
    
    private init() {
        aiService = OpenAIService(apiKey: "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")
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
        
        // Register Feather-specific commands
        AppContextManager.shared.registerCommand("add source") { sourceURL in
            if let url = URL(string: sourceURL) {
                CoreDataManager.shared.saveSource(name: "Custom Source", id: UUID().uuidString, iconURL: nil, url: sourceURL) { error in
                    if let error = error {
                        Debug.shared.log(message: "Failed to add source: \(error)", type: .error)
                    } else {
                        Debug.shared.log(message: "Added source: \(sourceURL)", type: .success)
                    }
                }
            } else {
                Debug.shared.log(message: "Invalid source URL: \(sourceURL)", type: .error)
            }
        }
        
        AppContextManager.shared.registerCommand("list sources") { _ in
            let sources = CoreDataManager.shared.getAZSources()
            let sourceNames = sources.map { $0.name ?? "Unnamed" }.joined(separator: "\n")
            if let topVC = UIApplication.shared.topMostViewController() {
                let alert = UIAlertController(title: "Sources", message: sourceNames.isEmpty ? "No sources available" : sourceNames, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                topVC.present(alert, animated: true)
            }
        }
        
        AppContextManager.shared.registerCommand("list downloaded apps") { _ in
            let apps = CoreDataManager.shared.getDatedDownloadedApps()
            let appNames = apps.map { "\($0.name ?? "Unnamed") (\($0.version ?? "Unknown"))" }.joined(separator: "\n")
            if let topVC = UIApplication.shared.topMostViewController() {
                let alert = UIAlertController(title: "Downloaded Apps", message: appNames.isEmpty ? "No downloaded apps" : appNames, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                topVC.present(alert, animated: true)
            }
        }
        
        AppContextManager.shared.registerCommand("list signed apps") { _ in
            let apps = CoreDataManager.shared.getDatedSignedApps()
            let appNames = apps.map { "\($0.name ?? "Unnamed") (\($0.bundleidentifier ?? "Unknown"))" }.joined(separator: "\n")
            if let topVC = UIApplication.shared.topMostViewController() {
                let alert = UIAlertController(title: "Signed Apps", message: appNames.isEmpty ? "No signed apps" : appNames, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                topVC.present(alert, animated: true)
            }
        }
        
        AppContextManager.shared.registerCommand("list certificates") { _ in
            let certificates = CoreDataManager.shared.getDatedCertificate()
            let certNames = certificates.map { $0.certData?.name ?? "Unnamed" }.joined(separator: "\n")
            if let topVC = UIApplication.shared.topMostViewController() {
                let alert = UIAlertController(title: "Certificates", message: certNames.isEmpty ? "No certificates" : certNames, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                topVC.present(alert, animated: true)
            }
        }
        
        AppContextManager.shared.registerCommand("navigate to") { screen in
            guard let _ = UIApplication.shared.topMostViewController() as? UIHostingController<TabbarView> else {
                Debug.shared.log(message: "Cannot navigate: Not on main tab bar", type: .error)
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
                return
            }
            
            UserDefaults.standard.set(targetTab, forKey: "selectedTab")
            NotificationCenter.default.post(name: .changeTab, object: nil, userInfo: ["tab": targetTab])
        }
    }
    
    @objc private func handleAIRequest() {
        guard let topController = UIApplication.shared.topMostViewController() else { return }
        AppContextManager.shared.updateContext(topController)
        
        let alert = UIAlertController(title: "AI Assistant",
                                    message: "How can I help you?",
                                    preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Type your request..."
            textField.autocapitalizationType = .sentences
        }
        
        alert.addAction(UIAlertAction(title: "Ask", style: .default) { _ in
            if let text = alert.textFields?.first?.text, !text.isEmpty {
                self.processAIRequest(text, from: topController)
            }
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        topController.present(alert, animated: true)
    }
    
    private func processAIRequest(_ request: String, from controller: UIViewController) {
        let context = AppContextManager.shared.currentContext()
        aiService.getAIResponse(prompt: request, context: context) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    self.handleAIResponse(response, from: controller)
                case .failure(let error):
                    self.showError(error.localizedDescription, from: controller)
                }
            }
        }
    }
    
    private func handleAIResponse(_ response: String, from controller: UIViewController) {
        let commandPattern = "\\[(.*?)\\:(.*?)\\]"
        if let regex = try? NSRegularExpression(pattern: commandPattern),
           let match = regex.firstMatch(in: response, range: NSRange(response.startIndex..., in: response)),
           let commandRange = Range(match.range(at: 1), in: response),
           let paramRange = Range(match.range(at: 2), in: response) {
            
            let command = String(response[commandRange])
            let parameter = String(response[paramRange])
            AppContextManager.shared.executeCommand(command, parameter: parameter)
        } else {
            let alert = UIAlertController(title: "AI Response",
                                        message: response,
                                        preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            controller.present(alert, animated: true)
        }
    }
    
    private func showError(_ message: String, from controller: UIViewController) {
        let alert = UIAlertController(title: "Error",
                                    message: message,
                                    preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        controller.present(alert, animated: true)
    }
}