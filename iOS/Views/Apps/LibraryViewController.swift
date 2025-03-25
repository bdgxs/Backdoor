import UIKit
import CoreData
import UniformTypeIdentifiers

class PopupViewControllerButton: PopupViewController.PopupButton {
    var onButtonTap: (() -> Void)?

    init(title: String, color: UIColor, titleColor: UIColor = .white) {
        super.init(title: title, color: color, titleColor: titleColor)
        self.addTarget(self, action: #selector(buttonTappedAction), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func buttonTappedAction() {
        onButtonTap?()
    }
}

class LibraryViewController: UITableViewController {
    var signedApps: [SignedApps]?
    var downloadedApps: [DownloadedApps]?
    
    var filteredSignedApps: [SignedApps] = []
    var filteredDownloadedApps: [DownloadedApps] = []
    
    var installer: Installer?
    
    public var searchController: UISearchController!
    var popupVC: PopupViewController!
    var loaderAlert: UIAlertController?
    
    init() { super.init(style: .grouped) }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupSearchController()
        fetchSources()
        loaderAlert = presentLoader()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavigation()
    }
    
    fileprivate func setupViews() {
        self.tableView.dataSource = self
        self.tableView.delegate = self
        tableView.register(AppsTableViewCell.self, forCellReuseIdentifier: "RoundedBackgroundCell")
        NotificationCenter.default.addObserver(self, selector: #selector(afetch), name: Notification.Name("lfetch"), object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInstallNotification(_:)),
            name: Notification.Name("InstallDownloadedApp"),
            object: nil
        )
    }
    
    @objc private func handleInstallNotification(_ notification: Notification) {
        guard let downloadedApp = notification.userInfo?["downloadedApp"] as? DownloadedApps else { return }
        
        let signingDataWrapper = SigningDataWrapper(signingOptions: UserDefaults.standard.signingOptions)
        signingDataWrapper.signingOptions.installAfterSigned = true
        
        let ap = SigningsViewController(
            signingDataWrapper: signingDataWrapper,
            application: downloadedApp,
            appsViewController: self
        )
        
        ap.signingCompletionHandler = { success in
            if success {
                Debug.shared.log(message: "Signing completed successfully", type: .success)
            }
        }
        
        let navigationController = UINavigationController(rootViewController: ap)
        navigationController.shouldPresentFullScreen()
        
        present(navigationController, animated: true)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: Notification.Name("lfetch"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("InstallDownloadedApp"), object: nil)
    }
    
    fileprivate func setupNavigation() {
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.title = String.localized("TAB_LIBRARY")
    }
    
    private func handleAppUpdate(for signedApp: SignedApps) {
        guard let sourceURL = signedApp.originalSourceURL else {
            Debug.shared.log(message: "Missing update version or source URL", type: .error)
            return
        }
        
        Debug.shared.log(message: "Fetching update from source: \(sourceURL.absoluteString)", type: .info)
        
        present(loaderAlert!, animated: true)
        
        if isDebugMode {
            let mockSource = SourceRefreshOperation()
            mockSource.createMockSource { mockSourceData in
                if let sourceData = mockSourceData {
                    self.handleSourceData(sourceData, for: signedApp)
                } else {
                    Debug.shared.log(message: "Failed to create mock source", type: .error)
                    DispatchQueue.main.async {
                        self.loaderAlert?.dismiss(animated: true)
                    }
                }
            }
        } else {
            SourceGET().downloadURL(from: sourceURL) { [weak self] result in
                guard let self = self else { return }
                
                switch result {
                case .success((let data, _)):
                    if case .success(let sourceData) = SourceGET().parse(data: data) {
                        self.handleSourceData(sourceData, for: signedApp)
                    } else {
                        Debug.shared.log(message: "Failed to parse source data", type: .error)
                        DispatchQueue.main.async {
                            self.loaderAlert?.dismiss(animated: true)
                        }
                    }
                case .failure(let error):
                    Debug.shared.log(message: "Failed to fetch source: \(error)", type: .error)
                    DispatchQueue.main.async {
                        self.loaderAlert?.dismiss(animated: true)
                    }
                }
            }
        }
    }
    
