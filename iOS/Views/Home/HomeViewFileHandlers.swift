import UIKit
import ZIPFoundation
import os.log
import Foundation

protocol FileHandlingDelegate: AnyObject {
    var documentsDirectory: URL { get }
    var activityIndicator: UIActivityIndicatorView { get }
    func loadFiles()
    func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)?)
}

class HomeViewFileHandlers {
    private let fileManager = FileManager.default
    private let utilities = HomeViewUtilities()

    func uploadFile(viewController: FileHandlingDelegate) {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.data]) // Removed ", asCopy: true"
        documentPicker.delegate = viewController as? UIDocumentPickerDelegate
        documentPicker.modalPresentationStyle = .formSheet
        viewController.present(documentPicker, animated: true, completion: nil)
    }

    func importFile(viewController: FileHandlingDelegate) {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.data]) // Removed ", asCopy: true"
        documentPicker.delegate = viewController as? UIDocumentPickerDelegate
        documentPicker.modalPresentationStyle = .formSheet
        viewController.present(documentPicker, animated: true, completion: nil)
    }

    func createNewFolder(viewController: FileHandlingDelegate, folderName: String, completion: @escaping (Result<URL, Error>) -> Void) {
        let folderURL = viewController.documentsDirectory.appendingPathComponent(folderName)
        do {
            try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: false, attributes: nil)
            completion(.success(folderURL))
        } catch {
            completion(.failure(error))
        }
    }

    func createNewFile(viewController: FileHandlingDelegate, fileName: String, completion: @escaping (Result<URL, Error>) -> Void) {
        let fileURL = viewController.documentsDirectory.appendingPathComponent(fileName)
        let fileContent = "" // Or any default content you want
        do {
            try fileContent.write(to: fileURL, atomically: true, encoding: .utf8)
            completion(.success(fileURL))
        } catch {
            completion(.failure(error))
        }
    }

    func unzipFile(viewController: FileHandlingDelegate, fileURL: URL, destinationName: String, progressHandler: ((Double) -> Void)? = nil, completion: @escaping (Result<URL, Error>) -> Void) {
        let destinationURL = fileURL.deletingLastPathComponent().appendingPathComponent(destinationName)
        viewController.activityIndicator.startAnimating()
        let workItem = DispatchWorkItem {
            do {
                let progress = Progress(totalUnitCount: 100)
                progress.cancellationHandler = {
                    print("Unzip cancelled")
                }
                try fileManager.unzipItem(at: fileURL, to: destinationURL, progress: progress)
                progressHandler?(1.0)
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
        DispatchQueue.global().async(execute: workItem)
    }

    func shareFile(viewController: UIViewController, fileURL: URL) {
        let activityController = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
        viewController.present(activityController, animated: true, completion: nil)
    }
}
