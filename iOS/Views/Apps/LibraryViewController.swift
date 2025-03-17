import UIKit

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
        
        // Setting background color using hex initializer
        self.view.backgroundColor = UIColor(hex: "#F0F0F0") // Example hex color
    }
    
    @objc func handleInstallNotification(_ notification: Notification) {
        if let userInfo = notification.userInfo,
           let app = userInfo["app"] as? DownloadedApps {
            if let filePath = app.value(forKey: "filePath") as? String {
                DispatchQueue.main.async {
                    self.startInstallProcess(meow: app, filePath: filePath)
                }
            }
        }
    }
    
    fileprivate func setupNavigation() {
        navigationItem.title = "Library"
        navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    fileprivate func setupSearchController() {
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search Apps..."
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isFiltering() {
            return section == 0 ? filteredSignedApps.count : filteredDownloadedApps.count
        }
        return section == 0 ? signedApps?.count ?? 0 : downloadedApps?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RoundedBackgroundCell", for: indexPath) as! AppsTableViewCell
        
        let app = isFiltering()
            ? (indexPath.section == 0 ? filteredSignedApps[indexPath.row] : filteredDownloadedApps[indexPath.row])
            : (indexPath.section == 0 ? signedApps?[indexPath.row] : downloadedApps?[indexPath.row])
        
        if let app = app {
            let filePath = app.value(forKey: "filePath") as? String ?? ""
            cell.configure(with: app, filePath: URL(fileURLWithPath: filePath))
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? "Signed Apps" : "Downloaded Apps"
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let app = isFiltering()
            ? (indexPath.section == 0 ? filteredSignedApps[indexPath.row] : filteredDownloadedApps[indexPath.row])
            : (indexPath.section == 0 ? signedApps?[indexPath.row] : downloadedApps?[indexPath.row])
        
        if let app = app {
            popupVC = PopupViewController()
            
            if indexPath.section == 0 {
                // Handle Signed Apps action
                let button1 = PopupViewController.PopupButton(
                    title: "Sign",
                    style: .default,
                    handler: {
                        self.startSigning(meow: app)
                    }
                )
                
                popupVC.configureButtons([button1])
                
                if let presentationController = popupVC.presentationController as? UISheetPresentationController {
                    presentationController.detents = [
                        .medium()
                    ]
                    presentationController.prefersGrabberVisible = true
                }
                
                self.present(popupVC, animated: true)
                
            } else {
                // Handle Downloaded Apps actions
                let button1 = PopupViewController.PopupButton(
                    title: "Install",
                    style: .default,
                    handler: {
                        if let filePath = self.getApplicationFilePath(with: app, row: indexPath.row, section: indexPath.section) {
                            let alertController = UIAlertController(
                                title: "Install App",
                                message: "Are you sure you want to install this app?",
                                preferredStyle: .alert
                            )

                            let confirmAction = UIAlertAction(
                                title: "Install",
                                style: .default,
                                handler: { _ in
                                    self.startInstallProcess(meow: app, filePath: filePath.path)
                                }
                            )

                            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)

                            alertController.addAction(confirmAction)
                            alertController.addAction(cancelAction)

                            // Example of updating the alert view colors
                            alertController.view.tintColor = UIColor(hex: "#FF5733") // Example hex color

                            self.present(alertController, animated: true, completion: nil)
                        }
                    }
                )
                
                let button2 = PopupViewController.PopupButton(
                    title: "Share",
                    style: .default,
                    handler: {
                        if let filePath = self.getApplicationFilePath(with: app, row: indexPath.row, section: indexPath.section) {
                            self.shareFile(meow: app, filePath: filePath.path)
                        }
                    }
                )
                
                popupVC.configureButtons([button1, button2])
                
                if let presentationController = popupVC.presentationController as? UISheetPresentationController {
                    presentationController.detents = [
                        .medium(),
                        .large()
                    ]
                    presentationController.prefersGrabberVisible = true
                }
                
                self.present(popupVC, animated: true)
            }
        }
    }
    
    // Placeholder methods for undefined functions in this context
    func getApplication(row: Int, section: Int) -> Any? { return nil }
    func getApplicationFilePath(with source: Any, row: Int, section: Int, getuuidonly: Bool = false) -> URL? { return nil }
    func startInstallProcess(meow: Any, filePath: String) {}
    func shareFile(meow: Any, filePath: String) {}
    func startSigning(meow: Any) {}
    @objc func afetch() {}
    func presentLoader() -> UIAlertController? { return nil }
}

extension LibraryViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text!)
    }
    
    public func fetchSources() {
        // Fetch Signed Apps
        let signedAppsFetchRequest: NSFetchRequest<SignedApps> = SignedApps.fetchRequest()
        do {
            signedApps = try CoreDataManager.shared.context.fetch(signedAppsFetchRequest)
        } catch {
            print("Failed to fetch signed apps: \(error)")
        }
        
        // Fetch Downloaded Apps
        let downloadedAppsFetchRequest: NSFetchRequest<DownloadedApps> = DownloadedApps.fetchRequest()
        do {
            downloadedApps = try CoreDataManager.shared.context.fetch(downloadedAppsFetchRequest)
        } catch {
            print("Failed to fetch downloaded apps: \(error)")
        }
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
            self.loaderAlert?.dismiss(animated: true, completion: nil)
        }
    }
    
    fileprivate func isFiltering() -> Bool {
        return searchController.isActive && !searchBarIsEmpty()
    }
    
    fileprivate func searchBarIsEmpty() -> Bool {
        return searchController.searchBar.text?.isEmpty ?? true
    }
    
    fileprivate func filterContentForSearchText(_ searchText: String, scope: String = "All") {
        filteredSignedApps = signedApps?.filter { app in
            return app.name?.lowercased().contains(searchText.lowercased()) ?? false
        } ?? []
        
        filteredDownloadedApps = downloadedApps?.filter { app in
            return app.name?.lowercased().contains(searchText.lowercased()) ?? false
        } ?? []
        
        tableView.reloadData()
    }
}