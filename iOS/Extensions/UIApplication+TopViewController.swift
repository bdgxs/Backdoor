import UIKit

extension UIApplication {
    func topMostViewController() -> UIViewController? {
        guard let windowScene = connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return nil
        }
        var topController = window.rootViewController
        while let presentedController = topController?.presentedViewController {
            topController = presentedController
        }
        return topController
    }
}

extension Notification.Name {
    static let changeTab = Notification.Name("changeTab")
    static let showAIAssistant = Notification.Name("showAIAssistant")
}
