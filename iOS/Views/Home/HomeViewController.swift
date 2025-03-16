import UIKit
import ZIPFoundation

class HomeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIDocumentPickerDelegate {
    
    // MARK: - Properties
    private var fileList: [String] = []
    private let fileManager = FileManager.default
    private var documentsDirectory: URL {
        return fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    }

    // MARK: - UI Elements
    private let navigationBar: UINavigationBar = {
        let navBar = UINavigationBar()
        navBar.translatesAutoresizingMaskIntoConstraints = false
        navBar.barTintColor = .systemBlue // Change this to match your app's theme
        navBar.titleTextAttributes = [.foregroundColor: UIColor.white]
        return navBar
    }()
    
    private let fileListTableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadFiles()
        fileListTableView.delegate = self
        fileListTableView.dataSource = self
    }

    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .white
        
        // Setup Navigation Bar
        let navItem = UINavigationItem(title: "Files")
        let menuButton = UIBarButtonItem(title: "⋮", style: .plain, target: self, action: #selector(showMenu))
        navItem.rightBarButtonItem = menuButton
        navigationBar.setItems([navItem], animated: false)
        
        // Add UI elements to the view
        view.addSubview(navigationBar)
        view.addSubview(fileListTableView)
        
        // Set up constraints
        NSLayoutConstraint.activate([
            navigationBar.topAnchor.constraint(equalTo: view.topAnchor), // Changed to view.topAnchor
            navigationBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navigationBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            fileListTableView.topAnchor.constraint(equalTo: navigationBar.bottomAnchor),
            fileListTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            fileListTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            fileListTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Register the table view cell
        fileListTableView.register(UITableViewCell.self, forCellReuseIdentifier: "FileCell")
        
        // Add long press gesture recognizer to table view
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        fileListTableView.addGestureRecognizer(longPressRecognizer)
    }

    // MARK: - Load Files
    private func loadFiles() {
        do {
            fileList = try fileManager.contentsOfDirectory(atPath: documentsDirectory.path)
            fileListTableView.reloadData()
        } catch {
            print("Failed to load files: \(error)")
        }
    }

    // MARK: - Actions
    @objc private func showMenu() {
        let menu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        menu.addAction(UIAlertAction(title: "Select", style: .default, handler: { _ in self.selectFiles() }))
        menu.addAction(UIAlertAction(title: "Import", style: .default, handler: { _ in self.importFile() }))
        menu.addAction(UIAlertAction(title: "New Folder", style: .default, handler: { _ in self.createNewFolder() }))
        menu.addAction(UIAlertAction(title: "New File", style: .default, handler: { _ in self.createNewFile() }))
        menu.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(menu, animated: true, completion: nil)
    }

    @objc private func handleLongPress(gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            let point = gesture.location(in: fileListTableView)
            if let indexPath = fileListTableView.indexPathForRow(at: point) {
                let fileName = fileList[indexPath.row]
                let fileURL = documentsDirectory.appendingPathComponent(fileName)
                showFileOptions(for: fileURL)
            }
        }
    }
    
    private func showFileOptions(for fileURL: URL) {
        let fileExtension = fileURL.pathExtension.lowercased()
        let menu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        if fileExtension == "ipa" {
            menu.addAction(UIAlertAction(title: "Unzip", style: .default, handler: { _ in self.unzipFile(at: fileURL) }))
            menu.addAction(UIAlertAction(title: "Hex Edit", style: .default, handler: { _ in self.hexEditFile(at: fileURL) }))
        } else {
            menu.addAction(UIAlertAction(title: "Copy", style: .default, handler: { _ in self.copyFile(at: fileURL) }))
            menu.addAction(UIAlertAction(title: "Move", style: .default, handler: { _ in self.moveFile(at: fileURL) }))
            menu.addAction(UIAlertAction(title: "Compress", style: .default, handler: { _ in self.compressFile(at: fileURL) }))
            menu.addAction(UIAlertAction(title: "Rename", style: .default, handler: { _ in self.renameFile(at: fileURL) }))
            menu.addAction(UIAlertAction(title: "Delete", style: .default, handler: { _ in self.deleteFile(at: fileURL) }))
        }
        
        menu.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(menu, animated: true, completion: nil)
    }

    private func selectFiles() {
        // Implement select files functionality
    }
    
    private func importFile() {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.data], asCopy: true)
        documentPicker.delegate = self
        documentPicker.modalPresentationStyle = .formSheet
        present(documentPicker, animated: true, completion: nil)
    }
    
    private func createNewFolder() {
        let alertController = UIAlertController(title: "New Folder", message: "Enter folder name", preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.placeholder = "Folder name"
        }
        let createAction = UIAlertAction(title: "Create", style: .default) { _ in
            guard let folderName = alertController.textFields?.first?.text else { return }
            let folderURL = self.documentsDirectory.appendingPathComponent(folderName)
            do {
                try self.fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)
                self.loadFiles()
            } catch {
                print("Failed to create folder: \(error)")
            }
        }
        alertController.addAction(createAction)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    private func createNewFile() {
        let alertController = UIAlertController(title: "New File", message: "Enter file name", preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.placeholder = "File name"
        }
        let createAction = UIAlertAction(title: "Create", style: .default) { _ in
            guard let fileName = alertController.textFields?.first?.text else { return }
            let fileURL = self.documentsDirectory.appendingPathComponent(fileName)
            self.fileManager.createFile(atPath: fileURL.path, contents: nil, attributes: nil)
            self.loadFiles()
        }
        alertController.addAction(createAction)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    private func copyFile(at fileURL: URL) {
        let destinationURL = fileURL.deletingLastPathComponent().appendingPathComponent("Copy_\(fileURL.lastPathComponent)")
        do {
            try FileOperations.copyFile(at: fileURL, to: destinationURL)
            loadFiles()
        } catch {
            print("Copy failed with error: \(error)")
        }
    }
    
    private func moveFile(at fileURL: URL) {
        let alertController = UIAlertController(title: "Move File", message: "Enter new file path", preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.placeholder = "New file path"
        }
        let moveAction = UIAlertAction(title: "Move", style: .default) { _ in
            guard let newPath = alertController.textFields?.first?.text else { return }
            let destinationURL = self.documentsDirectory.appendingPathComponent(newPath)
            do {
                try FileOperations.moveFile(at: fileURL, to: destinationURL)
                self.loadFiles()
            } catch {
                print("Move failed with error: \(error)")
            }
        }
        alertController.addAction(moveAction)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    private func compressFile(at fileURL: URL) {
        let destinationURL = fileURL.deletingLastPathComponent().appendingPathComponent("\(fileURL.lastPathComponent).zip")
        do {
            try FileOperations.compressFile(at: fileURL, to: destinationURL)
            loadFiles()
        } catch {
            print("Compression failed with error: \(error)")
        }
    }
    
    private func renameFile(at fileURL: URL) {
        let alertController = UIAlertController(title: "Rename File", message: "Enter new file name", preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.text = fileURL.lastPathComponent
        }
        let renameAction = UIAlertAction(title: "Rename", style: .default) { _ in
            guard let newName = alertController.textFields?.first?.text else { return }
            let destinationURL = fileURL.deletingLastPathComponent().appendingPathComponent(newName)
            do {
                try FileOperations.renameFile(at: fileURL, to: newName)
                self.loadFiles()
            } catch {
                print("Rename failed with error: \(error)")
            }
        }
        alertController.addAction(renameAction)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    private func deleteFile(at fileURL: URL) {
        do {
            try FileOperations.deleteFile(at: fileURL)
            loadFiles()
        } catch {
            print("Delete failed with error: \(error)")
        }
    }
    
    private func unzipFile(at fileURL: URL) {
        let destinationURL = fileURL.deletingLastPathComponent().appendingPathComponent("extracted")
        do {
            try FileOperations.unzipFile(at: fileURL, to: destinationURL)
            loadFiles()
        } catch {
            print("Unzip failed with error: \(error)")
        }
    }
    
    private func hexEditFile(at fileURL: URL) {
        FileOperations.hexEditFile(at: fileURL)
        // Implement hex edit functionality
    }
    
    // MARK: - UIDocumentPickerViewControllerDelegate
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let selectedFileURL = urls.first else {
            return
        }
        // Handle file import
        let destinationURL = documentsDirectory.appendingPathComponent(selectedFileURL.lastPathComponent)
        do {
            try fileManager.copyItem(at: selectedFileURL, to: destinationURL)
            loadFiles()
        } catch {
            print("Failed to import file: \(error)")
        }
    }

    // MARK: - UITableViewDelegate, UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fileList.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FileCell", for: indexPath)
        cell.textLabel?.text = fileList[indexPath.row]
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let fileName = fileList[indexPath.row]
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        openFile(fileURL)
    }

    private func openFile(_ fileURL: URL) {
        let fileExtension = fileURL.pathExtension.lowercased()

        switch fileExtension {
        case "txt":
            openTextEditor(fileURL)
        case "plist":
            openPlistEditor(fileURL)
        default:
            openHexEditor(fileURL)
        }
    }

    private func openTextEditor(_ fileURL: URL) {
        let textEditorVC = TextEditorViewController(fileURL: fileURL)
        navigationController?.pushViewController(textEditorVC, animated: true)
    }

    private func openPlistEditor(_ fileURL: URL) {
        let plistEditorVC = PlistEditorViewController(fileURL: fileURL)
        navigationController?.pushViewController(plistEditorVC, animated: true)
    }

    private func openHexEditor(_ fileURL: URL) {
        let hexEditorVC = HexEditorViewController(fileURL: fileURL)
        navigationController?.pushViewController(hexEditorVC, animated: true)
    }
}