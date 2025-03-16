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
    
    static func compressFile(at fileURL: URL, to destinationURL: URL) throws {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            throw FileOperationError.fileNotFound("File not found at \(fileURL.path)")
        }
        do {
            let archive = try Archive(url: destinationURL, accessMode: .create)
            try archive.addEntry(with: fileURL.lastPathComponent, relativeTo: fileURL.deletingLastPathComponent())
            print("File compressed from \(fileURL.path) to \(destinationURL.path)")
        } catch {
            throw FileOperationError.unknownError("Failed to compress file: \(error.localizedDescription)")
        }
    }
    
    static func renameFile(at sourceURL: URL, to newName: String) throws {
        guard fileManager.fileExists(atPath: sourceURL.path) else {
            throw FileOperationError.fileNotFound("Source file not found at \(sourceURL.path)")
        }
        let destinationURL = sourceURL.deletingLastPathComponent().appendingPathComponent(newName)
        do {
            try fileManager.moveItem(at: sourceURL, to: destinationURL)
            print("File renamed from \(sourceURL.path) to \(destinationURL.path)")
        } catch {
            throw FileOperationError.unknownError("Failed to rename file: \(error.localizedDescription)")
        }
    }
    
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
    
    static func unzipFile(at fileURL: URL, to destinationURL: URL) throws {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            throw FileOperationError.fileNotFound("File not found at \(fileURL.path)")
        }
        do {
            let archive = try Archive(url: fileURL, accessMode: .read)
            for entry in archive {
                let destination = destinationURL.appendingPathComponent(entry.path)
                if entry.type == .directory {
                    try fileManager.createDirectory(at: destination, withIntermediateDirectories: true, attributes: nil)
                } else {
                    _ = try archive.extract(entry, to: destination)
                }
            }
            print("File unzipped from \(fileURL.path) to \(destinationURL.path)")
        } catch {
            throw FileOperationError.unknownError("Failed to unzip file: \(error.localizedDescription)")
        }
    }
    
    static func hexEditFile(at fileURL: URL, in viewController: UIViewController) {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            print("File not found at \(fileURL.path)")
            return
        }
        
        let hexEditorViewController = HexEditorViewController(fileURL: fileURL)
        viewController.present(hexEditorViewController, animated: true, completion: nil)
    }
}