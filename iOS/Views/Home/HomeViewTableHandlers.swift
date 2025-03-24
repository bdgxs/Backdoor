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

        coordinator.items.forEach { dropItem in
            let itemProvider = dropItem.itemProvider // No need for explicit typing here
            itemProvider.loadObject(ofClass: URL.self) { [weak self] (object, error) in
                guard let self = self else { return }
                if let url = object as? URL {
                    let destinationURL = self.documentsDirectory.appendingPathComponent(url.lastPathComponent)
                    DispatchQueue.global(qos: .userInitiated).async {
                        do {
                            if url.startAccessingSecurityScopedResource() {
                                try self.fileManager.moveItem(at: url, to: destinationURL)
                                url.stopAccessingSecurityScopedResource()
                                DispatchQueue.main.async {
                                    self.loadFiles()
                                    HapticFeedbackGenerator.generateNotificationFeedback(type: .success)
                                }
                            }
                        } catch {
                            print("Error dropping file: \(error)")
                            DispatchQueue.main.async {
                                self.utilities.handleError(in: self, error: error, withTitle: "File Drop Error")
                            }
                        }
                    }
                }
            }
        }
    }
}