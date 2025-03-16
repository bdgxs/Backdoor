import UIKit
import ZIPFoundation

protocol FileHandlingDelegate: AnyObject {
    var documentsDirectory: URL { get }
    var activityIndicator: UIActivityIndicatorView { get }
    func loadFiles()
    func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)?)
}

class HomeViewFileHandlers {
    private let fileManager = FileManager.default
    private let utilities = HomeViewUtilities()

    func uploadFile(viewController: UIViewController & FileHandlingDelegate) {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.data], asCopy: true)
        documentPicker.delegate = viewController as? UIDocumentPickerDelegate
        documentPicker.modalPresentationStyle = .formSheet
        viewController.present(documentPicker, animated: true, completion: nil)
    }

    func importFile(viewController: UIViewController & FileHandlingDelegate) {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.data], asCopy: true)
        documentPicker.delegate = viewController as? UIDocumentPickerDelegate
        documentPicker.modalPresentationStyle = .formSheet
        viewController.present(documentPicker, animated: true, completion: nil)
    }

    func createNewFolder(viewController: FileHandlingDelegate, folderName: String) {
        let folderURL = viewController.documentsDirectory.appendingPathComponent(folderName)
        do {
            try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)
            viewController.loadFiles()
        } catch {
            utilities.handleError(in: viewController as! UIViewController, error: error, withTitle: "Creating Folder")
        }
    }

    func createNewFile(viewController: FileHandlingDelegate, fileName: String) {
        let fileURL = viewController.documentsDirectory.appendingPathComponent(fileName)
        if !fileManager.fileExists(atPath: fileURL.path) {
            fileManager.createFile(atPath: fileURL.path, contents: nil, attributes: nil)
            viewController.loadFiles()
        } else {
            utilities.handleError(in: viewController as! UIViewController, error: NSError(domain: "FileExists", code: 1, userInfo: [NSLocalizedDescriptionKey: "File already exists"]), withTitle: "Creating File")
        }
    }

    func renameFile(viewController: FileHandlingDelegate, fileURL: URL, newName: String, completion: @escaping (Result<URL, Error>) -> Void) {
        let destinationURL = fileURL.deletingLastPathComponent().appendingPathComponent(newName)
        viewController.activityIndicator.startAnimating()
        DispatchQueue.global().async {
            do {
                try self.fileManager.moveItem(at: fileURL, to: destinationURL)
                DispatchQueue.main.async {
                    viewController.activityIndicator.stopAnimating()
                    viewController.loadFiles()
                    completion(.success(destinationURL))
                }
            } catch {
                DispatchQueue.main.async {
                    viewController.activityIndicator.stopAnimating()
                    self.utilities.handleError(in: viewController as! UIViewController, error: error, withTitle: "Renaming File")
                    completion(.failure(error))
                }
            }
        }
    }

    func deleteFile(viewController: FileHandlingDelegate, fileURL: URL, completion: @escaping (Result<Void, Error>) -> Void) {
        viewController.activityIndicator.startAnimating()
        DispatchQueue.global().async {
            do {
                try self.fileManager.removeItem(at: fileURL)
                DispatchQueue.main.async {
                    viewController.activityIndicator.stopAnimating()
                    viewController.loadFiles()
                    completion(.success(()))
                }
            } catch {
                DispatchQueue.main.async {
                    viewController.activityIndicator.stopAnimating()
                    self.utilities.handleError(in: viewController as! UIViewController, error: error, withTitle: "Deleting File")
                    completion(.failure(error))
                }
            }
        }
    }

    func unzipFile(viewController: FileHandlingDelegate, fileURL: URL, destinationName: String, progressHandler: ((Double) -> Void)? = nil, completion: @escaping (Result<URL, Error>) -> Void) {
        let destinationURL = fileURL.deletingLastPathComponent().appendingPathComponent(destinationName)
        viewController.activityIndicator.startAnimating()
        DispatchQueue.global().async {
            do {
                try self.fileManager.unzipItem(at: fileURL, to: destinationURL, progress: progressHandler)
                DispatchQueue.main.async {
                    viewController.activityIndicator.stopAnimating()
                    viewController.loadFiles()
                    completion(.success(destinationURL))
                }
            } catch {
                DispatchQueue.main.async {
                    viewController.activityIndicator.stopAnimating()
                    self.utilities.handleError(in: viewController as! UIViewController, error: error, withTitle: "Unzipping File")
                    completion(.failure(error))
                }
            }
        }
    }

    func shareFile(viewController: UIViewController, fileURL: URL) {
        let activityController = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
        viewController.present(activityController, animated: true, completion: nil)
    }
}

class HomeViewUtilities {
    func handleError(in viewController: UIViewController, error: Error, withTitle title: String) {
        let alert = UIAlertController(title: title, message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        viewController.present(alert, animated: true, completion: nil)
    }
}