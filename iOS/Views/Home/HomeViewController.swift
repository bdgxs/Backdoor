import UIKit
import ZIPFoundation
import Foundation

class HomeViewController: UIViewController, UISearchResultsUpdating, UIScrollViewDelegate {
    
    // MARK: - Properties
    var fileList: [String] = [] // Removed 'private' for accessibility
    var filteredFileList: [String] = [] // Removed 'private' for accessibility
    let fileManager = FileManager.default
    let searchController = UISearchController(searchResultsController: nil) // Removed 'private' for accessibility
    private var sortOrder: SortOrder = .name
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
        let addButton = UIBarButtonItem(image: UIImage(systemName: "folder.badge.plus"), style: .plain, target: self, action: #selector(addDirectory))
        
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
        fileListTableView.register(FileTableViewCell.self, forCellReuseIdentifier: "FileCell")
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
                let files = try self.fileManager.contentsOfDirectory(at: self.documentsDirectory, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
                DispatchQueue.main.async {
                    self.fileList = files.map { $0.lastPathComponent }
                    self.sortFiles()
                    self.fileListTableView.reloadData()
                    self.activityIndicator.stopAnimating()
                }
            } catch {
                print("Error loading files: \(error)")
                DispatchQueue.main.async {
                    self.activityIndicator.stopAnimating()
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
                        let progressHandler: Progress? = nil
                        try self.fileManager.unzipItem(at: url, to: destinationURL, progress: progressHandler)
                    } else {
                        try self.fileManager.copyItem(at: url, to: destinationURL)
                    }
                    url.stopAccessingSecurityScopedResource()
                    DispatchQueue.main.async {
                        self.loadFiles()
                    }
                }
            } catch {
                print("Error handling file: \(error)")
                self.utilities.handleError(in: self, error: error, withTitle: "File Import Error")
            }
        }
    }
    
    func deleteFile(at index: Int) {
        let fileToDelete = fileList[index]
        let fileURL = documentsDirectory.appendingPathComponent(fileToDelete)
        do {
            try fileManager.removeItem(at: fileURL)
            fileList.remove(at: index)
            fileListTableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .fade)
        } catch {
            print("Error deleting file: \(error)")
            self.utilities.handleError(in: self, error: error, withTitle: "File Delete Error")
        }
    }
    
    func sortFiles() {
        switch sortOrder {
        case .name:
            fileList.sort { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
        case .date:
            // Need to implement file date retrieval and sorting
            break
        case .size:
            // Need to implement file size retrieval and sorting
            break
        }
    }
    
    // MARK: - UI Actions
    @objc private func showMenu() {
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
    
    // MARK: - UISearchResultsUpdating
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text else { return }
        filteredFileList = fileList.filter { $0.localizedCaseInsensitiveContains(searchText) }
        fileListTableView.reloadData()
    }
    
    @objc private func addDirectory() {
        let alertController = UIAlertController(title: "Add Directory", message: "Enter the name of the new directory", preferredStyle: .alert)
        alertController.addTextField { (textField) in
            textField.placeholder = "Directory Name"
        }
        
        let createAction = UIAlertAction(title: "Create", style: .default) { [weak self] _ in
            guard let self = self,
                  let textField = alertController.textFields?.first,
                  let directoryName = textField.text,
                  !directoryName.isEmpty else { return }
            
            let newDirectoryURL = self.documentsDirectory.appendingPathComponent(directoryName)
            
            do {
                try self.fileManager.createDirectory(at: newDirectoryURL, withIntermediateDirectories: false, attributes: nil)
                self.loadFiles()
            } catch {
                print("Error creating directory: \(error)")
                self.utilities.handleError(in: self, error: error, withTitle: "Directory Creation Error")
            }
        }
        alertController.addAction(createAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    // MARK: - File Options
    private func showFileOptions(for fileURL: URL) {
        let alertController = UIAlertController(title: "File Options", message: fileURL.lastPathComponent, preferredStyle: .actionSheet)
        
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            if let index = self.fileList.firstIndex(of: fileURL.lastPathComponent) {
                self.deleteFile(at: index)
            }
        }
        alertController.addAction(deleteAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
}

// MARK: - Extensions
extension HomeViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let selectedFileURL = urls.first else { return }
        handleImportedFile(url: selectedFileURL)
    }
}

extension HomeViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchController.isActive ? filteredFileList.count : fileList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FileCell", for: indexPath)
        let fileName = searchController.isActive ? filteredFileList[indexPath.row] : fileList[indexPath.row]
        cell.textLabel?.text = fileName
        return cell
    }
}

extension HomeViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let fileName = searchController.isActive ? filteredFileList[indexPath.row] : fileList[indexPath.row]
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        showFileOptions(for: fileURL)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension HomeViewController: UITableViewDropDelegate {
    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
        for dropItem in coordinator.items {
            dropItem.dragItem.itemProvider.loadObject(ofClass: URL.self) { [weak self] (object: URL?, error: Error?) in
                guard let self = self, let url = object else {
                    if let error = error {
                        print("Drop error: \(error)")
                    }
                    return
                }
                DispatchQueue.main.async {
                    self.handleImportedFile(url: url)
                }
            }
        }
    }
}

extension HomeViewController: UITableViewDragDelegate {
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        return [] // Implement drag support if needed
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