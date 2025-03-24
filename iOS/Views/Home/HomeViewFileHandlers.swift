import UIKit
import ZIPFoundation
import os.log

protocol FileHandlingDelegate: AnyObject {
    var documentsDirectory: URL { get }
    var activityIndicator: UIActivityIndicatorView { get }
    func loadFiles()
    func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)?)
}

class HomeViewFileHandlers {
    private let fileManager = FileManager.default
    private let utilities = HomeViewUtilities()
    private let logger = Logger(subsystem: "com.example.FileNexus", category: "FileHandlers")
    
    func uploadFile(viewController: FileHandlingDelegate) {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.data, .archive, .text])
        documentPicker.delegate = viewController as? UIDocumentPickerDelegate
        documentPicker.modalPresentationStyle = .formSheet
        viewController.present(documentPicker, animated: true, completion: nil)
    }
    
    func importFile(viewController: FileHandlingDelegate) {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.data, .archive, .text])
        documentPicker.delegate = viewController as? UIDocumentPickerDelegate
        documentPicker.modalPresentationStyle = .formSheet
        viewController.present(documentPicker, animated: true, completion: nil)
    }
    
    func createNewFolder(viewController: FileHandlingDelegate, folderName: String, completion: @escaping (Result<URL, Error>) -> Void) {
        let folderURL = viewController.documentsDirectory.appendingPathComponent(folderName)
        do {
            try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: false, attributes: nil)
            HapticFeedbackGenerator.generateNotificationFeedback(type: .success)
            completion(.success(folderURL))
        } catch {
            logger.error("Failed to create folder: \(error.localizedDescription)")
            completion(.failure(error))
        }
    }
    
    func createNewFile(viewController: FileHandlingDelegate, fileName: String, completion: @escaping (Result<URL, Error>) -> Void) {
        let fileURL = viewController.documentsDirectory.appendingPathComponent(fileName)
        let fileContent = ""
        do {
            try fileContent.write(to: fileURL, atomically: true, encoding: .utf8)
            HapticFeedbackGenerator.generateNotificationFeedback(type: .success)
            completion(.success(fileURL))
        } catch {
            logger.error("Failed to create file: \(error.localizedDescription)")
            completion(.failure(error))
        }
    }
    
    func unzipFile(viewController: FileHandlingDelegate, fileURL: URL, destinationName: String, progressHandler: ((Double) -> Void)? = nil, completion: @escaping (Result<URL, Error>) -> Void) {
        let destinationURL = fileURL.deletingLastPathComponent().appendingPathComponent(destinationName)
        viewController.activityIndicator.startAnimating()
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async {
                    viewController.activityIndicator.stopAnimating()
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Self deallocated during unzip"])))
                }
                return
            }
            do {
                let progress = Progress(totalUnitCount: 100)
                progress.cancellationHandler = { self.logger.info("Unzip cancelled") }
                try self.fileManager.unzipItem(at: fileURL, to: destinationURL, progress: progress)
                progressHandler?(1.0)
                DispatchQueue.main.async {
                    viewController.activityIndicator.stopAnimating()
                    viewController.loadFiles()
                    HapticFeedbackGenerator.generateNotificationFeedback(type: .success)
                    completion(.success(destinationURL))
                }
            } catch {
                DispatchQueue.main.async {
                    viewController.activityIndicator.stopAnimating()
                    self.utilities.handleError(in: viewController as! UIViewController, error: error, withTitle: "Unzipping Error")
                    completion(.failure(error))
                }
            }
        }
        DispatchQueue.global(qos: .userInitiated).async(execute: workItem)
    }
    
    func shareFile(viewController: UIViewController, fileURL: URL) {
        let activityController = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
        activityController.popoverPresentationController?.sourceView = viewController.view
        viewController.present(activityController, animated: true, completion: nil)
    }
}