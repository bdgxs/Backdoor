import UIKit

class HomeViewUtilities {

    // Method to present a simple alert
    func presentAlert(in viewController: UIViewController, title: String, message: String, buttonTitle: String = "OK", handler: ((UIAlertAction) -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: buttonTitle, style: .default, handler: handler)
        alert.addAction(action)

        if handler != nil {
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        }

        viewController.present(alert, animated: true, completion: nil)
    }

    // Method to show an input alert
    func showInputAlert(in viewController: UIViewController, title: String, message: String, actionTitle: String, initialText: String = "", completion: @escaping (String) -> Void) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.text = initialText
        }
        let confirmAction = UIAlertAction(title: actionTitle, style: .default) { [weak alertController] _ in
            guard let textField = alertController?.textFields?.first, let text = textField.text else { return }
            completion(text)
        }
        alertController.addAction(confirmAction)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        viewController.present(alertController, animated: true, completion: nil)
    }

    // Method to handle errors
    func handleError(in viewController: UIViewController, error: Error, withTitle title: String = "Error") {
        presentAlert(in: viewController, title: title, message: "An error occurred: \(error.localizedDescription)")
    }
}