import Foundation
import ZIPFoundation
import UIKit

enum FileOperationError: Error {
    case fileNotFound(String)
    case invalidDestination(String)
    case unknownError(String)
}

class FileOperations {

    static let fileManager = FileManager.default

    /// Copies a file from a source URL to a destination URL.
    ///
    /// - Parameters:
    ///   - sourceURL: The URL of the file to copy.
    ///   - destinationURL: The URL to copy the file to.
    /// - Throws: An error if the file does not exist or if the copy operation fails.
    static func copyFile(at sourceURL: URL, to destinationURL: URL) throws {
        guard fileManager.fileExists(atPath: sourceURL.path) else {
            throw FileOperationError.fileNotFound("Source file not found at \(sourceURL.path)")
        }
        do {
            try fileManager.copyItem(at: sourceURL, to: destinationURL)
            print("File copied from \(sourceURL.path) to \(destinationURL.path)")
        } catch {
            throw FileOperationError.unknownError("Failed to copy file: \(error.localizedDescription)")
        }
    }

    /// Moves a file from a source URL to a destination URL.
    ///
    /// - Parameters:
    ///   - sourceURL: The URL of the file to move.
    ///   - destinationURL: The URL to move the file to.
    /// - Throws: An error if the file does not exist or if the move operation fails.
    static func moveFile(at sourceURL: URL, to destinationURL: URL) throws {
        guard fileManager.fileExists(atPath: sourceURL.path) else {
            throw FileOperationError.fileNotFound("Source file not found at \(sourceURL.path)")
        }
        do {
            try fileManager.moveItem(at: sourceURL, to: destinationURL)
            print("File moved from \(sourceURL.path) to \(destinationURL.path)")
        } catch {
            throw FileOperationError.unknownError("Failed to move file: \(error.localizedDescription)")
        }
    }

    /// Deletes a file at the specified URL.
    ///
    /// - Parameter fileURL: The URL of the file to delete.
    /// - Throws: An error if the file does not exist or if the deletion fails.
    static func deleteFile(at fileURL: URL) throws {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            throw FileOperationError.fileNotFound("File not found at \(fileURL.path)")
        }
        do {
            try fileManager.removeItem(at: fileURL)
            print("File deleted at \(fileURL.path)")
        } catch {
            throw FileOperationError.unknownError("Failed to delete file: \(error.localizedDescription)")
        }
    }

    /// Renames a file at the source URL to a new name at the destination URL.
    ///
    /// - Parameters:
    ///   - sourceURL: The current URL of the file.
    ///   - destinationURL: The new URL for the file.
    /// - Throws: An error if the file does not exist or if the renaming fails.
    static func renameFile(at sourceURL: URL, to destinationURL: URL) throws {
        guard fileManager.fileExists(atPath: sourceURL.path) else {
            throw FileOperationError.fileNotFound("File not found at \(sourceURL.path)")
        }
        do {
            try fileManager.moveItem(at: sourceURL, to: destinationURL)
            print("File renamed from \(sourceURL.path) to \(destinationURL.path)")
        } catch {
            throw FileOperationError.unknownError("Failed to rename file: \(error.localizedDescription)")
        }
    }

    /// Creates a new directory at the specified URL.
    ///
    /// - Parameter directoryURL: The URL where the new directory should be created.
    /// - Throws: An error if the directory creation fails.
    static func createDirectory(at directoryURL: URL) throws {
        do {
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
            print("Directory created at \(directoryURL.path)")
        } catch {
            throw FileOperationError.unknownError("Failed to create directory: \(error.localizedDescription)")
        }
    }

    /// Checks if a file exists at the given path.
    ///
    /// - Parameter path: The path to check for file existence.
    /// - Returns: `true` if a file exists at the path, `false` otherwise.
    static func fileExists(at path: String) -> Bool {
        return fileManager.fileExists(atPath: path)
    }

    /// Gets the size of the file at the given URL.
    ///
    /// - Parameter fileURL: The URL of the file.
    /// - Returns: The size of the file in bytes, or nil if an error occurs.
    static func fileSize(at fileURL: URL) -> UInt64? {
        do {
            let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
            return attributes[.size] as? UInt64
        } catch {
            print("Error getting file size: \(error.localizedDescription)")
            return nil
        }
    }

    /// Gets the creation date of the file at the given URL.
    ///
    /// - Parameter fileURL: The URL of the file.
    /// - Returns: The creation date of the file, or nil if an error occurs.
    static func creationDate(at fileURL: URL) -> Date? {
        do {
            let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
            return attributes[.creationDate] as? Date
        } catch {
            print("Error getting creation date: \(error.localizedDescription)")
            return nil
        }
    }

    /// Unzips a file from a source URL to a destination URL.
    ///
    /// - Parameters:
    ///   - sourceURL: The URL of the ZIP file to unzip.
    ///   - destinationURL: The URL to unzip the contents to.
    /// - Throws: An error if the file does not exist or if the unzipping fails.
    static func unzipFile(at sourceURL: URL, to destinationURL: URL) throws {
        guard fileManager.fileExists(atPath: sourceURL.path) else {
            throw FileOperationError.fileNotFound("File not found at \(sourceURL.path)")
        }
        do {
            try Archive.extractAll(from: sourceURL, to: destinationURL)
            print("File unzipped from \(sourceURL.path) to \(destinationURL.path)")
        } catch {
            throw FileOperationError.unknownError("Failed to unzip file: \(error.localizedDescription)")
        }
    }

    /// Presents a Hex Editor View Controller for editing the file.
    ///
    /// - Parameters:
    ///   - fileURL: The URL of the file to be edited.
    ///   - viewController: The view controller to present the Hex Editor from.
    static func hexEditFile(at fileURL: URL, in viewController: UIViewController) {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            print("File not found at \(fileURL.path)")
            return
        }

        let hexEditorViewController = HexEditorViewController(fileURL: fileURL)
        viewController.present(hexEditorViewController, animated: true, completion: nil)
    }
}