    private func handleSourceData(_ sourceData: SourcesData, for signedApp: SignedApps) {
        guard let bundleId = signedApp.bundleidentifier,
              let updateVersion = signedApp.updateVersion,
              let app = sourceData.apps.first(where: { $0.bundleIdentifier == bundleId }),
              let versions = app.versions else {
            Debug.shared.log(message: "Failed to find app in source", type: .error)
            DispatchQueue.main.async {
                self.loaderAlert?.dismiss(animated: true)
            }
            return
        }
        
        for version in versions {
            if version.version == updateVersion {
                Debug.shared.log(message: "Found matching version: \(version.version)", type: .info)
                
                let uuid = UUID().uuidString
                
                DispatchQueue.global(qos: .background).async {
                    do {
                        let tempDirectory = FileManager.default.temporaryDirectory
                        let destinationURL = tempDirectory.appendingPathComponent("\(uuid).ipa")
                        
                        if let data = try? Data(contentsOf: version.downloadURL) {
                            try data.write(to: destinationURL)
                            
                            let dl = AppDownload()
                            try handleIPAFile(destinationURL: destinationURL, uuid: uuid, dl: dl)
                            
                            DispatchQueue.main.async {
                                self.loaderAlert?.dismiss(animated: true) {
                                    let downloadedApps = CoreDataManager.shared.getDatedDownloadedApps()
                                    if let downloadedApp = downloadedApps.first(where: { $0.uuid == uuid }) {
                                        let signingDataWrapper = SigningDataWrapper(signingOptions: UserDefaults.standard.signingOptions)
                                        signingDataWrapper.signingOptions.installAfterSigned = true
                                        
                                        let originalSignedApp = signedApp
                                        
                                        let ap = SigningsViewController(
                                            signingDataWrapper: signingDataWrapper,
                                            application: downloadedApp,
                                            appsViewController: self
                                        )
                                        
                                        ap.signingCompletionHandler = { [weak self] success in
                                            if success {
                                                CoreDataManager.shared.deleteAllSignedAppContent(for: originalSignedApp)
                                                self?.fetchSources()
                                                self?.tableView.reloadData()
                                            }
                                        }
                                        
                                        let navigationController = UINavigationController(rootViewController: ap)
                                        navigationController.shouldPresentFullScreen()
                                        self.present(navigationController, animated: true)
                                    }
                                }
                            }
                        }
                    } catch {
                        Debug.shared.log(message: "Error downloading or saving IPA: \(error)", type: .error)
                        DispatchQueue.main.async {
                            self.loaderAlert?.dismiss(animated: true)
                        }
                    }
                }
                return
            }
        }
        
        Debug.shared.log(message: "No matching version found in source", type: .error)
        DispatchQueue.main.async {
            self.loaderAlert?.dismiss(animated: true)
        }
    }
}

// MARK: - UITableView Data Source & Delegate
extension LibraryViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return isFiltering ? filteredSignedApps.count : signedApps?.count ?? 0
        case 1: return isFiltering ? filteredDownloadedApps.count : downloadedApps?.count ?? 0
        default: return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return signedApps?.isEmpty == false ? "Signed Apps" : nil
        case 1: return downloadedApps?.isEmpty == false ? "Downloaded Apps" : nil
        default: return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 72
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RoundedBackgroundCell", for: indexPath) as! AppsTableViewCell
        var app: Any?
        
        switch indexPath.section {
        case 0:
            app = isFiltering ? filteredSignedApps[indexPath.row] : signedApps?[indexPath.row]
            if let signedApp = app as? SignedApps {
                let filePath = signedApp.filePath ?? AppDelegate.getDocumentsDirectory().appendingPathComponent("placeholder")
                cell.configure(with: signedApp, filePath: filePath)
            }
        case 1:
            app = isFiltering ? filteredDownloadedApps[indexPath.row] : downloadedApps?[indexPath.row]
            if let downloadedApp = app as? DownloadedApps {
                let filePath = downloadedApp.filePath ?? AppDelegate.getDocumentsDirectory().appendingPathComponent("placeholder")
                cell.configure(with: downloadedApp, filePath: filePath)
            }
        default:
            break
        }
        
        cell.selectionStyle = .none
        cell.backgroundColor = .clear
        return cell
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        var actions: [UIContextualAction] = []
        
        switch indexPath.section {
        case 0:
            guard let signedApp = (isFiltering ? filteredSignedApps : signedApps)?[indexPath.row] else { return nil }
            
            let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (_, _, completion) in
                CoreDataManager.shared.deleteAllSignedAppContent(for: signedApp)
                self?.fetchSources()
                self?.tableView.reloadData()
                completion(true)
            }
            
            let resignAction = UIContextualAction(style: .normal, title: "Resign") { [weak self] (_, _, completion) in
                guard let self = self else { return }
                let signingDataWrapper = SigningDataWrapper(signingOptions: UserDefaults.standard.signingOptions)
                let ap = SigningsViewController(signingDataWrapper: signingDataWrapper, application: signedApp, appsViewController: self)
                let navigationController = UINavigationController(rootViewController: ap)
                navigationController.shouldPresentFullScreen()
                self.present(navigationController, animated: true)
                completion(true)
            }
            resignAction.backgroundColor = .systemBlue
            
            if signedApp.updateVersion != nil {
                let updateAction = UIContextualAction(style: .normal, title: "Update") { [weak self] (_, _, completion) in
                    self?.handleAppUpdate(for: signedApp)
                    completion(true)
                }
                updateAction.backgroundColor = .systemGreen
                actions.append(updateAction)
            }
            
            actions.append(contentsOf: [resignAction, deleteAction])
            
        case 1:
            guard let downloadedApp = (isFiltering ? filteredDownloadedApps : downloadedApps)?[indexPath.row] else { return nil }
            
            let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (_, _, completion) in
                CoreDataManager.shared.deleteAllDownloadedAppContent(for: downloadedApp)
                self?.fetchSources()
                self?.tableView.reloadData()
                completion(true)
            }
            
            let installAction = UIContextualAction(style: .normal, title: "Install") { [weak self] (_, _, completion) in
                guard let self = self else { return }
                let signingDataWrapper = SigningDataWrapper(signingOptions: UserDefaults.standard.signingOptions)
                signingDataWrapper.signingOptions.installAfterSigned = true
                let ap = SigningsViewController(signingDataWrapper: signingDataWrapper, application: downloadedApp, appsViewController: self)
                let navigationController = UINavigationController(rootViewController: ap)
                navigationController.shouldPresentFullScreen()
                self.present(navigationController, animated: true)
                completion(true)
            }
            installAction.backgroundColor = .systemBlue
            
            actions.append(contentsOf: [installAction, deleteAction])
        default:
            return nil
        }
        
        return UISwipeActionsConfiguration(actions: actions)
    }
    
    override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        switch indexPath.section {
        case 0:
            guard let signedApp = (isFiltering ? filteredSignedApps : signedApps)?[indexPath.row],
                  let filePath = signedApp.filePath else { return nil }
            
            return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
                UIMenu(children: [
                    UIAction(title: "Share", image: UIImage(systemName: "square.and.arrow.up")) { [weak self] _ in
                        self?.shareFile(at: filePath.path)
                    }
                ])
            }
        case 1:
            guard let downloadedApp = (isFiltering ? filteredDownloadedApps : downloadedApps)?[indexPath.row],
                  let filePath = downloadedApp.filePath else { return nil }
            
            return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
                UIMenu(children: [
                    UIAction(title: "Share", image: UIImage(systemName: "square.and.arrow.up")) { [weak self] _ in
                        self?.shareFile(at: filePath.path)
                    }
                ])
            }
        default:
            return nil
        }
    }
}

