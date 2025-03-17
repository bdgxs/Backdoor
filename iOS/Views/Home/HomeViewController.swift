import UIKit
import ZIPFoundation

class HomeViewController: UIViewController, UIDocumentPickerDelegate, UISearchResultsUpdating, UITableViewDragDelegate, UITableViewDropDelegate, UITableViewDelegate, UITableViewDataSource, FileHandlingDelegate {

    // MARK: - Properties
    private var fileList: [String] =
    private var filteredFileList: [String] =
    private let fileManager = FileManager.default
    private let searchController = UISearchController(searchResultsController: nil)
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
        let menuButton = UIBarButtonItem(image: UIImage(systemName: "ellipsis.circle"), style: .plain, target: self, action: #selector(showOptionsMenu))
        navItem.rightBarButtonItem = menuButton

        let navBar = UINavigationBar(frame: CGRect(x: 0, y: view.safeAreaInsets.top, width: view.bounds.width, height: 44))
        navBar.translatesAutoresizingMaskIntoConstraints = false
        navBar.items = [navItem]
        view.addSubview(navBar)

        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search Files"
        navigationItem.searchController = searchController
        definesPresentationContext = true

        view.addSubview(fileListTableView)

        NSLayoutConstraint.activate([
            navBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            navBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            fileListTableView.topAnchor.constraint(equalTo: navBar.bottomAnchor),
            fileListTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            fileListTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            fileListTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupActivityIndicator() {
        view.addSubview(activityIndicator)
        activityIndicator.center = view.center
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
        DispatchQueue.global().async {
            do {
                let contents = try self.fileManager.contentsOfDirectory(atPath: self.documentsDirectory.path)
                DispatchQueue.main.async {
                    self.fileList = contents.sorted()
                    self.filteredFileList = self.fileList
                    self.fileListTableView.reloadData()
                    self.activityIndicator.stopAnimating()
                }
            } catch {
                DispatchQueue.main.async {
                    self.activityIndicator.stopAnimating()
                    self.utilities.handleError(in: self, error: error, withTitle: "Error Loading Files")
                }
            }
        }
    }

    func deleteFile(at url: URL) {
        do {
            try fileManager.removeItem(at: url)
            loadFiles()
        } catch {
            utilities.handleError(in: self, error: error, withTitle: "Error Deleting File")
        }
    }

    func renameFile(at url: URL, newName: String) {
        let newURL = url.deletingLastPathComponent().appendingPathComponent(newName)
        do {
            try fileManager.moveItem(at: url, to: newURL)
            loadFiles()
        } catch {
            utilities.handleError(in: self, error: error, withTitle: "Error Renaming File")
        }
    }

    func duplicateFile(at url: URL) {
        let newName = "Copy of \(url.lastPathComponent)"
        let newURL = url.deletingLastPathComponent().appendingPathComponent(newName)
        do {
            try fileManager.copyItem(at: url, to: newURL)
            loadFiles()
        } catch {
            utilities.handleError(in: self, error: error, withTitle: "Error Duplicating File")
        }
    }

    // MARK: - Navigation
    @objc private func showOptionsMenu() {
        let alertController = UIAlertController(title: nil, message: "File Options", preferredStyle: .actionSheet)

        let uploadAction = UIAlertAction(title: "Upload File", style: .default) { _ in
            self.fileHandlers.uploadFile(viewController: self)
        }
        alertController.addAction(uploadAction)

        let importAction = UIAlertAction(title: "Import File", style: .default) { _ in
            self.fileHandlers.importFile(viewController: self)
        }
        alertController.addAction(importAction)

        let newFolderAction = UIAlertAction(title: "New Folder", style: .default) { _ in
            self.showNewFolderAlert()
        }
        alertController.addAction(newFolderAction)

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)

        present(alertController, animated: true, completion: nil)
    }

    private func showNewFolderAlert() {
        let alertController = UIAlertController(title: "New Folder", message: "Enter folder name", preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.placeholder = "Folder Name"
        }

        let createAction = UIAlertAction(title: "Create", style: .default) { [weak self, weak alertController] _ in
            guard let folderName = alertController?.textFields?.first?.text, !folderName.isEmpty else { return }
            self?.fileHandlers.createNewFolder(viewController: self!, folderName: folderName) { result in
                switch result {
                case .success(_):
                    self?.loadFiles()
                case .failure(let error):
                    self?.utilities.handleError(in: self!, error: error, withTitle: "Error Creating Folder")
                }
            }
        }
        alertController.addAction(createAction)

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)

        present(alertController, animated: true, completion: nil)
    }

    func showFileOptions(for fileURL: URL) {
        let alertController = UIAlertController(title: nil, message: fileURL.lastPathComponent, preferredStyle: .actionSheet)

        let openAction = UIAlertAction(title: "Open", style: .default) { _ in
            self.openFile(at: fileURL)
        }
        alertController.addAction(openAction)

        let renameAction = UIAlertAction(title: "Rename", style: .default) { _ in
            self.showRenameAlert(for: fileURL)
        }
        alertController.addAction(renameAction)

        let duplicateAction = UIAlertAction(title: "Duplicate", style: .default) { _ in
            self.duplicateFile(at: fileURL)
        }
        alertController.addAction(duplicateAction)

        let shareAction = UIAlertAction(title: "Share", style: .default) { _ in
            self.utilities.shareFile(viewController: self, fileURL: fileURL)
        }
        alertController.addAction(shareAction)

        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { _ in
            self.deleteFile(at: fileURL)
        }
        alertController.addAction(deleteAction)

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)

        present(alertController, animated: true, completion: nil)
    }

