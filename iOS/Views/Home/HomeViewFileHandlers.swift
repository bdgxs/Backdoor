import UIKit
import ZIPFoundation

class HomeViewFileHandlers {
    private let fileManager = FileManager.default
    private let utilities = HomeViewUtilities()

    // Existing functions...

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

    // New functions

    func listDylibs(filePath: String) throws -> [String]? {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/otool")
        task.arguments = ["-L", filePath]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe() // Capture standard error too

        try task.run()
        task.waitUntilExit()

        if task.terminationStatus == 0 {
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                let lines = output.components(separatedBy: .newlines)
                var dylibs: [String] = []

                for line in lines {
                    let trimmedLine = line.trimmingCharacters(in: .whitespaces)
                    if trimmedLine.hasPrefix("\t") {
                        if let dylib = trimmedLine.components(separatedBy: "(").first?.trimmingCharacters(in: .whitespaces) {
                            dylibs.append(dylib)
                        }
                    }
                }
                return dylibs
            }
        } else {
            let errorData = task.standardError as! Pipe
            let errorString = String(data: errorData.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)
            print("otool error: \(errorString ?? "Unknown error")")
            throw NSError(domain: "otool", code: Int(task.terminationStatus), userInfo: [NSLocalizedDescriptionKey: "otool failed with status \(task.terminationStatus)"])
        }
        return nil
    }

    func fetchSources() {
        sources = CoreDataManager.shared.getAZSources()
        searchResultsTableViewController.sources = sources
        DispatchQueue.main.async {
            self.tableView.reloadSections(IndexSet(integer: 1), with: .automatic)
        }
    }

    func uninstallDylibs(filePath: String, dylibPaths: [String]) throws {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/otool")
        task.arguments = ["-L", filePath]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe() // Capture standard error too

        try task.run()
        task.waitUntilExit()

        if task.terminationStatus == 0 {
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                let lines = output.components(separatedBy: .newlines)
                var dylibs: [String] = []

                for line in lines {
                    let trimmedLine = line.trimmingCharacters(in: .whitespaces)
                    if trimmedLine.hasPrefix("\t") {
                        if let dylib = trimmedLine.components(separatedBy: "(").first?.trimmingCharacters(in: .whitespaces) {
                            dylibs.append(dylib)
                        }
                    }
                }
                return dylibs
            }
        } else {
            let errorData = task.standardError as! Pipe
            let errorString = String(data: errorData.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)
            print("otool error: \(errorString ?? "Unknown error")")
            throw NSError(domain: "otool", code: Int(task.terminationStatus), userInfo: [NSLocalizedDescriptionKey: "otool failed with status \(task.terminationStatus)"])
        }
        return nil
    }

    func updatePlugIns(options: SigningOptions, app: URL) throws {
        let plugInsPath = app.appendingPathComponent("PlugIns")
        let plugIns = try fileManager.contentsOfDirectory(atPath: plugInsPath.path)
        
        for plugIn in plugIns {
            let plugInPath = plugInsPath.appendingPathComponent(plugIn)
            let infoPlistPath = plugInPath.appendingPathComponent("Info.plist")
            
            if fileManager.fileExists(atPath: infoPlistPath.path) {
                if let info = NSDictionary(contentsOf: infoPlistPath)?.mutableCopy() as? NSMutableDictionary {
                    try updateInfoPlist(infoDict: info, main: options.mainOptions, options: options, icon: options.mainOptions.iconURL, app: plugInPath)
                }
            }
            
            let handler = TweakHandler(urls: options.signingOptions.toInject, app: plugInPath)
            try handler.getInputFiles()
            
            if !options.mainOptions.removeInjectPaths.isEmpty {
                if let appexe = try? TweakHandler.findExecutable(at: plugInPath) {
                    _ = uninstallDylibs(filePath: appexe.path, dylibPaths: options.mainOptions.removeInjectPaths)
                }
            }
        }
    }

    func removeDumbAssPlaceHolderExtension(options: SigningOptions, app: URL) throws {
        let extensionsPath = app.appendingPathComponent("Extensions")
        let extensions = try fileManager.contentsOfDirectory(atPath: extensionsPath.path)
        
        for extensionItem in extensions {
            let extensionPath = extensionsPath.appendingPathComponent(extensionItem)
            
            if extensionPath.lastPathComponent == "DumbAssPlaceHolderExtension.appex" {
                try fileManager.removeItem(at: extensionPath)
            }
        }
    }

    func updateMobileProvision(app: URL) throws {
        let provisioningPath = app.appendingPathComponent("embedded.mobileprovision")
        
        if fileManager.fileExists(atPath: provisioningPath.path) {
            try fileManager.removeItem(at: provisioningPath)
        }
        
        let certPath = try CoreDataManager.shared.getCertifcatePath(source: mainOptions.mainOptions.certificate)
        let provisionPath = certPath.appendingPathComponent("\(mainOptions.mainOptions.certificate?.provisionPath ?? "")").path
        
        try fileManager.copyItem(atPath: provisionPath, toPath: provisioningPath.path)
    }

    func signAppWithZSign(tmpDirApp: URL, certPaths: (String, String), password: String, main: MainOptions, options: SigningOptions) throws {
        let zsignCmd = "/usr/local/bin/zsign"
        let args = [
            "-k", certPaths.1,
            "-m", certPaths.0,
            "-p", password,
            "-o", tmpDirApp.path,
            tmpDirApp.path
        ]
        
        let task = Process()
        task.executableURL = URL(fileURLWithPath: zsignCmd)
        task.arguments = args
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()
        
        try task.run()
        task.waitUntilExit()
        
        if task.terminationStatus != 0 {
            let errorData = task.standardError as! Pipe
            let errorString = String(data: errorData.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)
            print("zsign error: \(errorString ?? "Unknown error")")
            throw NSError(domain: "zsign", code: Int(task.terminationStatus), userInfo: [NSLocalizedDescriptionKey: "zsign failed with status \(task.terminationStatus)"])
        }
    }

    func changeDylib(oldPath: String, newPath: String, appPath: String) throws {
        let task = Process()
        task.launchPath = "/usr/bin/install_name_tool"
        task.arguments = ["-change", oldPath, newPath, appPath]
        
        try task.run()
        task.waitUntilExit()
        
        if task.terminationStatus != 0 {
            let errorData = task.standardError as! Pipe
            let errorString = String(data: errorData.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)
            print("install_name_tool error: \(errorString ?? "Unknown error")")
            throw NSError(domain: "install_name_tool", code: Int(task.terminationStatus), userInfo: [NSLocalizedDescriptionKey: "install_name_tool failed with status \(task.terminationStatus)"])
        }
    }

    func injectDylib(dylibPath: String, appPath: String) throws {
        let task = Process()
        task.launchPath = "/usr/bin/install_name_tool"
        task.arguments = ["-add_rpath", dylibPath, appPath]
        
        try task.run()
        task.waitUntilExit()
        
        if task.terminationStatus != 0 {
            let errorData = task.standardError as! Pipe
            let errorString = String(data: errorData.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)
            print("install_name_tool error: \(errorString ?? "Unknown error")")
            throw NSError(domain: "install_name_tool", code: Int(task.terminationStatus), userInfo: [NSLocalizedDescriptionKey: "install_name_tool failed with status \(task.terminationStatus)"])
        }
    }
}