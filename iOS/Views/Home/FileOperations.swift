import Foundation
import ZIPFoundation

class FileOperations {
    
    static let fileManager = FileManager.default
    
    static func copyFile(at sourceURL: URL, to destinationURL: URL) throws {
        try fileManager.copyItem(at: sourceURL, to: destinationURL)
    }
    
    static func moveFile(at sourceURL: URL, to destinationURL: URL) throws {
        try fileManager.moveItem(at: sourceURL, to: destinationURL)
    }
    
    static func compressFile(at fileURL: URL, to destinationURL: URL) throws {
        let archive = try Archive(url: destinationURL, accessMode: .create)
        try archive.addEntry(with: fileURL.lastPathComponent, relativeTo: fileURL.deletingLastPathComponent())
    }
    
    static func renameFile(at sourceURL: URL, to newName: String) throws {
        let destinationURL = sourceURL.deletingLastPathComponent().appendingPathComponent(newName)
        try fileManager.moveItem(at: sourceURL, to: destinationURL)
    }
    
    static func deleteFile(at fileURL: URL) throws {
        try fileManager.removeItem(at: fileURL)
    }
    
    static func unzipFile(at fileURL: URL, to destinationURL: URL) throws {
        let archive = try Archive(url: fileURL, accessMode: .read)
        for entry in archive {
            let destination = destinationURL.appendingPathComponent(entry.path)
            if entry.type == .directory {
                try fileManager.createDirectory(at: destination, withIntermediateDirectories: true, attributes: nil)
            } else {
                try archive.extract(entry, to: destination)
            }
        }
    }
    
    static func hexEditFile(at fileURL: URL) {
        // Implement hex edit functionality
    }
}