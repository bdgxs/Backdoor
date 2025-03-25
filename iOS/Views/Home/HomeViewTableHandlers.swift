import UIKit

class HomeViewTableHandlers {
    private let utilities: HomeViewUtilities
    
    init(utilities: HomeViewUtilities) {
        self.utilities = utilities
    }
    
    func tableView(_ tableView: UITableView, 
                  performDropWith coordinator: UITableViewDropCoordinator, 
                  fileList: inout [File],
                  documentsDirectory: URL,
                  loadFiles: @escaping () -> Void) {
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
        
        // Copy the needed values before entering the closure
        let sourceFile = fileList[sourceIndex]
        
        DispatchQueue.global(qos: .userInitiated).async {
            // Reorder the file list without moving files on disk
            DispatchQueue.main.async { [sourceFile, sourceIndex, destinationIndexPath] in
                fileList.remove(at: sourceIndex)
                fileList.insert(sourceFile, at: destinationIndexPath.row) // Insert File, not String
                tableView.moveRow(at: IndexPath(row: sourceIndex, section: 0), to: destinationIndexPath)
                HapticFeedbackGenerator.generateNotificationFeedback(type: .success)
                loadFiles() // Call loadFiles to refresh the file system if needed
            }
        }
    }
}