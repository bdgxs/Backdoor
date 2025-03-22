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

    /// Compresses a file at a given URL to a destination URL using ZIPFoundation.
    ///
    /// - Parameters:
    ///   - fileURL: The URL of the file to compress.
    ///   - destinationURL: The URL where the ZIP archive should be created.
    /// - Throws: An error if the compression fails.
    static func compressFile(at fileURL: URL, to destinationURL: URL) throws {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            throw FileOperationError.fileNotFound("File not found at \(fileURL.path)")
        }
        do {
            try fileManager.zipItem(at: fileURL, to: destinationURL)
            print("File compressed from \(fileURL.path) to \(destinationURL.path)")
        } catch {
            throw FileOperationError.unknownError("Failed to compress file: \(error.localizedDescription)")
        }
    }

    /// Decompresses a ZIP archive at a given URL to a destination URL using ZIPFoundation.
    ///
    /// - Parameters:
    ///   - fileURL: The URL of the ZIP archive to decompress.
    ///   - destinationURL: The URL where the contents of the archive should be extracted.
    /// - Throws: An error if the archive does not exist or if the decompression fails.
    static func decompressFile(at fileURL: URL, to destinationURL: URL) throws {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            throw FileOperationError.fileNotFound("Archive not found at \(fileURL.path)")
        }
        do {
            try fileManager.unzipItem(at: fileURL, to: destinationURL)
            print("Archive unzipped from \(fileURL.path) to \(destinationURL.path)")
        } catch {
            throw FileOperationError.unknownError("Failed to unzip archive: \(error.localizedDescription)")
        }
    }

    /// Deletes a file at a given URL.
    ///
    /// - Parameters:
    ///   - fileURL: The URL of the file to delete.
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

    /// Reads the content of a text file at a given URL.
    ///
    /// - Parameters:
    ///   - fileURL: The URL of the text file.
    /// - Returns: The content of the file as a String.
    /// - Throws: An error if the file does not exist or if the reading fails.
    static func readTextFile(at fileURL: URL) throws -> String {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            throw FileOperationError.fileNotFound("File not found at \(fileURL.path)")
        }
        do {
            let content = try String(contentsOf: fileURL, encoding: .utf8)
            return content
        } catch {
            throw FileOperationError.unknownError("Failed to read text file: \(error.localizedDescription)")
        }
    }

    /// Writes content to a text file at a given URL.
    ///
    /// - Parameters:
    ///   - content: The content to write to the file.
    ///   - fileURL: The URL of the text file.
    /// - Throws: An error if the writing fails.
    static func writeTextFile(content: String, to fileURL: URL) throws {
        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            print("Content written to file at \(fileURL.path)")
        } catch {
            throw FileOperationError.unknownError("Failed to write to text file: \(error.localizedDescription)")
        }
    }

    /// Reads the content of a plist file at a given URL.
    ///
    /// - Parameters:
    ///   - fileURL: The URL of the plist file.
    /// - Returns: The content of the file as an Any.
    /// - Throws: An error if the file does not exist or if the reading fails.
    static func readPlistFile(at fileURL: URL) throws -> Any {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            throw FileOperationError.fileNotFound("File not found at \(fileURL.path)")
        }
        do {
            let data = try Data(contentsOf: fileURL)
            let plist = try PropertyListSerialization.propertyList(from: data, options:, format: nil)
            return plist
        } catch {
            throw FileOperationError.unknownError("Failed to read plist file: \(error.localizedDescription)")
        }
    }

    /// Writes content to a plist file at a given URL.
    ///
    /// - Parameters:
    ///   - plist: The content to write to the file as an Any.
    ///   - fileURL: The URL of the plist file.
    /// - Throws: An error if the writing fails.
    static func writePlistFile(plist: Any, to fileURL: URL) throws {
        do {
            let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
            try data.write(to: fileURL)
            print("Content written to plist file at \(fileURL.path)")
        } catch {
            throw FileOperationError.unknownError("Failed to write to plist file: \(error.localizedDescription)")
        }
    }

    /// Reads the content of a file as hexadecimal data.
    ///
    /// - Parameters:
    ///   - fileURL: The URL of the file.
    /// - Returns: The content of the file as a String of hexadecimal values.
    /// - Throws: An error if the file does not exist or if the reading fails.
    static func readHexFile(at fileURL: URL) throws -> String {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            throw FileOperationError.fileNotFound("File not found at \(fileURL.path)")
        }
        do {
            let data = try Data(contentsOf: fileURL)
            return data.map { String(format: "%02hhX", $0) }.joined()
        } catch {
            throw FileOperationError.unknownError("Failed to read file as hex: \(error.localizedDescription)")
        }
    }

    /// Writes hexadecimal data to a file.
    ///
    /// - Parameters:
    ///   - hexString: The hexadecimal data to write.
    ///   - fileURL: The URL of the file.
    /// - Throws: An error if the writing fails.
    static func writeHexFile(hexString: String, to fileURL: URL) throws {
        var data = Data()
        var i = hexString.startIndex
        while i < hexString.endIndex {
            let nextIndex = hexString.index(i, offsetBy: 2, limitedBy: hexString.endIndex) ?? hexString.endIndex
            let byteString = String(hexString[i..<nextIndex])
            if let byte = UInt8(byteString, radix: 16) {
                data.append(byte)
            } else {
                throw FileOperationError.unknownError("Invalid hex string")
            }
            i = nextIndex
        }
        do {
            try data.write(to: fileURL)
            print("Hex data written to file at \(fileURL.path)")
        } catch {
            throw FileOperationError.unknownError("Failed to write hex data to file: \(error.localizedDescription)")
        }
    }

    /// Unzips a file at a given URL to a destination URL using ZIPFoundation.
    ///
    /// - Parameters:
    ///   - fileURL: The URL of the file to unzip.
    ///   - destinationURL: The URL where the contents of the file should be extracted.
    /// - Throws: An error if the file does not exist or if the unzipping fails.
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
