import UIKit

class HomeViewTableHandlers {
    private let utilities: HomeViewUtilities
    
    init(utilities: HomeViewUtilities) {
        self.utilities = utilities
    }
    
    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator, fileList: inout [File]) {
        let destinationIndexPath: IndexPath
        if let indexPath = coordinator.destinationIndexPath {
            destinationIndexPath = indexPath
        } else {
            let section = tableView.numberOfSections - 1
            let row = tableView.numberOfRows(inSection: section)
            destinationIndexPath = IndexPath(row: row, section: section)
        }
        
        guard let session = coordinator.session as? UIDragSession,
              let fileName = session.localContext as? String,
              let sourceIndex = fileList.firstIndex(where: { $0.name == fileName }) else { return }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let sourceFile = fileList[sourceIndex] // Get the File object
            
            // Reorder the file list without moving files on disk
            DispatchQueue.main.async {
                fileList.remove(at: sourceIndex)
                fileList.insert(sourceFile, at: destinationIndexPath.row) // Insert File, not String
                tableView.moveRow(at: IndexPath(row: sourceIndex, section: 0), to: destinationIndexPath)
                HapticFeedbackGenerator.generateNotificationFeedback(type: .success)
            }
        }
    }
}