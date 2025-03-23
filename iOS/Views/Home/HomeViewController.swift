import UIKit
import ZIPFoundation

class HomeViewController: UIViewController, UISearchResultsUpdating, UIScrollViewDelegate, UITableViewDataSource, UITableViewDelegate, UITableViewDragDelegate, UITableViewDropDelegate, UIDocumentPickerDelegate, FileHandlingDelegate {
    
    var fileList: [String] = []
    var filteredFileList: [String] = []
    let fileManager = FileManager.default
    let searchController = UISearchController(searchResultsController: nil)
    var sortOrder: SortOrder = .name
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
    
    var activityIndicator: UIActivityIndicatorView {
        return HomeViewUI.activityIndicator
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActivityIndicator()
        loadFiles()
        configureTableView()
    }
    
    func setupUI() {
        view.backgroundColor = .systemBackground
        
        let navItem = UINavigationItem(title: "Files")
        let menuButton = UIBarButtonItem(image: UIImage(systemName: "ellipsis.circle"), style: .plain, target: self, action: #selector(showMenu))
        let uploadButton = UIBarButtonItem(customView: HomeViewUI.uploadButton)
        let addButton = UIBarButtonItem(image: UIImage(systemName: "folder.badge.plus"), style: .plain, target: self, action: #selector(addDirectory))
        
        HomeViewUI.uploadButton.addTarget(self, action: #selector(importFile), for: .touchUpInside)
        navItem.rightBarButtonItems = [menuButton, uploadButton, addButton]
        HomeViewUI.navigationBar.setItems([navItem], animated: false)
        view.addSubview(HomeViewUI.navigationBar)
        
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search Files"
        navigationItem.searchController = searchController
        definesPresentationContext = true
        
        view.addSubview(HomeViewUI.fileListTableView)
        NSLayoutConstraint.activate([
            HomeViewUI.navigationBar.topAnchor.constraint(equalTo: view.topAnchor),
            HomeViewUI.navigationBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            HomeViewUI.navigationBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            HomeViewUI.fileListTableView.topAnchor.constraint(equalTo: HomeViewUI.navigationBar.bottomAnchor),
            HomeViewUI.fileListTableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            HomeViewUI.fileListTableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            HomeViewUI.fileListTableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    func setupActivityIndicator() {
        view.addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    func configureTableView() {
        HomeViewUI.fileListTableView.delegate = self
        HomeViewUI.fileListTableView.dataSource = self
        HomeViewUI.fileListTableView.dragDelegate = self
        HomeViewUI.fileListTableView.dropDelegate = self
        HomeViewUI.fileListTableView.register(FileTableViewCell.self, forCellReuseIdentifier: "FileCell")
    }
    
    func createFilesDirectoryIfNeeded(at directory: URL) {
        if !fileManager.fileExists(atPath: directory.path) {
            do {
                try fileManager.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Error creating directory: \(error)")
                utilities.handleError(in: self, error: error, withTitle: "Directory Creation Error")
            }
        }
    }
    
    func loadFiles() {
        activityIndicator.startAnimating()
        DispatchQueue.global().async {
            do {
                let files = try self.fileManager.contentsOfDirectory(at: self.documentsDirectory, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
                DispatchQueue.main.async {
                    self.fileList = files.map { $0.lastPathComponent }
                    self.sortFiles()
                    self.HomeViewUI.fileListTableView.reloadData()
                    self.activityIndicator.stopAnimating()
                }
            } catch {
                print("Error loading files: \(error)")
                DispatchQueue.main.async {
                    self.activityIndicator.stopAnimating()
                    self.utilities.handleError(in: self, error: error, withTitle: "File Load Error")
                }
            }
        }
    }
    
    @objc func importFile() {
        fileHandlers.uploadFile(viewController: self)
    }
    
    func handleImportedFile(url: URL) {
        let destinationURL = documentsDirectory.appendingPathComponent(url.lastPathComponent)
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                if url.startAccessingSecurityScopedResource() {
                    if url.pathExtension == "zip" {
                        try self.fileManager.unzipItem(at: url, to: destinationURL.deletingLastPathComponent(), progress: nil)
                    } else {
                        try self.fileManager.copyItem(at: url, to: destinationURL)
                    }
                    url.stopAccessingSecurityScopedResource()
                    DispatchQueue.main.async {
                        self.loadFiles()
                        HapticFeedbackGenerator.generateNotificationFeedback(type: .success)
                    }
                }
            } catch {
                print("Error handling file: \(error)")
                DispatchQueue.main.async {
                    self.utilities.handleError(in: self, error: error, withTitle: "File Import Error")
                }
            }
        }
    }
    
    func deleteFile(at index: Int) {
        let fileToDelete = fileList[index]
        let fileURL = documentsDirectory.appendingPathComponent(fileToDelete)
        do {
            try fileManager.removeItem(at: fileURL)
            fileList.remove(at: index)
            HomeViewUI.fileListTableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .fade)
            HapticFeedbackGenerator.generateNotificationFeedback(type: .success)
        } catch {
            print("Error deleting file: \(error)")
            utilities.handleError(in: self, error: error, withTitle: "File Delete Error")
        }
    }
    
    func sortFiles() {
        switch sortOrder {
        case .name:
            fileList.sort { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
        case .date:
            fileList.sort { (file1, file2) in
                let url1 = documentsDirectory.appendingPathComponent(file1)
                let url2 = documentsDirectory.appendingPathComponent(file2)
                let date1 = File(url: url1).date
                let date2 = File(url: url2).date
                return date1 > date2
            }
        case .size:
            fileList.sort { (file1, file2) in
                let url1 = documentsDirectory.appendingPathComponent(file1)
                let url2 = documentsDirectory.appendingPathComponent(file2)
                let size1 = File(url: url1).size
                let size2 = File(url: url2).size
                return size1 > size2
            }
        }
    }
    
    @objc func showMenu() {
        let alertController = UIAlertController(title: "Sort By", message: nil, preferredStyle: .actionSheet)
        
        let sortByNameAction = UIAlertAction(title: "Name", style: .default) { _ in
            self.sortOrder = .name
            self.sortFiles()
            self.HomeViewUI.fileListTableView.reloadData()
        }
        alertController.addAction(sortByNameAction)
        
        let sortByDateAction = UIAlertAction(title: "Date", style: .default) { _ in
            self.sortOrder = .date
            self.sortFiles()
            self.HomeViewUI.fileListTableView.reloadData()
        }
        alertController.addAction(sortByDateAction)
        
        let sortBySizeAction = UIAlertAction(title: "Size", style: .default) { _ in
            self.sortOrder = .size
            self.sortFiles()
            self.HomeViewUI.fileListTableView.reloadData()
        }
        alertController.addAction(sortBySizeAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text else { return }
        filteredFileList = fileList.filter { $0.localizedCaseInsensitiveContains(searchText) }
        HomeViewUI.fileListTableView.reloadData()
    }
    
    @objc func addDirectory() {
        let alertController = UIAlertController(title: "Add Directory", message: "Enter the name of the new directory", preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.placeholder = "Directory Name"
        }
        
        let createAction = UIAlertAction(title: "Create", style: .default) { _ in
            guard let textField = alertController.textFields?.first,
                  let directoryName = textField.text,
                  !directoryName.isEmpty else { return }
            
            let newDirectoryURL = self.documentsDirectory.appendingPathComponent(directoryName)
            do {
                try self.fileManager.createDirectory(at: newDirectoryURL, withIntermediateDirectories: false, attributes: nil)
                self.loadFiles()
                HapticFeedbackGenerator.generateNotificationFeedback(type: .success)
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
    
    func showFileOptions(for fileURL: URL) {
        let alertController = UIAlertController(title: "File Options", message: fileURL.lastPathComponent, preferredStyle: .actionSheet)
        
        let openAction = UIAlertAction(title: "Open", style: .default) { _ in
            let fileExtension = fileURL.pathExtension.lowercased()
            if ["txt", "md"].contains(fileExtension) {
                let textEditor = TextEditorViewController(fileURL: fileURL)
                self.navigationController?.pushViewController(textEditor, animated: true)
            } else {
                FileOperations.hexEditFile(at: fileURL, in: self)
            }
        }
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { _ in
            if let index = self.fileList.firstIndex(of: fileURL.lastPathComponent) {
                self.deleteFile(at: index)
            }
        }
        let shareAction = UIAlertAction(title: "Share", style: .default) { _ in
            self.fileHandlers.shareFile(viewController: self, fileURL: fileURL)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(openAction)
        alertController.addAction(deleteAction)
        alertController.addAction(shareAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)?) {
        present(viewControllerToPresent, animated: flag, completion: completion)
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