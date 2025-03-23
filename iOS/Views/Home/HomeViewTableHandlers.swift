import UIKit

// MARK: - UITableViewDelegate and UITableViewDataSource
extension HomeViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchController.isActive ? filteredFileList.count : fileList.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Safely dequeue the custom cell with a fallback for failure
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "FileCell", for: indexPath) as? FileTableViewCell else {
            fatalError("Unable to dequeue FileTableViewCell")
        }
        
        // Determine the file name based on search state
        let fileName = searchController.isActive ? filteredFileList[indexPath.row] : fileList[indexPath.row]
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        let file = File(url: fileURL)
        
        // Configure the cell with file data
        cell.configure(with: file)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Handle row selection to show file options
        let fileName = searchController.isActive ? filteredFileList[indexPath.row] : fileList[indexPath.row]
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        showFileOptions(for: fileURL)
    }
}

// MARK: - UITableViewDragDelegate
extension HomeViewController: UITableViewDragDelegate {
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        // Provide drag items for the file at the given index path
        let fileName = searchController.isActive ? filteredFileList[indexPath.row] : fileList[indexPath.row]
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        let itemProvider = NSItemProvider(contentsOf: fileURL)
        let dragItem = UIDragItem(itemProvider: itemProvider)
        dragItem.localObject = fileName // Useful for in-app drag-and-drop
        return [dragItem]
    }

    func tableView(_ tableView: UITableView, canHandle session: UIDropSession) -> Bool {
        // Check if the drop session can handle URL objects
        return session.canLoadObjects(ofClass: URL.self)
    }
}

// MARK: - UITableViewDropDelegate
extension HomeViewController: UITableViewDropDelegate {
    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
        // Determine the destination index path for the drop
        let destinationIndexPath: IndexPath
        if let indexPath = coordinator.destinationIndexPath {
            destinationIndexPath = indexPath
        } else {
            let section = tableView.numberOfSections - 1
            let row = tableView.numberOfRows(inSection: section)
            destinationIndexPath = IndexPath(row: row, section: section)
        }

        // Process each dropped item
        coordinator.items.forEach { dropItem in
            dropItem.itemProvider.loadObject(ofClass: URL.self) { [weak self] (object, error) in
                guard let self = self else { return }
                
                if let url = object as? URL {
                    let destinationURL = self.documentsDirectory.appendingPathComponent(url.lastPathComponent)
                    do {
                        // Move the dropped file to the documents directory
                        try self.fileManager.moveItem(at: url, to: destinationURL)
                        DispatchQueue.main.async {
                            self.loadFiles() // Refresh the file list
                        }
                    } catch {
                        // Log the error and show an alert to the user
                        print("Error dropping file: \(error)")
                        DispatchQueue.main.async {
                            let alert = UIAlertController(
                                title: "Error",
                                message: "Failed to move file: \(error.localizedDescription)",
                                preferredStyle: .alert
                            )
                            alert.addAction(UIAlertAction(title: "OK", style: .default))
                            self.present(alert, animated: true)
                        }
                    }
                }
            }
        }
    }
}