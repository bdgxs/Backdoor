import UIKit

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
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.data, .archive, .text])
        documentPicker.delegate = viewController as? UIDocumentPickerDelegate
        documentPicker.modalPresentationStyle = .formSheet
        viewController.present(documentPicker, animated: true, completion: nil) // Added completion: nil
    }
    
    func importFile(viewController: FileHandlingDelegate) {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.data, .archive, .text])
        documentPicker.delegate = viewController as? UIDocumentPickerDelegate
        documentPicker.modalPresentationStyle = .formSheet
        viewController.present(documentPicker, animated: true, completion: nil) // Added completion: nil
    }
    
    func createNewFolder(viewController: FileHandlingDelegate, folderName: String, completion: @escaping (Result<URL, Error>) -> Void) {
        let folderURL = viewController.documentsDirectory.appendingPathComponent(folderName)
        do {
            try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: false, attributes: nil)
            HapticFeedbackGenerator.generateNotificationFeedback(type: .success)
            completion(.success(folderURL))
        } catch {
            Debug.shared.log(message: "Failed to create folder: \(error.localizedDescription)", type: .error)
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
            Debug.shared.log(message: "Failed to create file: \(error.localizedDescription)", type: .error)
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
                progress.cancellationHandler = { Debug.shared.log(message: "Unzip cancelled", type: .info) }
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
                    Debug.shared.log(message: "Failed to unzip file: \(error.localizedDescription)", type: .error)
                    completion(.failure(error))
                }
            }
        }
        DispatchQueue.global(qos: .userInitiated).async(execute: workItem)
    }
}