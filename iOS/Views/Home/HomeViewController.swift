import UIKit
import ZIPFoundation

class HomeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIDocumentPickerDelegate, UISearchResultsUpdating, UITableViewDragDelegate, UITableViewDropDelegate {

    // MARK: - Properties
    private var fileList: [String] = []
    private var filteredFileList: [String] = []
    private let fileManager = FileManager.default
    private let searchController = UISearchController(searchResultsController: nil)
    private var sortOrder: SortOrder = .name
    private var documentsDirectory: URL {
        let directory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("files")
        createFilesDirectoryIfNeeded(at: directory)
        return directory
    }

    enum SortOrder {
        case name, date, size
    }

    // MARK: - UI Elements
    private let navigationBar: UINavigationBar = {
        let navBar = UINavigationBar()
        navBar.translatesAutoresizingMaskIntoConstraints = false
        navBar.barTintColor = .systemBlue
        navBar.titleTextAttributes = [.foregroundColor: UIColor.white]
        return navBar
    }()
    
    private let fileListTableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    private let uploadButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Upload File", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(uploadFile), for: .touchUpInside)
        return button
    }()
        // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActivityIndicator()
        loadFiles()
        fileListTableView.delegate = self
        fileListTableView.dataSource = self
        fileListTableView.dragDelegate = self
        fileListTableView.dropDelegate = self
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
        let menuButton = UIBarButtonItem(title: "\u{22ee}", style: .plain, target: self, action: #selector(showMenu))
        let sortButton = UIBarButtonItem(title: "Sort", style: .plain, target: self, action: #selector(changeSortOrder))
        navItem.rightBarButtonItems = [menuButton, sortButton]
        navigationBar.setItems([navItem], animated: false)
        
        // Add UI elements to the view
        view.addSubview(navigationBar)
        view.addSubview(fileListTableView)
        view.addSubview(activityIndicator)
        view.addSubview(uploadButton)
        
        // Set up constraints with padding
        NSLayoutConstraint.activate([
            navigationBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            navigationBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navigationBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            fileListTableView.topAnchor.constraint(equalTo: navigationBar.bottomAnchor),
            fileListTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            fileListTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            fileListTableView.bottomAnchor.constraint(equalTo: uploadButton.topAnchor),
            
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            uploadButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            uploadButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            uploadButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            uploadButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        // Register the table view cell
        fileListTableView.register(FileTableViewCell.self, forCellReuseIdentifier: "FileCell")
        
        // Add long press gesture recognizer to table view
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        fileListTableView.addGestureRecognizer(longPressRecognizer)
    }

    private func setupActivityIndicator() {
        view.addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
        // MARK: - Load Files
    private func loadFiles() {
        do {
            fileList = try fileManager.contentsOfDirectory(atPath: documentsDirectory.path)
            sortFiles()
            filteredFileList = fileList
            fileListTableView.reloadData()
        } catch {
            presentAlert(title: "Error", message: "Failed to load files: \(error.localizedDescription)")
        }
    }

    private func sortFiles() {
        switch sortOrder {
        case .name:
            fileList.sort(by: { $0.lowercased() < $1.lowercased() })
        case .date:
            fileList.sort(by: { getFileDate($0) < getFileDate($1) })
        case .size:
            fileList.sort(by: { getFileSize($0) < getFileSize($1) })
        }
    }

    private func getFileDate(_ fileName: String) -> Date {
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path)
        return attributes?[.modificationDate] as? Date ?? Date.distantPast
    }

    private func getFileSize(_ fileName: String) -> UInt64 {
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path)
        return attributes?[.size] as? UInt64 ?? 0
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

    @objc private func changeSortOrder() {
        let sortMenu = UIAlertController(title: "Sort By", message: nil, preferredStyle: .actionSheet)
        sortMenu.addAction(UIAlertAction(title: "Name", style: .default, handler: { _ in self.sortOrder = .name; self.loadFiles() }))
        sortMenu.addAction(UIAlertAction(title: "Date", style: .default, handler: { _ in self.sortOrder = .date; self.loadFiles() }))
        sortMenu.addAction(UIAlertAction(title: "Size", style: .default, handler: { _ in self.sortOrder = .size; self.loadFiles() }))
        sortMenu.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(sortMenu, animated: true, completion: nil)
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
            menu.addAction(UIAlertAction(title: "Share", style: .default, handler: { _ in self.shareFile(at: fileURL) }))
        }
        
        menu.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(menu, animated: true, completion: nil)
    }

    private func selectFiles() {
        // Implement select files functionality
    }
    
    @objc private func uploadFile() {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.data], asCopy: true)
        documentPicker.delegate = self
        documentPicker.modalPresentationStyle = .formSheet
        present(documentPicker, animated: true, completion: nil)
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