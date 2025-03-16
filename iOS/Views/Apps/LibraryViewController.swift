import Foundation
import CoreData
import UniformTypeIdentifiers

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
        
        // Create mock source if in debug mode
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
            // Normal source fetch
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
        
        // Look for the version that matches our update version
        for version in versions {
            if version.version == updateVersion {
                // Found the matching version
                Debug.shared.log(message: "Found matching version: \(version.version)", type: .info)
                
                let uuid = UUID().uuidString
                
                DispatchQueue.global(qos: .background).async {
                    do {
                        let tempDirectory = FileManager.default.temporaryDirectory
                        let destinationURL = tempDirectory.appendingPathComponent("\(uuid).ipa")
                        
                        // Download the file
                        if let data = try? Data(contentsOf: version.downloadURL) {
                            try data.write(to: destinationURL)
                            
                            let dl = AppDownload()
                            try handleIPAFile(destinationURL: destinationURL, uuid: uuid, dl: dl)
                            
                            DispatchQueue.main.async {
                                self.loaderAlert?.dismiss(animated: true) {
                                    // Force Sign & Install
                                    let downloadedApps = CoreDataManager.shared.getDatedDownloadedApps()
                                    if let downloadedApp = downloadedApps.first(where: { $0.uuid == uuid }) {
                                        let signingDataWrapper = SigningDataWrapper(signingOptions: UserDefaults.standard.signingOptions)
                                        signingDataWrapper.signingOptions.installAfterSigned = true
                                        
                                        // Store the original signed app for deletion after update
                                        let originalSignedApp = signedApp
                                        
                                        let ap = SigningsViewController(
                                            signingDataWrapper: signingDataWrapper,
                                            application: downloadedApp,
                                            appsViewController: self
                                        )
                                        
                                        // Add completion handler to delete the original app after successful signing
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
                        Debug.shared.log(message: "Failed to handle update: \(error)", type: .error)
                        DispatchQueue.main.async {
                            self.loaderAlert?.dismiss(animated: true)
                        }
                    }
                }
                return
            }
        }
        
        Debug.shared.log(message: "Could not find version \(updateVersion) in source", type: .error)
        DispatchQueue.main.async {
            self.loaderAlert?.dismiss(animated: true)
        }
    }
    
    private var isDebugMode: Bool {
        var isDebug = false
        assert({
            isDebug = true
            return true
        }())
        return isDebug
    }
    
    private func resignApp(certificate: Certificate, appPath: URL, completion: @escaping (Bool) -> Void) {
        // Implement resignApp functionality here
    }
}

extension LibraryViewController {
    override func numberOfSections(in tableView: UITableView) -> Int { return 2 }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return isFiltering ? filteredSignedApps.count : signedApps?.count ?? 0
        case 1:
            return isFiltering ? filteredDownloadedApps.count : downloadedApps?.count ?? 0
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        switch section {
        case 0:
            let headerWithButton = GroupedSectionHeader(
                title: String.localized("LIBRARY_VIEW_CONTROLLER_SECTION_TITLE_SIGNED_APPS"),
                subtitle: String.localized("LIBRARY_VIEW_CONTROLLER_SECTION_TITLE_SIGNED_APPS_TOTAL", arguments: String(signedApps?.count ?? 0)),
                buttonTitle: String.localized("LIBRARY_VIEW_CONTROLLER_SECTION_BUTTON_IMPORT"),
                buttonAction: {
                self.startImporting()
            })
            return headerWithButton
        case 1:
            
            let headerWithButton = GroupedSectionHeader(
                title: String.localized("LIBRARY_VIEW_CONTROLLER_SECTION_DOWNLOADED_APPS"),
                subtitle: String.localized("LIBRARY_VIEW_CONTROLLER_SECTION_TITLE_DOWNLOADED_APPS_TOTAL", arguments: String(downloadedApps?.count ?? 0))
            )
            
            return headerWithButton
        default:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = AppsTableViewCell(style: .subtitle, reuseIdentifier: "RoundedBackgroundCell")
        cell.selectionStyle = .default
        cell.accessoryType = .disclosureIndicator
        cell.backgroundColor = .clear
        let source = getApplication(row: indexPath.row, section: indexPath.section)
        let filePath = getApplicationFilePath(with: source!, row: indexPath.row, section: indexPath.section)
        
        
        if let iconURL = source!.value(forKey: "iconURL") as? String {
            let imagePath = filePath!.appendingPathComponent(iconURL)
            
            if let image = CoreDataManager.shared.loadImage(from: imagePath) {
                SectionIcons.sectionImage(to: cell, with: image)
            } else {
                SectionIcons.sectionImage(to: cell, with: UIImage(named: "unknown")!)
            }
        } else {
            SectionIcons.sectionImage(to: cell, with: UIImage(named: "unknown")!)
        }
        
        cell.configure(with: source!, filePath: filePath!)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let source = getApplication(row: indexPath.row, section: indexPath.section)
        let filePath = getApplicationFilePath(with: source!, row: indexPath.row, section: indexPath.section, getuuidonly: true)
        let filePath2 = getApplicationFilePath(with: source!, row: indexPath.row, section: indexPath.section, getuuidonly: false)
        let appName = "\((source!.value(forKey: "name") as? String ?? ""))"
        switch indexPath.section {
        case 0:
            if FileManager.default.fileExists(atPath: filePath2!.path) {
                popupVC = PopupViewController()
                popupVC.modalPresentationStyle = .pageSheet
                
                let hasUpdate = (source as? SignedApps)?.value(forKey: "hasUpdate") as? Bool ?? false
                
                if let signedApp = source as? SignedApps,
                   hasUpdate {
                    // Update available menu
                    let updateButton = PopupViewControllerButton(
                        title: String.localized("LIBRARY_VIEW_CONTROLLER_SIGN_ACTION_UPDATE", arguments: appName),
                        color: .tintColor.withAlphaComponent(0.9),
                        titleColor: .white
                    )
                    updateButton.onTap = { [weak self] in
                        guard let self = self else { return }
                        self.popupVC.dismiss(animated: true) {
                            self.handleAppUpdate(for: signedApp)
                        }
                    }
                    
                    let clearButton = PopupViewControllerButton(
                        title: String.localized("LIBRARY_VIEW_CONTROLLER_SIGN_ACTION_CLEAR_UPDATE"),
                        color: .quaternarySystemFill,
                        titleColor: .tintColor
                    )
                    clearButton.onTap = { [weak self] in
                        guard let self = self else { return }
                        self.popupVC.dismiss(animated: true)
                        CoreDataManager.shared.clearUpdateState(for: signedApp)
                        self.tableView.reloadRows(at: [indexPath], with: .none)
                    }
                    
                    popupVC.configureButtons([updateButton, clearButton])
                } else {
                    // Regular menu
                    let button1 = PopupViewControllerButton(
                        title: String.localized("LIBRARY_VIEW_CONTROLLER_SIGN_ACTION_INSTALL", arguments: appName),
                        color: .tintColor.withAlphaComponent(0.9)
                    )
                    button1.onTap = { [weak self] in
                        guard let self = self else { return }
                        self.popupVC.dismiss(animated: true)
                        self.startInstallProcess(meow: source!, filePath: filePath?.path ?? "")
                    }
                    
                    let button4 = PopupViewControllerButton(
                        title: String.localized("LIBRARY_VIEW_CONTROLLER_SIGN_ACTION_OPEN", arguments: appName),
                        color: .quaternarySystemFill,
                        titleColor: .tintColor
                    )
                    button4.onTap = { [weak self] in
                        guard let self = self else { return }
                        self.popupVC.dismiss(animated: true)
                        if let workspace = LSApplicationWorkspace.default() {
                            let success = workspace.openApplication(withBundleID: "\((source!.value(forKey: "bundleidentifier") as? String ?? ""))")
                            if !success {
                                Debug.shared.log(message: "Unable to open, do you have the app installed?", type: .warning)
                            }
                        }
                    }
                    
                    let button3 = PopupViewControllerButton(
                        title: String.localized("LIBRARY_VIEW_CONTROLLER_SIGN_ACTION_RESIGN", arguments: appName),
                        color: .quaternarySystemFill,
                        titleColor: .tintColor
                    )
                    button3.onTap = { [weak self] in
                        guard let self = self else { return }
                        self.popupVC.dismiss(animated: true) {
                            if let cert = CoreDataManager.shared.getCurrentCertificate() {
                                self.present(self.loaderAlert!, animated: true)
                                
                                self.resignApp(certificate: cert, appPath: filePath2!) { success in
                                    if success {
                                        CoreDataManager.shared.updateSignedApp(app: source as! SignedApps, newTimeToLive: (cert.certData?.expirationDate)!, newTeamName: (cert.certData?.name)!) { _ in
                                            DispatchQueue.main.async {
                                                self.loaderAlert?.dismiss(animated: true)
                                                Debug.shared.log(message: "Done action??")
                                                self.tableView.reloadRows(at: [indexPath], with: .left)
                                            }
                                        }
                                    } else {
                                        // Handle resigning failure
                                        self.loaderAlert?.dismiss(animated: true)
                                        Debug.shared.log(message: "Failed to resign the app", type: .error)
                                    }
                                }
                            } else {
                                let alert = UIAlertController(
                                    title: String.localized("APP_SIGNING_VIEW_CONTROLLER_NO_CERTS_ALERT_TITLE"),
                                    message: String.localized("APP_SIGNING_VIEW_CONTROLLER_NO_CERTS_ALERT_DESCRIPTION"),
                                    preferredStyle: .alert
                                )
                                alert.addAction(UIAlertAction(title: String.localized("LAME"), style: .default))
                                self.present(alert, animated: true)
                            }
                        }
                    }
                    
                    let button2 = PopupViewControllerButton(
                        title: String.localized("LIBRARY_VIEW_CONTROLLER_SIGN_ACTION_SHARE", arguments: appName),
                        color: .quaternarySystemFill,
                        titleColor: .tintColor
                    )
                    button2.onTap = { [weak self] in
                        guard let self = self else { return }
                        self.popupVC.dismiss(animated: true)
                        self.shareFile(meow: source!, filePath: filePath?.path ?? "")
                    }
                    
                    popupVC.configureButtons([button1, button4, button3, button2])
                }
                let detent2: UISheetPresentationController.Detent = ._detent(withIdentifier: "Test2", constant: hasUpdate ? 150.0 : 270.0)
                if let presentationController = popupVC.presentationController as? UISheetPresentationController {
                    presentationController.detents = [
                        detent2,
                        .medium()
                    ]
                    presentationController.prefersGrabberVisible = true
                }
                
                self.present(popupVC, animated: true)
            } else {
                Debug.shared.log(message: "The file has been deleted for this entry, please remove it manually.", type: .critical)
            }
        case 1:
            if FileManager.default.fileExists(atPath: filePath2!.path) {
                popupVC = PopupViewController()
                popupVC.modalPresentationStyle = .pageSheet
                
                let singingData = SigningDataWrapper(signingOptions: UserDefaults.standard.signingOptions)
                let button1 = PopupViewControllerButton(
                    title: singingData.signingOptions.installAfterSigned
                    ? String.localized("LIBRARY_VIEW_CONTROLLER_SIGN_ACTION_SIGN_INSTALL", arguments: appName)
                    : String.localized("LIBRARY_VIEW_CONTROLLER_SIGN_ACTION_SIGN", arguments: appName),
                    color: .tintColor.withAlphaComponent(0.9))
                button1.onTap = { [weak self] in
                    guard let self = self else { return }
                    self.popupVC.dismiss(animated: true)
                    self.startSigning(meow: source!)
                }
                
                let button2 = PopupViewControllerButton(title: String.localized("LIBRARY_VIEW_CONTROLLER_SIGN_ACTION_INSTALL", arguments: appName), color: .quaternarySystemFill, titleColor: .tintColor)
                button2.onTap = { [weak self] in
                    guard let self = self else { return }
                    self.popupVC.dismiss(animated: true) {
                        let alertController = UIAlertController(
                            title: String.localized("LIBRARY_VIEW_CONTROLLER_SIGN_ACTION_INSTALL_CONFIRM"),
                            message: String.localized("LIBRARY_VIEW_CONTROLLER_SIGN_ACTION_INSTALL_CONFIRM_DESCRIPTION"),
                            preferredStyle: .alert
                        )
                        
                        let confirmAction = UIAlertAction(title: String.localized("INSTALL"), style: .default) { _ in
                            self.startInstallProcess(meow: source!, filePath: filePath?.path ?? "")
                        }
                        let cancelAction = UIAlertAction(title: String.localized("CANCEL"), style: .cancel, handler: nil)
                        
                        alertController.addAction(confirmAction)
                        alertController.addAction(cancelAction)
                        
                        self.present(alertController, animated: true, completion: nil)
                    }
                }
                
                popupVC.configureButtons([button1, button2])
                
                let detent2: UISheetPresentationController.Detent = ._detent(withIdentifier: "Test2", constant: 150.0)
                if let presentationController = popupVC.presentationController as? UISheetPresentationController {
                    presentationController.detents = [
                        det
                        if let presentationController = popupVC.presentationController as? UISheetPresentationController {
    presentationController.detents = [
        .medium(),
        .large()
    ]
    presentationController.prefersGrabberVisible = true
}

self.present(popupVC, animated: true)