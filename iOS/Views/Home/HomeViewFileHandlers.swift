import UIKit
import ZIPFoundation

extension HomeViewController {

    @objc private func uploadFile() {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.data], asCopy: true)
        documentPicker.delegate = self
        documentPicker.modalPresentationStyle = .formSheet
        present(documentPicker, animated: true, completion: nil)
    }

    private func importFile() {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.data], asCopy: true)
        documentPicker.delegate = self
        documentPicker.modalPresentationStyle = .formSheet
        present(documentPicker, animated: true, completion: nil)
    }
    
    private func createNewFolder() {
        showInputAlert(title: "New Folder", message: "Enter folder name", actionTitle: "Create") { folderName in
            let folderURL = self.documentsDirectory.appendingPathComponent(folderName)
            do {
                try self.fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)
                self.loadFiles()
            } catch {
                self.handleError(error, withTitle: "Creating Folder")
            }
        }
    }
    
    private func createNewFile() {
        showInputAlert(title: "New File", message: "Enter file name", actionTitle: "Create") { fileName in
            let fileURL = self.documentsDirectory.appendingPathComponent(fileName)
            self.fileManager.createFile(atPath: fileURL.path, contents: nil, attributes: nil)
            self.loadFiles()
        }
    }

    private func renameFile(at fileURL: URL) {
        showInputAlert(title: "Rename File", message: "Enter new file name", actionTitle: "Rename", initialText: fileURL.lastPathComponent) { newName in
            let destinationURL = fileURL.deletingLastPathComponent().appendingPathComponent(newName)
            self.activityIndicator.startAnimating()
            DispatchQueue.global().async {
                do {
                    try self.fileManager.moveItem(at: fileURL, to: destinationURL)
                    DispatchQueue.main.async {
                        self.activityIndicator.stopAnimating()
                        self.loadFiles()
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.activityIndicator.stopAnimating()
                        self.handleError(error, withTitle: "Renaming File")
                    }
                }
            }
        }
    }
    
    private func deleteFile(at fileURL: URL) {
        activityIndicator.startAnimating()
        DispatchQueue.global().async {
            do {
                try self.fileManager.removeItem(at: fileURL)
                DispatchQueue.main.async {
                    self.activityIndicator.stopAnimating()
                    self.loadFiles()
                }
            } catch {
                DispatchQueue.main.async {
                    self.activityIndicator.stopAnimating()
                    self.handleError(error, withTitle: "Deleting File")
                }
            }
        }
    }

    private func unzipFile(at fileURL: URL) {
        let destinationURL = fileURL.deletingLastPathComponent().appendingPathComponent("extracted")
        activityIndicator.startAnimating()
        DispatchQueue.global().async {
            do {
                try self.fileManager.unzipItem(at: fileURL, to: destinationURL)
                DispatchQueue.main.async {
                    self.activityIndicator.stopAnimating()
                    self.loadFiles()
                }
            } catch {
                DispatchQueue.main.async {
                    self.activityIndicator.stopAnimating()
                    self.handleError(error, withTitle: "Unzipping File")
                }
            }
        }
    }
    
    private func shareFile(at fileURL: URL) {
        let activityController = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
        present(activityController, animated: true, completion: nil)
    }
}