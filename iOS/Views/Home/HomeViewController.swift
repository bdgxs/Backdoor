import UIKit
import ZIPFoundation

class HomeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIDocumentPickerDelegate, UISearchResultsUpdating {
    
    // MARK: - Properties
    private var fileList: [String] = []
    private var filteredFileList: [String] = []
    private let fileManager = FileManager.default
    private let searchController = UISearchController(searchResultsController: nil)
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
        searchController.searchResultsUpdater = self
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        filteredFileList = fileList
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
        fileListTableView.register(FileTableViewCell.self, forCellReuseIdentifier: "FileCell")
        
        // Add long press gesture recognizer to table view
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        fileListTableView.addGestureRecognizer(longPressRecognizer)
    }

    // MARK: - Load Files
    private func loadFiles() {
        do {
            fileList = try fileManager.contentsOfDirectory(atPath: documentsDirectory.path)
            filteredFileList = fileList
            fileListTableView.reloadData()
        } catch {
            presentAlert(title: "Error", message: "Failed to load files: \(error.localizedDescription)")
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
                let fileName = filteredFileList[indexPath.row]
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
                self.presentAlert(title: "Error", message: "Failed to create folder: \(error.localizedDescription)")
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
        DispatchQueue.global().async {
            do {
                try FileOperations.copyFile(at: fileURL, to: destinationURL)
                DispatchQueue.main.async {
                    self.loadFiles()
                }
            } catch {
                DispatchQueue.main.async {
                    self.presentAlert(title: "Error", message: "Copy failed with error: \(error.localizedDescription)")
                }
            }
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
            DispatchQueue.global().async {
                do {
                    try FileOperations.moveFile(at: fileURL, to: destinationURL)
                    DispatchQueue.main.async {
                        self.loadFiles()
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.presentAlert(title: "Error", message: "Move failed with error: \(error.localizedDescription)")
                    }
                }
            }
        }
        alertController.addAction(moveAction)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    private func compressFile(at fileURL: URL) {
        let destinationURL = fileURL.deletingLastPathComponent().appendingPathComponent("\(fileURL.lastPathComponent).zip")
        DispatchQueue.global().async {
            do {
                try FileOperations.compressFile(at: fileURL, to: destinationURL)
                DispatchQueue.main.async {
                    self.loadFiles()
                }
            } catch {
                DispatchQueue.main.async {
                    self.presentAlert(title: "Error", message: "Compression failed with error: \(error.localizedDescription)")
                }
            }
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
            DispatchQueue.global().async {
                do {
                    try FileOperations.renameFile(at: fileURL, to: newName)
                    DispatchQueue.main.async {
                        self.loadFiles()
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.presentAlert(title: "Error", message: "Rename failed with error: \(error.localizedDescription)")
                    }
                }
            }
        }
        alertController.addAction(renameAction)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    private func deleteFile(at fileURL: URL) {
        DispatchQueue.global().async {
            do {
                try FileOperations.deleteFile(at: fileURL)
                DispatchQueue.main.async {
                    self.loadFiles()
                }
            } catch {
                DispatchQueue.main.async {
                    self.presentAlert(title: "Error", message: "Delete failed with error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func unzipFile(at fileURL: URL) {
        let destinationURL = fileURL.deletingLastPathComponent().appendingPathComponent("extracted")
        DispatchQueue.global().async {
            do {
                try FileOperations.unzipFile(at: fileURL, to: destinationURL)
                DispatchQueue.main.async {
                    self.loadFiles()
                }
            } catch {
                DispatchQueue.main.async {
                    self.presentAlert(title: "Error", message: "Unzip failed with error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func hexEditFile(at fileURL: URL) {
        guard let navigationController = self.navigationController else {
            presentAlert(title: "Error", message: "Navigation controller is missing")
            return
        }
        FileOperations.hexEditFile(at: fileURL, in: navigationController)
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
            presentAlert(title: "Error", message: "Failed to import file: \(error.localizedDescription)")
        }
    }

    // MARK: - UITableViewDelegate, UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchController.isActive ? filteredFileList.count : fileList.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FileCell", for: indexPath) as! FileTableViewCell
        let fileName = searchController.isActive ? filteredFileList[indexPath.row] : fileList[indexPath.row]
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        let file = File(url: fileURL)
        cell.configure(with: file)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let fileName = searchController.isActive ? filteredFileList[indexPath.row] : fileList[indexPath.row]
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        openFile(fileURL)
    }

    // MARK: - UISearchResultsUpdating
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text else { return }
        filteredFileList = fileList.filter { $0.contains(searchText) }
        fileListTableView.reloadData()
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
    
    // MARK: - Helper Methods
    private func presentAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}

// Custom UITableViewCell
class FileTableViewCell: UITableViewCell {
    let fileIconImageView = UIImageView()
    let fileNameLabel = UILabel()
    let fileSizeLabel = UILabel()
    let fileDateLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        // Configure and add subviews to contentView
        contentView.addSubview(fileIconImageView)
        contentView.addSubview(fileNameLabel)
        contentView.addSubview(fileSizeLabel)
        contentView.addSubview(fileDateLabel)

        // Setup layout constraints
        fileIconImageView.translatesAutoresizingMaskIntoConstraints = false
        fileNameLabel.translatesAutoresizingMaskIntoConstraints = false
        fileSizeLabel.translatesAutoresizingMaskIntoConstraints = false
        fileDateLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            fileIconImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            fileIconImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            fileIconImageView.widthAnchor.constraint(equalToConstant: 40),
            fileIconImageView.heightAnchor.constraint(equalToConstant: 40),

            fileNameLabel.leadingAnchor.constraint(equalTo: fileIconImageView.trailingAnchor, constant: 16),
            fileNameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            fileNameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),

            fileSizeLabel.leadingAnchor.constraint(equalTo: fileNameLabel.leadingAnchor),
            fileSizeLabel.topAnchor.constraint(equalTo: fileNameLabel.bottomAnchor, constant: 4),

            fileDateLabel.leadingAnchor.constraint(equalTo: