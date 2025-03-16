import UIKit
import ZIPFoundation

class HomeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIDocumentPickerDelegate, UISearchResultsUpdating, UITableViewDragDelegate, UITableViewDropDelegate {

    // ... existing code ...

    // MARK: - Helper Methods
    private func presentAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    private func presentFileOptions(for fileURL: URL) {
        let fileExtension = fileURL.pathExtension.lowercased()
        let menu = UIAlertController(title: "File Options", message: nil, preferredStyle: .actionSheet)
        
        switch fileExtension {
        case "txt":
            menu.addAction(UIAlertAction(title: "Open as Text", style: .default, handler: { _ in self.openTextEditor(fileURL) }))
        case "plist":
            menu.addAction(UIAlertAction(title: "Open as Plist", style: .default, handler: { _ in self.openPlistEditor(fileURL) }))
        case "ipa":
            menu.addAction(UIAlertAction(title: "Unzip", style: .default, handler: { _ in self.unzipFile(at: fileURL) }))
            menu.addAction(UIAlertAction(title: "Hex Edit", style: .default, handler: { _ in self.hexEditFile(at: fileURL) }))
        default:
            menu.addAction(UIAlertAction(title: "Open as Hex", style: .default, handler: { _ in self.openHexEditor(fileURL) }))
        }
        
        menu.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(menu, animated: true, completion: nil)
    }

    // ... rest of the existing methods ...

}