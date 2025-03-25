import UIKit

/// Manages the floating AI button across the app
final class FloatingButtonManager {
    static let shared = FloatingButtonManager()
    private let aiService: OpenAIService
    private let floatingButton: FloatingAIButton
    private var window: UIWindow?
    
    private init() {
        aiService = OpenAIService(apiKey: "YOUR_OPENAI_API_KEY")
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
        
        // TODO: Register your app-specific commands here
        AppContextManager.shared.registerCommand("create note") { parameter in
            // Implementation needed from your app
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