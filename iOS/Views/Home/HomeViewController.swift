import UIKit
import ZIPFoundation
import Foundation

class HomeViewController: UIViewController, UISearchResultsUpdating, UITableViewDragDelegate, UITableViewDropDelegate {

    // MARK: - Properties
    fileprivate var fileList: [String] =
    fileprivate var filteredFileList: [String] =
    fileprivate let fileManager = FileManager.default
    fileprivate let searchController = UISearchController(searchResultsController: nil)
    fileprivate var sortOrder: SortOrder = .name
    let fileHandlers = HomeViewFileHandlers()
    let utilities = HomeViewUtilities()

    var documentsDirectory: URL {
        let directory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("files")
        createFilesDirectoryIfNeeded(at: directory)
        return directory
    }

    enum SortOrder {
        case name, date, size
    }

    let fileListTableView = UITableView()
    let activityIndicator = UIActivityIndicatorView(style: .large)

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActivityIndicator()
        loadFiles()
        configureTableView()
    }

    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground

        let navItem = UINavigationItem(title: "Files")
        let menuButton = UIBarButtonItem(image: UIImage(systemName: "ellipsis.circle"), style: .plain, target: self, action: #selector(showMenu))
        let uploadButton = UIBarButtonItem(image: UIImage(systemName: "square.and.arrow.up"), style: .plain, target: self, action: #selector(importFile))
        let addButton = UIBarButtonItem(image: UIImage(systemName: "folder.badge.plus"), style: .plain, target: self, action: #selector(addDirectory)) // Add Directory button

        navItem.rightBarButtonItems = [menuButton, uploadButton, addButton]
        navigationController?.navigationBar.setItems([navItem], animated: false)

        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search Files"
        navigationItem.searchController = searchController
        definesPresentationContext = true

        view.addSubview(fileListTableView)
        fileListTableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            fileListTableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            fileListTableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            fileListTableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            fileListTableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    private func setupActivityIndicator() {
        view.addSubview(activityIndicator)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func configureTableView() {
        fileListTableView.delegate = self
        fileListTableView.dataSource = self
        fileListTableView.dragDelegate = self
        fileListTableView.dropDelegate = self
        fileListTableView.register(UITableViewCell.self, forCellReuseIdentifier: "fileCell")
    }

    private func createFilesDirectoryIfNeeded(at directory: URL) {
        if !fileManager.fileExists(atPath: directory.path) {
            do {
                try fileManager.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Error creating directory: \(error)")
            }
        }
    }

    // MARK: - File Operations
    func loadFiles() {
        activityIndicator.startAnimating()
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            do {
                let files = try self?.fileManager.contentsOfDirectory(atPath: self?.documentsDirectory.path ?? "")
                DispatchQueue.main.async {
                    self?.fileList = files ??
                    self?.sortFiles()
                    self?.fileListTableView.reloadData()
                    self?.activityIndicator.stopAnimating()
                }
            } catch {
                print("Error loading files: \(error)")
                DispatchQueue.main.async {
                    self?.activityIndicator.stopAnimating()
                }
            }
        }
    }

    @objc private func importFile() {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.zip, .item])
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        present(documentPicker, animated: true, completion: nil)
    }

    func handleImportedFile(url: URL) {
        let destinationURL = documentsDirectory.appendingPathComponent(url.lastPathComponent)
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            do {
                if url.startAccessingSecurityScopedResource() {
                    if url.pathExtension == "zip" {
                        let progressHandler: Progress? = nil // Adjust to match expected type
                        try self?.fileManager.unzipItem(at: url, to: destinationURL, progress: progressHandler)
                    } else {
                        try self?.fileManager.copyItem(at: url, to: destinationURL)
                    }
                    url.stopAccessingSecurityScopedResource()
                    DispatchQueue.main.async {
                        self?.loadFiles()
                    }
                }
            } catch {
                print("Error handling file: \(error)")
            }
        }
    }

    @objc private func showMenu() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let sortAction = UIAlertAction(title: "Sort", style: .default) { [weak self] _ in
            self?.showSortOptions()
        }
        alertController.addAction(sortAction)
        
        let newFolderAction = UIAlertAction(title: "New Folder", style: .default) { [weak self] _ in
            self?.addDirectory()
        }
        alertController.addAction(newFolderAction)
        
        let newFileAction = UIAlertAction(title: "New File", style: .default) { [weak self] _ in
            self?.addFile()
        }
        alertController.addAction(newFileAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }

    func showFileOptions(for url: URL) {
        let alertController = UIAlertController(title: url.lastPathComponent, message: nil, preferredStyle: .actionSheet)

        let openAction = UIAlertAction(title: "Open", style: .default) { [weak self] _ in
            self?.openFile(at: url)
        }
        alertController.addAction(openAction)

        let renameAction = UIAlertAction(title: "Rename", style: .default) { [weak self] _ in
            self?.renameFile(at: url)
        }
        alertController.addAction(renameAction)

        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.deleteFile(at: url)
        }
        alertController.addAction(deleteAction)

        let shareAction = UIAlertAction(title: "Share", style: .default) { [weak self] _ in
            self?.fileHandlers.shareFile(viewController: self!, fileURL: url)
        }
        alertController.addAction(shareAction)

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)

        present(alertController, animated: true, completion: nil)
    }

    func openFile(at url: URL) {
        let fileExtension = url.pathExtension
        
        switch fileExtension.lowercased() {
        case "txt", "swift", "html", "css", "js", "c", "cpp", "py":
            let textEditorVC = TextEditorViewController(fileURL: url)
            navigationController?.pushViewController(textEditorVC, animated: true)
        case "hex":
            FileOperations.hexEditFile(at: url, in: self)
        case "plist":
            let plistEditorVC = PlistEditorViewController(fileURL: url)
            navigationController?.pushViewController(plistEditorVC, animated: true)
        default:
            let alert = UIAlertController(title: "Cannot Open File", message: "No viewer available for this file type.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            present(alert, animated: true, completion: nil)
        }
    }

    func renameFile(at url: URL) {
        let alertController = UIAlertController(title: "Rename File", message: "Enter new file name", preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.text = url.lastPathComponent
        }
        
        let renameAction = UIAlertAction(title: "Rename", style: .default) { [weak self, weak alertController] _ in
            guard let newName = alertController?.textFields?.first?.text else { return }
            
            let newURL = url.deletingLastPathComponent().appendingPathComponent(newName)
            
            do {
                try self?.fileManager.moveItem(at: url, to: newURL)
                self?.loadFiles()
            } catch {
                print("Error renaming file: \(error)")
            }
        }
        alertController.addAction(renameAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }

    func deleteFile(at url: URL) {
        let alertController = UIAlertController(title: "Delete File", message: "Are you sure you want to delete this file?", preferredStyle: .alert)
        
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            do {
                try self?.fileManager.removeItem(at: url)
                self?.loadFiles()
            } catch {
                print("Error deleting file: \(error)")
            }
        }
        alertController.addAction(deleteAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }

    func addFile() {
        let alertController = UIAlertController(title: "New File", message: "Enter file name", preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.placeholder = "File name"
        }
        
        let createAction = UIAlertAction(title: "Create", style: .default) { [weak self, weak alertController] _ in
            guard let fileName = alertController?.textFields?.first?.text else { return }
            
            self?.fileHandlers.createNewFile(viewController: self!, fileName: fileName) { result in
                switch result {
                case .success(_):
                    self?.loadFiles()
                case .failure(let error):
                    print("Error creating file: \(error)")
                }
            }
        }
        alertController.addAction(createAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }

    @objc func addDirectory() {
        let alertController = UIAlertController(title: "New Folder", message: "Enter folder name", preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.placeholder = "Folder name"
        }
        
        let createAction = UIAlertAction(title: "Create", style: .default) { [weak self, weak alertController] _ in
            guard let directoryName = alertController?.textFields?.first?.text else { return }
            
            self?.fileHandlers.createNewFolder(viewController: self!, folderName: directoryName) { result in
                switch result {
                case .success(_):
                    self?.loadFiles()
                case .failure(let error):
                    print("Error creating directory: \(error)")
                }
            }
        }
        alertController.addAction(createAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }

    func showSortOptions() {
        let alertController = UIAlertController(title: "Sort By", message: nil, preferredStyle: .actionSheet)
        
        let sortByNameAction = UIAlertAction(title: "Name", style: .default) { [weak self] _ in
            self?.sortOrder = .name
            self?.sortFiles()
            self?.fileListTableView.reloadData()
        }
        alertController.addAction(sortByNameAction)
        
        let sortByDateAction = UIAlertAction(title: "Date", style: .default) { [weak self] _ in
            self?.sortOrder = .date
            self?.sortFiles()
            self?.fileListTableView.reloadData()
        }
        alertController.addAction(sortByDateAction)
        
        let sortBySizeAction = UIAlertAction(title: "Size", style: .default) { [weak self] _ in
            self?.sortOrder = .size
            self?.sortFiles()
            self?.fileListTableView.reloadData()
        }
        alertController.addAction(sortBySizeAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }

    func sortFiles() {
        switch sortOrder {
        case .name:
            fileList.sort { $0.localizedCaseInsensitiveCompare($1) == ComparisonResult.orderedAscending }
        case .date:
            fileList.sort {
                let url1 = documentsDirectory.appendingPathComponent($0)
                let url2 = documentsDirectory.appendingPathComponent($1)
                
                let date1 = FileManager.default.creationDate(at: url1.path) ?? Date.distantPast
                let date2 = FileManager.default.creationDate(at: url2.path) ?? Date.distantPast
                
                return date1 < date2
            }
        case .size:
            fileList.sort {
                let url1 = documentsDirectory.appendingPathComponent($0)
                let url2 = documentsDirectory.appendingPathComponent($1)
                
                let size1 = FileManager.default.fileSize(at: url1.path) ?? 0
                let size2 = FileManager.default.fileSize(at: url2.path) ?? 0
                
                return size1 < size2
            }
        }
    }

    // MARK: - UISearchResultsUpdating
    func updateSearchResults(for searchController: UISearchController) {
        if let searchText = searchController.searchBar.text, !searchText.isEmpty {
            filteredFileList = fileList.filter { $0.localizedCaseInsensitiveContains(searchText) }
        } else {
            filteredFileList = fileList
        }
        fileListTableView.reloadData()
    }
}

// MARK: - Extensions
extension HomeViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let selectedFileURL = urls.first else {
            return
        }
        
        handleImportedFile(url: selectedFileURL)
    }
}

extension FileManager {
    func fileSize(at path: String) -> UInt64? {
        do {
            let attr = try attributesOfItem(atPath: path)
            return attr[.size] as? UInt64
        } catch {
            return nil
        }
    }
    
    func creationDate(at path: String) -> Date? {
        do {
            let attr = try attributesOfItem(atPath: path)
            return attr[.creationDate] as? Date
        } catch {
            return nil
        }
    }
}
