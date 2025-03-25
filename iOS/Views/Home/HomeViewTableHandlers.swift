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
        
        performFileReorder(tableView: tableView,
                         sourceIndex: sourceIndex,
                         destinationIndexPath: destinationIndexPath,
                         fileList: &fileList) {
            loadFiles()
        }
    }
    
    private func performFileReorder(tableView: UITableView,
                                  sourceIndex: Int,
                                  destinationIndexPath: IndexPath,
                                  fileList: inout [File],
                                  completion: @escaping () -> Void) {
        let sourceFile = fileList[sourceIndex]
        let sourceIndexPath = IndexPath(row: sourceIndex, section: 0)
        
        fileList.remove(at: sourceIndex)
        fileList.insert(sourceFile, at: destinationIndexPath.row)
        
        DispatchQueue.global(qos: .userInitiated).async {
            DispatchQueue.main.async {
                tableView.moveRow(at: sourceIndexPath, to: destinationIndexPath)
                HapticFeedbackGenerator.generateNotificationFeedback(type: .success)
                completion()
            }
        }
    }
}