    func openFile(at fileURL: URL) {
        let fileExtension = fileURL.pathExtension.lowercased()

        switch fileExtension {
        case "txt", "swift", "json", "js", "html", "css", "c", "cpp", "h", "m", "rs":
            let textEditorVC = TextEditorViewController(fileURL: fileURL)
            navigationController?.pushViewController(textEditorVC, animated: true)
        case "plist":
            let plistVC = PlistEditorViewController(fileURL: fileURL)
            navigationController?.pushViewController(plistVC, animated: true)
        default:
            UIDocumentPickerViewController.revealDocument(at: fileURL, in: self.view, animated: true) { _ in
                // Completion handler (optional)
            }
        }
    }

    private func showRenameAlert(for fileURL: URL) {
        let alertController = UIAlertController(title: "Rename File", message: "Enter new file name", preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.text = fileURL.lastPathComponent
        }

        let renameAction = UIAlertAction(title: "Rename", style: .default) { [weak self, weak alertController] _ in
            guard let newName = alertController?.textFields?.first?.text, !newName.isEmpty else { return }
            self?.renameFile(at: fileURL, newName: newName)
        }
        alertController.addAction(renameAction)

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)

        present(alertController, animated: true, completion: nil)
    }

    // MARK: - UIDocumentPickerDelegate
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let selectedFileURL = urls.first else { return }

        let destinationURL = documentsDirectory.appendingPathComponent(selectedFileURL.lastPathComponent)

        if fileManager.fileExists(atPath: destinationURL.path) {
            utilities.handleError(in: self, error: NSError(domain: "com.example.app", code: -1, userInfo: [NSLocalizedDescriptionKey: "File already exists"]), withTitle: "File Exists")
            return
        }

        do {
            try fileManager.copyItem(at: selectedFileURL, to: destinationURL)
            loadFiles()
        } catch {
            utilities.handleError(in: self, error: error, withTitle: "File Copy Failed")
        }
    }

    // MARK: - UISearchResultsUpdating
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text else { return }
        filteredFileList = fileList.filter { $0.localizedCaseInsensitiveContains(searchText) }
        fileListTableView.reloadData()
    }

    // MARK: - UITableViewDragDelegate
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        let item = self.fileList[indexPath.row]
        let itemProvider = NSItemProvider(object: item as NSString)
        let dragItem = UIDragItem(itemProvider: itemProvider)
        return [dragItem]
    }

    // MARK: - UITableViewDropDelegate
    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
        coordinator.session.loadObjects(ofClass: NSString.self) { items in
            guard let string = items.first as? String else { return }
            self.fileList.append(string)
            self.loadFiles()
        }
    }

    func tableView(_ tableView: UITableView, canHandle session: UIDropSession) -> Bool {
        return session.canLoadObjects(ofClass: NSString.self)
    }

    func tableView(_ tableView: UITableView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal {
        return UITableViewDropProposal(operation: .copy, intent: .insertAtDestinationIndexPath)
    }
}