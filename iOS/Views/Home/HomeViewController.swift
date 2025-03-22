import UIKit
import ZIPFoundation
import Foundation

class HomeViewController: UIViewController, UISearchResultsUpdating, UITableViewDragDelegate, UITableViewDropDelegate, UITableViewDelegate, UITableViewDataSource {

    // MARK: - Properties
    private var fileList: [File] =// Changed to [File]
    private var filteredFileList: [File] =// Changed to [File]
    private let fileManager = FileManager.default
    private let searchController = UISearchController(searchResultsController: nil)
    private var sortOrder: SortOrder = .name
    let fileHandlers = HomeViewFileHandlers()
    let utilities = HomeViewUtilities(logger: Logger(subsystem: "com.example.FileApp", category: "HomeViewController")) // Initialize logger

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
            fileListTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
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
        fileListTableView.register(UITableViewCell.self, forCellReuseIdentifier: "FileCell")
    }

    private func createFilesDirectoryIfNeeded(at directory: URL) {
        if !fileManager.fileExists(atPath: directory.path) {
            do {
                try fileManager.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
            } catch {
                utilities.logger.error("Error creating directory: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - File Operations
    func loadFiles() {
        activityIndicator.startAnimating()
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            do {
                let fileURLs = try self.fileManager.contentsOfDirectory(at: self.documentsDirectory, includingPropertiesForKeys: nil)
                self.utilities.logger.info("Loaded \(fileURLs.count) files")

                let files = fileURLs.map { File(url: $0) } // Create File objects
                DispatchQueue.main.async {
                    self.fileList = files
                    self.sortFiles()
                    self.fileListTableView.reloadData()
                    self.activityIndicator.stopAnimating()
                }
            } catch {
                self.utilities.logger.error("Error loading files: \(error.localizedDescription)")
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
                        let progressHandler: Progress? = nil // Adjust to match expected type
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
                self.utilities.logger.error("Error handling imported file: \(error.localizedDescription)")
            }
        }
    }

    func deleteFile(at index: Int) {
        let fileToDelete = fileList[index]
        do {
            try fileManager.removeItem(at: fileToDelete.url)
            fileList.remove(at: index)
            fileListTableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .fade)
        } catch {
            utilities.logger.error("Error deleting file: \(error.localizedDescription)")
        }
    }

    func sortFiles() {
        switch sortOrder {
        case .name:
            fileList.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .date:
            fileList.sort { $0.date < $1.date }
        case .size:
            fileList.sort { $0.size < $1.size }
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

        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }

    @objc private func addDirectory() {
        let alertController = UIAlertController(title: "New Directory", message: "Enter directory name:", preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.placeholder = "Directory name"
        }

        let createAction = UIAlertAction(title: "Create", style: .default) { [weak self, weak alertController] _ in
            guard let directoryName = alertController?.textFields?.first?.text,
                  !directoryName.isEmpty else { return }

            let newDirectoryURL = self?.documentsDirectory.appendingPathComponent(directoryName)

            do {
                try self?.fileManager.createDirectory(at: newDirectoryURL!, withIntermediateDirectories: false, attributes: nil)
                self?.loadFiles()
            } catch {
                self?.utilities.logger.error("Error creating directory: \(error.localizedDescription)")
            }
        }
        alertController.addAction(createAction)

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)

        present(alertController, animated: true, completion: nil)
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

extension HomeViewController {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchController.isActive ? filteredFileList.count : fileList.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FileCell", for: indexPath) as! FileTableViewCell
        let file = searchController.isActive ? filteredFileList[indexPath.row] : fileList[indexPath.row]
        cell.configure(with: file)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let file = searchController.isActive ? filteredFileList[indexPath.row] : fileList[indexPath.row]
        showFileOptions(for: file.url)
    }
}

extension HomeViewController: UITableViewDragDelegate {
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        let file = fileList[indexPath.row]
        let itemProvider = NSItemProvider(contentsOf: file.url)
        let dragItem = UIDragItem(itemProvider: itemProvider)
        dragItem.localObject = file
        return [dragItem]
    }

    func tableView(_ tableView: UITableView, dragSessionDidEnd session: UIDragSession) {
        self.loadFiles()
    }
}

extension HomeViewController: UITableViewDropDelegate {
    func tableView(_ tableView: UITableView, canHandle session: UIDropSession) -> Bool {
        return session.canLoadObjects(ofClass: URL.self)
    }

    func tableView(_ tableView: UITableView, dropSessionDidEnter session: UIDropSession) {
    }

    func tableView(_ tableView: UITableView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal {
        return UITableViewDropProposal(operation: .copy)
    }

    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
        let destinationIndexPath: IndexPath

        if let indexPath = coordinator.destinationIndexPath {
            destinationIndexPath = indexPath
        } else {
            let newRow = tableView.numberOfRows(inSection: 0)
            destinationIndexPath = IndexPath(row: newRow, section: 0)
        }

        coordinator.items.forEach {  drop.loadObjects(ofClass: URL.self) { [weak self] droppedItems in
            guard let self = self else { return }

            DispatchQueue.main.async {
                for item in droppedItems {
                    if let url = item as? URL {
                        let destinationURL = self.documentsDirectory.appendingPathComponent(url.lastPathComponent)
                        do {
                            try self.fileManager.copyItem(at: url, to: destinationURL)
                        } catch {
                            self.utilities.logger.error("Error dropping file: \(error.localizedDescription)")
                        }
                    }
                }
                self.loadFiles()
            }
        }
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            deleteFile(at: indexPath.row)
        }
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
}

extension HomeViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        if let searchText = searchController.searchBar.text, !searchText.isEmpty {
            filteredFileList = fileList.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        } else {
            filteredFileList = fileList
        }
        fileListTableView.reloadData()
    }
}
