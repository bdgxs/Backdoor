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

        guard let session = coordinator.session as? UIDragSession,
              let fileName = session.localContext as? String else { return }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let sourceURL = self.documentsDirectory.appendingPathComponent(fileName)
            
            do {
                // Reorder the file list without moving files on disk
                DispatchQueue.main.async {
                    if let sourceIndex = self.fileList.firstIndex(of: fileName) {
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