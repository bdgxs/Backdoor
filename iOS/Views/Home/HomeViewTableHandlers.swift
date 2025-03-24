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
            // Use localObject instead of itemProvider
            guard let fileName = dropItem.localObject as? String else { return }
            let sourceURL = documentsDirectory.appendingPathComponent(fileName)
            let destinationURL = documentsDirectory.appendingPathComponent(fileName) // Same directory, just reordering in list

            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else { return }
                do {
                    // For simplicity, just update the file list order (no file system move needed)
                    DispatchQueue.main.async {
                        let sourceIndex = self.fileList.firstIndex(of: fileName)
                        if let sourceIndex = sourceIndex {
                            self.fileList.remove(at: sourceIndex)
                            self.fileList.insert(fileName, at: destinationIndexPath.row)
                            tableView.moveRow(at: IndexPath(row: sourceIndex, section: 0), to: destinationIndexPath)
                            HapticFeedbackGenerator.generateNotificationFeedback(type: .success)
                        }
                    }
                } catch {
                    print("Error handling drop: \(error)")
                    DispatchQueue.main.async {
                        self.utilities.handleError(in: self, error: error, withTitle: "File Drop Error")
                    }
                }
            }
        }
    }
}