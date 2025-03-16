import UIKit
import ZIPFoundation

class HomeViewFileHandlers {
    private let fileManager = FileManager.default
    private let utilities = HomeViewUtilities()

    func uploadFile(viewController: UIViewController) {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.data], asCopy: true)
        documentPicker.delegate = viewController as? UIDocumentPickerDelegate
        documentPicker.modalPresentationStyle = .formSheet
        viewController.present(documentPicker, animated: true, completion: nil)
    }

    func importFile(viewController: UIViewController) {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.data], asCopy: true)
        documentPicker.delegate = viewController as? UIDocumentPickerDelegate
        documentPicker.modalPresentationStyle = .formSheet
        viewController.present(documentPicker, animated: true, completion: nil)
    }

    func createNewFolder(viewController: HomeViewController, folderName: String) {
        let folderURL = viewController.documentsDirectory.appendingPathComponent(folderName)
        do {
            try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)
            viewController.loadFiles()
        } catch {
            utilities.handleError(in: viewController, error: error, withTitle: "Creating Folder")
        }
    }

    func createNewFile(viewController: HomeViewController, fileName: String) {
        let fileURL = viewController.documentsDirectory.appendingPathComponent(fileName)
        fileManager.createFile(atPath: fileURL.path, contents: nil, attributes: nil)
        viewController.loadFiles()
    }

    func renameFile(viewController: HomeViewController, fileURL: URL, newName: String) {
        let destinationURL = fileURL.deletingLastPathComponent().appendingPathComponent(newName)
        viewController.activityIndicator.startAnimating()
        DispatchQueue.global().async {
            do {
                try self.fileManager.moveItem(at: fileURL, to: destinationURL)
                DispatchQueue.main.async {
                    viewController.activityIndicator.stopAnimating()
                    viewController.loadFiles()
                }
            } catch {
                DispatchQueue.main.async {
                    viewController.activityIndicator.stopAnimating()
                    self.utilities.handleError(in: viewController, error: error, withTitle: "Renaming File")
                }
            }
        }
    }

    func deleteFile(viewController: HomeViewController, fileURL: URL) {
        viewController.activityIndicator.startAnimating()
        DispatchQueue.global().async {
            do {
                try self.fileManager.removeItem(at: fileURL)
                DispatchQueue.main.async {
                    viewController.activityIndicator.stopAnimating()
                    viewController.loadFiles()
                }
            } catch {
                DispatchQueue.main.async {
                    viewController.activityIndicator.stopAnimating()
                    self.utilities.handleError(in: viewController, error: error, withTitle: "Deleting File")
                }
            }
        }
    }

    func unzipFile(viewController: HomeViewController, fileURL: URL) {
        let destinationURL = fileURL.deletingLastPathComponent().appendingPathComponent("extracted")
        viewController.activityIndicator.startAnimating()
        DispatchQueue.global().async {
            do {
                try self.fileManager.unzipItem(at: fileURL, to: destinationURL)
                DispatchQueue.main.async {
                    viewController.activityIndicator.stopAnimating()
                    viewController.loadFiles()
                }
            } catch {
                DispatchQueue.main.async {
                    viewController.activityIndicator.stopAnimating()
                    self.utilities.handleError(in: viewController, error: error, withTitle: "Unzipping File")
                }
            }
        }
    }

    func shareFile(viewController: UIViewController, fileURL: URL) {
        let activityController = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
        viewController.present(activityController, animated: true, completion: nil)
    }
}