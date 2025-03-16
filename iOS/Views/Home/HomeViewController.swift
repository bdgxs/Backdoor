import UIKit
import ZIPFoundation

// Assuming the separated components are in the same module
// If they are in different modules, remember to import them accordingly

class HomeViewController: UIViewController, UIDocumentPickerDelegate, UISearchResultsUpdating, UITableViewDragDelegate, UITableViewDropDelegate {
    
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
        
        // Setup Navigation Bar
        let navItem = UINavigationItem(title: "Files")
        let menuButton = UIBarButtonItem(image: UIImage(systemName: "ellipsis.circle"), style: .plain, target: self, action: #selector(showMenu))
        let sortButton = UIBarButtonItem(title: "Sort", style: .plain, target: self, action: #selector(changeSortOrder))
        navItem.rightBarButtonItems = [menuButton, sortButton]
        HomeViewUI.navigationBar.setItems([navItem], animated: false)

        // Add UI elements to the view
        view.addSubview(HomeViewUI.navigationBar)
        view.addSubview(HomeViewUI.fileListTableView)
        view.addSubview(HomeViewUI.activityIndicator)
        view.addSubview(HomeViewUI.uploadButton)
        
        // Set up constraints
        NSLayoutConstraint.activate([
            HomeViewUI.navigationBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            HomeViewUI.navigationBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            HomeViewUI.navigationBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            HomeViewUI.fileListTableView.topAnchor.constraint(equalTo: HomeViewUI.navigationBar.bottomAnchor),
            HomeViewUI.fileListTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            HomeViewUI.fileListTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            HomeViewUI.fileListTableView.bottomAnchor.constraint(equalTo: HomeViewUI.uploadButton.topAnchor, constant: -20),
            
            HomeViewUI.activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            HomeViewUI.activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            HomeViewUI.uploadButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            HomeViewUI.uploadButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            HomeViewUI.uploadButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            HomeViewUI.uploadButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        // Register the table view cell
        HomeViewUI.fileListTableView.register(FileTableViewCell.self, forCellReuseIdentifier: "FileCell")
        
        // Add long press gesture recognizer to table view
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        HomeViewUI.fileListTableView.addGestureRecognizer(longPressRecognizer)
    }

    private func setupActivityIndicator() {
        view.addSubview(HomeViewUI.activityIndicator)
        NSLayoutConstraint.activate([
            HomeViewUI.activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            HomeViewUI.activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func configureTableView() {
        HomeViewUI.fileListTableView.delegate = self
        HomeViewUI.fileListTableView.dataSource = self
        HomeViewUI.fileListTableView.dragDelegate = self
        HomeViewUI.fileListTableView.dropDelegate = self
        searchController.searchResultsUpdater = self
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        filteredFileList = fileList
    }

    // MARK: - Load Files
    private func loadFiles() {
        HomeViewUI.activityIndicator.startAnimating()
        DispatchQueue.global().async { [weak self] in
            do {
                self?.fileList = try self?.fileManager.contentsOfDirectory(atPath: self?.documentsDirectory.path ?? "") ?? []
                self?.sortFiles()
                DispatchQueue.main.async {
                    self?.filteredFileList = self?.fileList ?? []
                    self?.fileListTableView.reloadData()
                    self?.activityIndicator.stopAnimating()
                }
            } catch {
                DispatchQueue.main.async {
                    self?.activityIndicator.stopAnimating()
                    self?.handleError(error, withTitle: "Loading Files")
                }
            }
        }
    }

    private func sortFiles() {
        switch sortOrder {
        case .name:
            fileList.sort { $0.lowercased() < $1.lowercased() }
        case .date:
            fileList.sort { getFileDate($0) < getFileDate($1) }
        case .size:
            fileList.sort { getFileSize($0) < getFileSize($1) }
        }
    }

    private func getFileDate(_ fileName: String) -> Date {
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        return (try? fileManager.attributesOfItem(atPath: fileURL.path)[.modificationDate] as? Date) ?? Date.distantPast
    }

    private func getFileSize(_ fileName: String) -> UInt64 {
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        return (try? fileManager.attributesOfItem(atPath: fileURL.path)[.size] as? UInt64) ?? 0
    }

    // MARK: - Actions
    @objc private func showMenu() {
        let menu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        ["Select", "Import", "New Folder", "New File"].forEach { actionTitle in
            menu.addAction(UIAlertAction(title: actionTitle, style: .default) { _ in
                switch actionTitle {
                case "Select": self.selectFiles()
                case "Import": self.importFile()
                case "New Folder": self.createNewFolder()
                case "New File": self.createNewFile()
                default: break
                }
            })
        }
        menu.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(menu, animated: true, completion: nil)
    }

    @objc private func changeSortOrder() {
        let sortMenu = UIAlertController(title: "Sort By", message: nil, preferredStyle: .actionSheet)
        ["Name", "Date", "Size"].forEach { sortOption in
            sortMenu.addAction(UIAlertAction(title: sortOption, style: .default) { _ in
                switch sortOption {
                case "Name": self.sortOrder = .name
                case "Date": self.sortOrder = .date
                case "Size": self.sortOrder = .size
                default: return
                }
                self.loadFiles()
            })
        }
        sortMenu.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(sortMenu, animated: true, completion: nil)
    }

    @objc private func handleLongPress(gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            let point = gesture.location(in: HomeViewUI.fileListTableView)
            if let indexPath = HomeViewUI.fileListTableView.indexPathForRow(at: point) {
                let fileName = filteredFileList[indexPath.row]
                let fileURL = documentsDirectory.appendingPathComponent(fileName)
                showFileOptions(for: fileURL)
            }
        }
    }

    private func showFileOptions(for fileURL: URL) {
        let fileExtension = fileURL.pathExtension.lowercased()
        let menu = UIAlertController(title: "File Options", message: "Select an action for this file", preferredStyle: .actionSheet)
        
        switch fileExtension {
        case "txt":
            menu.addAction(UIAlertAction(title: "Open as Text", style: .default, handler: { _ in self.openTextEditor(fileURL) }))
        case "plist":
            menu.addAction(UIAlertAction(title: "Open as Plist", style: .default, handler: { _ in self.openPlistEditor(fileURL) }))
        case "ipa":
            menu.addAction(UIAlertAction(title: "Unzip", style: .default, handler: { _ in self.unzipFile(at: fileURL) }))
            menu.addAction(UIAlertAction(title: "Hex Edit", style: .default, handler: { _ in self.hexEditFile(at: fileURL) }))
        default:
            menu.addAction(UIAlertAction(title: "Open as Hex", style: .default, handler: { _ in self.openHexEditor(fileURL) }))
        }
        
        menu.addAction(UIAlertAction(title: "Rename", style: .default, handler: { _ in self.renameFile(at: fileURL) }))
        menu.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in self.deleteFile(at: fileURL) }))
        menu.addAction(UIAlertAction(title: "Share", style: .default, handler: { _ in self.shareFile(at: fileURL) }))
        
        if let popoverController = menu.popoverPresentationController {
            popoverController.sourceView = self.view
            popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
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
        showInputAlert(title: "New Folder", message: "Enter folder name", actionTitle: "Create") { folderName in
            let folderURL = self.documentsDirectory.appendingPathComponent(folderName)
            do {
                try self.fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)
                self.loadFiles()
            } catch {
                self.handleError(error, withTitle: "Creating Folder")
            }
        }
    }
    
    private func createNewFile() {
        showInputAlert(title: "New File", message: "Enter file name", actionTitle: "Create") { fileName in
            let fileURL = self.documentsDirectory.appendingPathComponent(fileName)
            self.fileManager.createFile(atPath: fileURL.path, contents: nil, attributes: nil)
            self.loadFiles()
        }
    }
    
    private func renameFile(at fileURL: URL) {
        showInputAlert(title: "Rename File", message: "Enter new file name", actionTitle: "Rename", initialText: fileURL.lastPathComponent) { newName in
            let destinationURL = fileURL.deletingLastPathComponent().appendingPathComponent(newName)
            self.activityIndicator.startAnimating()
            DispatchQueue.global().async {
                do {
                    try self.fileManager.moveItem(at: fileURL, to: destinationURL)
                    DispatchQueue.main.async {
                        self.activityIndicator.stopAnimating()
                        self.loadFiles()
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.activityIndicator.stopAnimating()
                        self.handleError(error, withTitle: "Renaming File")
                    }
                }
            }
        }
    }
    
    private func deleteFile(at fileURL: URL) {
        activityIndicator.startAnimating()
        DispatchQueue.global().async {
            do {
                try self.fileManager.removeItem(at: fileURL)
                DispatchQueue.main.async {
                    self.activityIndicator.stopAnimating()
                    self.loadFiles()
                }
            } catch {
                DispatchQueue.main.async {
                    self.activityIndicator.stopAnimating()
                    self.handleError(error, withTitle: "Deleting File")
                }
            }
        }
    }

    private func unzipFile(at fileURL: URL) {
        let destinationURL = fileURL.deletingLastPathComponent().appendingPathComponent("extracted")
        activityIndicator.startAnimating()
        DispatchQueue.global().async {
            do {
                try self.fileManager.unzipItem(at: fileURL, to: destinationURL)
                DispatchQueue.main.async {
                    self.activityIndicator.stopAnimating()
                    self.loadFiles()
                }
            } catch {
                DispatchQueue.main.async {
                    self.activityIndicator.stopAnimating()
                    self.handleError(error, withTitle: "Unzipping File")
                }
            }
        }
    }
    
    private func shareFile(at fileURL: URL) {
        let activityController = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
        present(activityController, animated: true, completion: nil)
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

    // MARK: - UIDocumentPickerViewControllerDelegate
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let selectedFileURL = urls.first else {
            return
        }
        let destinationURL = documentsDirectory.appendingPathComponent(selectedFileURL.lastPathComponent)
        do {
            try fileManager.copyItem(at: selectedFileURL, to: destinationURL)
            loadFiles()
        } catch {
            handleError(error, withTitle: "Importing File")
        }
    }

    // MARK: - UISearchResultsUpdating
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text else { return }
        filteredFileList = fileList.filter { $0.localizedCaseInsensitiveContains(searchText) }
        HomeViewUI.fileListTableView.reloadData()
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

    // MARK: - Helper Methods
    private func createFilesDirectoryIfNeeded(at directory: URL) {
        do {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
        } catch {
            handleError(error, withTitle: "Creating Files Directory")
        }
    }

    private func presentAlert(title: String, message: String, buttonTitle: String = "OK", handler: ((UIAlertAction) -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: buttonTitle, style: .default, handler: handler)
        alert.addAction(action)
        
        if handler != nil {
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        }
        
        present(alert, animated: true, completion: nil)
    }

    private func showInputAlert(title: String, message: String, actionTitle: String, initialText: String = "", completion: @escaping (String) -> Void) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.text = initialText
        }
        let confirmAction = UIAlertAction(title: actionTitle, style: .default) { [weak alertController] _ in
            guard let textField = alertController?.textFields?.first, let text = textField.text else { return }
            completion(text)
        }
        alertController.addAction(confirmAction)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }

    private func handleError(_ error: Error, withTitle title: String = "Error") {
        presentAlert(title: title, message: "An error occurred: \(error.localizedDescription)")
    }
}