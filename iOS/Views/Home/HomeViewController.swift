import UIKit
import ZIPFoundation

class HomeViewController: UIViewController, UIDocumentPickerDelegate, UISearchResultsUpdating, UITableViewDragDelegate, UITableViewDropDelegate, UITableViewDelegate, UITableViewDataSource {
    
    // MARK: - Properties
    private var fileList: [String] = []
    private var filteredFileList: [String] = []
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
        let menuButton = UIBarButtonItem(image: UIImage(systemName: "ellipsis.circle"), style: .plain, target: self, action: #selector(showMenu))
        let sortButton = UIBarButtonItem(title: "Sort", style: .plain, target: self, action: #selector(changeSortOrder))
        navItem.rightBarButtonItems = [menuButton, sortButton]
        navigationController?.navigationBar.setItems([navItem], animated: false)
        
        view.addSubview(fileListTableView)
        view.addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            fileListTableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            fileListTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            fileListTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            fileListTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        fileListTableView.register(UITableViewCell.self, forCellReuseIdentifier: "FileCell")
    }
    
    private func setupActivityIndicator() {
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
    }
    
    private func configureTableView() {
        fileListTableView.delegate = self
        fileListTableView.dataSource = self
        fileListTableView.dragDelegate = self
        fileListTableView.dropDelegate = self
        searchController.searchResultsUpdater = self
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        filteredFileList = fileList
    }
    
    // MARK: - Load Files
    func loadFiles() {
        activityIndicator.startAnimating()
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
                case "Import": self.fileHandlers.importFile(viewController: self)
                case "New Folder": 
                    self.showInputAlert(title: "New Folder", message: "Enter folder name", actionTitle: "Create") { folderName in
                        self.fileHandlers.createNewFolder(viewController: self, folderName: folderName)
                    }
                case "New File": 
                    self.showInputAlert(title: "New File", message: "Enter file name", actionTitle: "Create") { fileName in
                        self.fileHandlers.createNewFile(viewController: self, fileName: fileName)
                    }
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
    
    private func selectFiles() {
        // Implement select files functionality
    }
    
    @objc private func uploadFile() {
        fileHandlers.uploadFile(viewController: self)
    }
    
    private func createFilesDirectoryIfNeeded(at directory: URL) {
        do {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
        } catch {
            handleError(error, withTitle: "Creating Files Directory")
        }
    }
    
    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredFileList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FileCell", for: indexPath)
        cell.textLabel?.text = filteredFileList[indexPath.row]
        return cell
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

// Extension methods for HomeViewController
extension HomeViewController {
    func presentAlert(title: String, message: String, buttonTitle: String = "OK", handler: ((UIAlertAction) -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: buttonTitle, style: .default, handler: handler)
        alert.addAction(action)

        if handler != nil {
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        }

        present(alert, animated: true, completion: nil)
    }

    func showInputAlert(title: String, message: String, actionTitle: String, initialText: String = "", completion: @escaping (String) -> Void) {
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

    func handleError(_ error: Error, withTitle title: String = "Error") {
        presentAlert(title: title, message: "An error occurred: \(error.localizedDescription)")
    }
}