// MARK: - Fetching Sources
extension LibraryViewController {
    @objc func afetch() {
        fetchSources()
    }
    
    func fetchSources() {
        signedApps = CoreDataManager.shared.getDatedSignedApps()
        downloadedApps = CoreDataManager.shared.getDatedDownloadedApps()
        
        DispatchQueue.main.async {
            self.loaderAlert?.dismiss(animated: true)
            self.tableView.reloadData()
        }
    }
}

// MARK: - Search Controller
extension LibraryViewController: UISearchControllerDelegate, UISearchBarDelegate {
    func setupSearchController() {
        self.searchController = UISearchController(searchResultsController: nil)
        self.searchController.obscuresBackgroundDuringPresentation = false
        self.searchController.hidesNavigationBarDuringPresentation = true
        self.searchController.searchResultsUpdater = self
        self.searchController.delegate = self
        self.searchController.searchBar.placeholder = String.localized("LIBRARY_VIEW_CONTROLLER_SEARCH")
        self.navigationItem.searchController = searchController
        self.definesPresentationContext = true
        self.navigationItem.hidesSearchBarWhenScrolling = false
    }
    
    var isFiltering: Bool { searchController.isActive && !isSearchBarEmpty }
    var isSearchBarEmpty: Bool { searchController.searchBar.text?.isEmpty ?? true }
}

// MARK: - UISearchResultsUpdating
extension LibraryViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        let searchText = searchController.searchBar.text?.lowercased() ?? ""
        filteredSignedApps = signedApps?.filter { $0.name?.lowercased().contains(searchText) == true } ?? []
        filteredDownloadedApps = downloadedApps?.filter { $0.name?.lowercased().contains(searchText) == true } ?? []
        tableView.reloadData()
    }
}

// MARK: - Helper Methods
extension LibraryViewController {
    private func presentLoader() -> UIAlertController {
        let alert = UIAlertController(title: nil, message: "Please wait...", preferredStyle: .alert)
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.style = .medium
        loadingIndicator.startAnimating()
        alert.view.addSubview(loadingIndicator)
        return alert
    }
    
    private func shareFile(at filePath: String) {
        let activityVC = UIActivityViewController(activityItems: [URL(fileURLWithPath: filePath)], applicationActivities: nil)
        present(activityVC, animated: true)
    }
    
    private var isDebugMode: Bool {
        var isDebug = false
        assert({ isDebug = true; return true }())
        return isDebug
    }
}