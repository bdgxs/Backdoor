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

    func uploadFile(viewController: FileHandlingDelegate) {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.data], asCopy: true)
        documentPicker.delegate = viewController as? UIDocumentPickerDelegate
        documentPicker.modalPresentationStyle = .formSheet
        viewController.present(documentPicker, animated: true, completion: nil)
    }

    func importFile(viewController: FileHandlingDelegate) {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.data], asCopy: true)
        documentPicker.delegate = viewController as? UIDocumentPickerDelegate
        documentPicker.modalPresentationStyle = .formSheet
        viewController.present(documentPicker, animated: true, completion: nil)
    }

    func createNewFolder(viewController: FileHandlingDelegate, folderName: String, completion: @escaping (Result<URL, Error>) -> Void) {
        let folderURL = viewController.documentsDirectory.appendingPathComponent(folderName)
        do {
            try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)
            viewController.loadFiles()
            completion(.success(folderURL))
        } catch {
            utilities.handleError(in: viewController as! UIViewController, error: error, withTitle: "Creating Folder")
            completion(.failure(error))
        }
    }

    func createNewFile(viewController: FileHandlingDelegate, fileName: String, completion: @escaping (Result<URL, Error>) -> Void) {
        let fileURL = viewController.documentsDirectory.appendingPathComponent(fileName)
        if !fileManager.fileExists(atPath: fileURL.path) {
            fileManager.createFile(atPath: fileURL.path, contents: nil, attributes: nil)
            viewController.loadFiles()
            completion(.success(fileURL))
        } else {
            let error = NSError(domain: "FileExists", code: 1, userInfo: [NSLocalizedDescriptionKey: "File already exists"])
            utilities.handleError(in: viewController as! UIViewController, error: error, withTitle: "Creating File")
            completion(.failure(error))
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

    // Process Execution Helper
    private func executeProcess(executableURL: URL, arguments: [String]) throws -> String {
        let task = Process()
        task.executableURL = executableURL
        task.arguments = arguments

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe

        try task.run()
        task.waitUntilExit()

        if task.terminationStatus == 0 {
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                return output
            } else {
                throw NSError(domain: "Process", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to decode output"])
            }
        } else {
            let errorData = task.standardError.fileHandleForReading.readDataToEndOfFile()
            if let errorString = String(data: errorData, encoding: .utf8) {
                throw NSError(domain: "Process", code: Int(task.terminationStatus), userInfo: [NSLocalizedDescriptionKey: "Process failed: \(errorString)"])
            } else {
                throw NSError(domain: "Process", code: Int(task.terminationStatus), userInfo: [NSLocalizedDescriptionKey: "Process failed with unknown error"])
            }
        }
    }

    func listDylibs(filePath: String, completion: @escaping (Result<[String], Error>) -> Void) {
        let otoolURL = URL(fileURLWithPath: "/usr/bin/otool")
        let arguments = ["-L", filePath]
        DispatchQueue.global().async {
            do {
                let output = try self.executeProcess(executableURL: otoolURL, arguments: arguments)
                let lines = output.components(separatedBy: .newlines)
                let dylibs = lines.filter { $0.hasPrefix("\t") }.compactMap { line in
                    line.components(separatedBy: "(").first?.trimmingCharacters(in: .whitespaces)
                }
                DispatchQueue.main.async { completion(.success(dylibs)) }
            } catch {
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }
    }

    func listDylibsFromApp(filePath: String, completion: @escaping (Result<[String], Error>) -> Void) {
        listDylibs(filePath: filePath, completion: completion)
    }

    // Add other functions here, using executeProcess and DispatchQueue.global().async for stability.
}

class HomeViewUtilities {
    func handleError(in viewController: UIViewController, error: Error, withTitle title: String) {
        let alert = UIAlertController(title: title, message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        viewController.present(alert, animated: true, completion: nil)
    }
}