import UIKit

extension HomeViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchController.isActive ? filteredFileList.count : fileList.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "FileCell", for: indexPath) as? FileTableViewCell else {
            return UITableViewCell()
        }
        let fileName = searchController.isActive ? filteredFileList[indexPath.row] : fileList[indexPath.row]
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        let file = File(url: fileURL)
        cell.configure(with: file)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let fileName = searchController.isActive ? filteredFileList[indexPath.row] : fileList[indexPath.row]
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        showFileOptions(for: fileURL)
    }
}

extension HomeViewController: UITableViewDragDelegate {
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        let fileName = searchController.isActive ? filteredFileList[indexPath.row] : fileList[indexPath.row]
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        let itemProvider = NSItemProvider(contentsOf: fileURL)
        let dragItem = UIDragItem(itemProvider: itemProvider)
        dragItem.localObject = fileName
        return [dragItem]
    }

    func tableView(_ tableView: UITableView, canHandle session: UIDropSession) -> Bool {
        return session.canLoadObjects(ofClass: URL.self)
    }
}

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
            dropItem.itemProvider.loadObject(ofClass: URL.self) { [weak self] (object, error) in
                guard let self = self, let url = object as? URL else {
                    if let error = error {
                        print("Drop error: \(error)")
                    }
                    return
                }
                let destinationURL = self.documentsDirectory.appendingPathComponent(url.lastPathComponent)
                do {
                    try FileManager.default.moveItem(at: url, to: destinationURL)
                    DispatchQueue.main.async {
                        self.loadFiles()
                        HapticFeedbackGenerator.generateNotificationFeedback(type: .success)
                    }
                } catch {
                    print("Error dropping file: \(error)")
                    self.utilities.handleError(in: self, error: error, withTitle: "Drop Error")
                }
            }
        }
    }
}