import UIKit

extension HomeViewController: UITableViewDropDelegate {
    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
        let destinationIndexPath: IndexPath
        if let indexPath = coordinator.destinationIndexPath {
            destinationIndexPath = indexPath
        } else {
            let section = tableView.numberOfSections - 1
            let row = tableView.numberOfRows(inSection: section)
            destinationIndexPath = IndexPath(row: row, section: section)
        }

        // Explicitly type dropItem as UITableViewDropItem
        coordinator.items.forEach { (dropItem: UITableViewDropItem) in
            let itemProvider: NSItemProvider = dropItem.itemProvider
            itemProvider.loadObject(ofClass: URL.self) { [weak self] (object: URL?, error: Error?) in
                guard let self else { return }
                
                if let url = object {
                    let destinationURL = self.documentsDirectory.appendingPathComponent(url.lastPathComponent)
                    do {
                        try self.fileManager.moveItem(at: url, to: destinationURL)
                        DispatchQueue.main.async {
                            self.loadFiles()
                        }
                    } catch {
                        print("Error dropping file: \(error)")
                        DispatchQueue.main.async {
                            let alert = UIAlertController(
                                title: "Error",
                                message: "Failed to move file: \(error.localizedDescription)",
                                preferredStyle: .alert
                            )
                            alert.addAction(UIAlertAction(title: "OK", style: .default))
                            self.present(alert, animated: true, completion: nil)
                        }
                    }
                }
            }
        }
    }
}