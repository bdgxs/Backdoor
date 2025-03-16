import UIKit
import ZIPFoundation

class HomeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIDocumentPickerDelegate {
    
    // MARK: - Properties
    private var fileList: [String] = []
    private let fileManager = FileManager.default

    // MARK: - UI Elements
    private let navigationBar: UINavigationBar = {
        let navBar = UINavigationBar()
        navBar.translatesAutoresizingMaskIntoConstraints = false
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
            navigationBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
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
                let fileURL = URL(fileURLWithPath: fileName)
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
        // Implement create new folder functionality
    }
    
    private func createNewFile() {
        // Implement create new file functionality
    }
    
    private func copyFile(at fileURL: URL) {
        let destinationURL = fileURL.deletingLastPathComponent().appendingPathComponent("Copy_\(fileURL.lastPathComponent)")
        do {
            try FileOperations.copyFile(at: fileURL, to: destinationURL)
            print("File copied to \(destinationURL.path)")
        } catch {
            print("Copy failed with error: \(error)")
        }
    }
    
    private func moveFile(at fileURL: URL) {
        let destinationURL = fileURL.deletingLastPathComponent().appendingPathComponent("Moved_\(fileURL.lastPathComponent)")
        do {
            try FileOperations.moveFile(at: fileURL, to: destinationURL)
            print("File moved to \(destinationURL.path)")
        } catch {
            print("Move failed with error: \(error)")
        }
    }
    
    private func compressFile(at fileURL: URL) {
        let destinationURL = fileURL.deletingLastPathComponent().appendingPathComponent("\(fileURL.lastPathComponent).zip")
        do {
            try FileOperations.compressFile(at: fileURL, to: destinationURL)
            print("File compressed to \(destinationURL.path)")
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
            do {
                try FileOperations.renameFile(at: fileURL, to: newName)
                print("File renamed to \(newName)")
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
            print("File deleted")
        } catch {
            print("Delete failed with error: \(error)")
        }
    }
    
    private func unzipFile(at fileURL: URL) {
        let destinationURL = fileURL.deletingLastPathComponent().appendingPathComponent("extracted")
        do {
            try FileOperations.unzipFile(at: fileURL, to: destinationURL)
            print("File unzipped to \(destinationURL.path)")
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
        print("Selected file: \(selectedFileURL.path)")
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
        let fileURL = URL(fileURLWithPath: fileName)
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