//
//  SigningsViewController.swift
//  feather
//
//  Created by samara on 26.10.2024.
//

import UIKit
import CoreData

struct BundleOptions {
    var name: String?
    var bundleId: String?
    var version: String?
    var sourceURL: URL?
}

class SigningsViewController: UIViewController {
    
    private let buttonHeight: CGFloat = 80.0
    private let buttonHeightForPad: CGFloat = 65.0
    
    var tableData: [[String]] = [
        [
            "AppIcon",
            String.localized("APPS_INFORMATION_TITLE_NAME"),
            String.localized("APPS_INFORMATION_TITLE_IDENTIFIER"),
            String.localized("APPS_INFORMATION_TITLE_VERSION"),
        ],
        [ 
            "Signing",
        ],
        [
            String.localized("APP_SIGNING_VIEW_CONTROLLER_CELL_ADD_TWEAKS"),
            String.localized("APP_SIGNING_VIEW_CONTROLLER_CELL_MODIFY_DYLIBS"),
        ],
        [ String.localized("APP_SIGNING_VIEW_CONTROLLER_CELL_PROPERTIES") ],
    ]

    var sectionTitles: [String] = [
        String.localized("APP_SIGNING_VIEW_CONTROLLER_CELL_TITLE_CUSTOMIZATION"),
        String.localized("APP_SIGNING_VIEW_CONTROLLER_CELL_TITLE_SIGNING"),
        String.localized("APP_SIGNING_VIEW_CONTROLLER_CELL_TITLE_ADVANCED"),
        "",
    ]
    
    public var application: NSManagedObject?
    private var appsViewController: LibraryViewController?
    
    var signingDataWrapper: SigningDataWrapper
    var mainOptions = SigningMainDataWrapper(mainOptions: MainSigningOptions())
    
    var bundle: BundleOptions?
    
    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.showsHorizontalScrollIndicator = false
        tableView.showsVerticalScrollIndicator = false
        tableView.contentInset.bottom = 70
        return tableView
    }()
    
    private lazy var variableBlurView: UIVariableBlurView = {
        let blurView = UIVariableBlurView(frame: .zero)
        blurView.gradientMask = VariableBlurViewConstants.defaultGradientMask
        blurView.transform = CGAffineTransform(rotationAngle: CGFloat.pi)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        return blurView
    }()
    
    private lazy var largeButton: ActivityIndicatorButton = {
        let button = ActivityIndicatorButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(startSign), for: .touchUpInside)
        return button
    }()
    
    var signingCompletionHandler: ((Bool) -> Void)?
    
    init(signingDataWrapper: SigningDataWrapper, application: NSManagedObject, appsViewController: LibraryViewController) {
        self.signingDataWrapper = signingDataWrapper
        self.application = application
        self.appsViewController = appsViewController
        super.init(nibName: nil, bundle: nil)
        setupInitialData()
    }
    
    private func setupInitialData() {
        guard let name = application?.value(forKey: "name") as? String,
              let bundleId = application?.value(forKey: "bundleidentifier") as? String,
              let version = application?.value(forKey: "version") as? String else {
            return
        }
        let sourceLocation = application?.value(forKey: "oSU") as? String
        let sourceURL = sourceLocation != nil ? URL(string: sourceLocation!) : nil
        self.bundle = BundleOptions(name: name, bundleId: bundleId, version: version, sourceURL: sourceURL)
        
        if let hasGotCert = CoreDataManager.shared.getCurrentCertificate() {
            self.mainOptions.mainOptions.certificate = hasGotCert
        }
        if let uuid = application?.value(forKey: "uuid") as? String {
            self.mainOptions.mainOptions.uuid = uuid
        }
        
        configureBundleID()
        configureDynamicProtection()
    }
    
    private func configureBundleID() {
        if signingDataWrapper.signingOptions.ppqCheckProtection,
           mainOptions.mainOptions.certificate?.certData?.pPQCheck == true {
            if !signingDataWrapper.signingOptions.dynamicProtection {
                mainOptions.mainOptions.bundleId = (bundle?.bundleId ?? "") + "." + Preferences.pPQCheckString
            }
        }
        
        if let currentBundleId = bundle?.bundleId,
           let newBundleId = signingDataWrapper.signingOptions.bundleIdConfig[currentBundleId] {
            mainOptions.mainOptions.bundleId = newBundleId
        }
        
        if let currentName = bundle?.name,
           let newName = signingDataWrapper.signingOptions.displayNameConfig[currentName] {
            mainOptions.mainOptions.name = newName
        }
    }
    
    private func configureDynamicProtection() {
        guard signingDataWrapper.signingOptions.dynamicProtection else { return }
        Task {
            await checkDynamicProtection()
        }
    }
    
    private func checkDynamicProtection() async {
        guard signingDataWrapper.signingOptions.ppqCheckProtection,
              mainOptions.mainOptions.certificate?.certData?.pPQCheck == true,
              let bundleId = bundle?.bundleId else {
            return
        }
        
        let shouldModify = await BundleIdChecker.shouldModifyBundleId(originalBundleId: bundleId)
        if shouldModify {
            mainOptions.mainOptions.bundleId = bundleId + "." + Preferences.pPQCheckString
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigation()
        setupViews()
        setupToolbar()
        #if !targetEnvironment(simulator)
        certAlert()
        #endif
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeLeft.direction = .left
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeRight.direction = .right
        tableView.addGestureRecognizer(swipeLeft)
        tableView.addGestureRecognizer(swipeRight)
        NotificationCenter.default.addObserver(self, selector: #selector(fetch), name: Notification.Name("reloadSigningController"), object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: Notification.Name("reloadSigningController"), object: nil)
    }
    
    @objc func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
        let location = gesture.location(in: tableView)
        if let indexPath = tableView.indexPathForRow(at: location),
           indexPath.section == 1 && indexPath.row == 0 {
            let certificates = CoreDataManager.shared.getDatedCertificate()
            guard certificates.count > 1 else { return }
            
            let currentIndex = certificates.firstIndex { $0 == mainOptions.mainOptions.certificate } ?? 0
            var newIndex = currentIndex
            
            switch gesture.direction {
            case .left:
                newIndex = (currentIndex + 1) % certificates.count
            case .right:
                newIndex = (currentIndex - 1 + certificates.count) % certificates.count
            default:
                break
            }
            
            let feedbackGenerator = UISelectionFeedbackGenerator()
            feedbackGenerator.prepare()
            feedbackGenerator.selectionChanged()
            
            Preferences.selectedCert = newIndex
            mainOptions.mainOptions.certificate = certificates[newIndex]
            tableView.reloadRows(at: [indexPath], with: gesture.direction == .left ? .left : .right)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    
    private func setupNavigation() {
        let logoImageView = UIImageView(image: UIImage(named: "feather_glyph"))
        logoImageView.contentMode = .scaleAspectFit
        navigationItem.titleView = logoImageView
        self.navigationController?.navigationBar.prefersLargeTitles = false
        
        self.isModalInPresentation = true
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: String.localized("DISMISS"), style: .done, target: self, action: #selector(closeSheet))
    }
    
    private func setupViews() {
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupToolbar() {
        view.addSubview(variableBlurView)
        view.addSubview(largeButton)
        
        NSLayoutConstraint.activate([
            variableBlurView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            variableBlurView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            variableBlurView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            variableBlurView.heightAnchor.constraint(equalToConstant: buttonHeightForPad),
            
            largeButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            largeButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            largeButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -17),
            largeButton.heightAnchor.constraint(equalToConstant: UIDevice.current.userInterfaceIdiom == .pad ? buttonHeightForPad : buttonHeight)
        ])
        
        variableBlurView.layer.zPosition = 3
        largeButton.layer.zPosition = 4
    }
    
    private func certAlert() {
        guard mainOptions.mainOptions.certificate == nil else { return }
        DispatchQueue.main.async {
            let alert = UIAlertController(
                title: String.localized("APP_SIGNING_VIEW_CONTROLLER_NO_CERTS_ALERT_TITLE"),
                message: String.localized("APP_SIGNING_VIEW_CONTROLLER_NO_CERTS_ALERT_DESCRIPTION"),
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: String.localized("LAME"), style: .default) { _ in
                self.dismiss(animated: true)
            })
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    @objc private func closeSheet() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func fetch() {
        tableView.reloadData()
    }
    
    @objc private func startSign() {
        self.navigationItem.leftBarButtonItem = nil
        largeButton.showLoadingIndicator()
        signInitialApp(
            bundle: bundle!,
            mainOptions: mainOptions,
            signingOptions: signingDataWrapper,
            appPath: getFilesForDownloadedApps(app: application as! DownloadedApps, getuuidonly: false)
        ) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let (signedPath, signedApp)):
                self.appsViewController?.fetchSources()
                self.appsViewController?.tableView.reloadData()
                Debug.shared.log(message: signedPath.path)
                if self.signingDataWrapper.signingOptions.installAfterSigned {
                    self.appsViewController?.startInstallProcess(meow: signedApp, filePath: signedPath.path)
                    self.signingCompletionHandler?(true)
                }
            case .failure(let error):
                Debug.shared.log(message: "Signing failed: \(error.localizedDescription)", type: .error)
                self.showErrorAlert(error: error)
                self.signingCompletionHandler?(false)
            }
            self.dismiss(animated: true)
        }
    }
    
    private func showErrorAlert(error: Error) {
        let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}

extension SigningsViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int { return sectionTitles.count }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return tableData[section].count }
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? { return sectionTitles[section] }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { return sectionTitles[section].isEmpty ? 0 : 40 }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let title = sectionTitles[section]
        return InsetGroupedSectionHeader(title: title)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellText = tableData[indexPath.section][indexPath.row]
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "Cell")
        cell.accessoryType = .none
        cell.selectionStyle = .gray
        cell.textLabel?.text = cellText
        
        switch cellText {
        case "AppIcon":
            let iconCell = IconImageViewCell()
            if let iconURL = mainOptions.mainOptions.iconURL {
                iconCell.configure(with: iconURL)
            } else if let url = getIconURL(for: application as! DownloadedApps) {
                iconCell.configure(with: CoreDataManager.shared.loadImage(from: url))
            }
            iconCell.accessoryType = .disclosureIndicator
            return iconCell
        case String.localized("APPS_INFORMATION_TITLE_NAME"):
            cell.detailTextLabel?.text = mainOptions.mainOptions.name ?? bundle?.name
            cell.accessoryType = .disclosureIndicator
        case String.localized("APPS_INFORMATION_TITLE_IDENTIFIER"):
            cell.detailTextLabel?.text = mainOptions.mainOptions.bundleId ?? bundle?.bundleId
            cell.accessoryType = .disclosureIndicator
        case String.localized("APPS_INFORMATION_TITLE_VERSION"):
            cell.detailTextLabel?.text = mainOptions.mainOptions.version ?? bundle?.version
            cell.accessoryType = .disclosureIndicator
        case "Signing":
            if let certificate = mainOptions.mainOptions.certificate {
                let certificateCell = CertificateViewTableViewCell()
                certificateCell.configure(with: certificate, isSelected: false)
                certificateCell.selectionStyle = .none
                return certificateCell
            } else {
                cell.textLabel?.text = String.localized("SETTINGS_VIEW_CONTROLLER_CELL_CURRENT_CERTIFICATE_NOSELECTED")
                cell.textLabel?.textColor = .secondaryLabel
                cell.selectionStyle = .none
            }
        default:
            if ["Change Certificate", String.localized("APP_SIGNING_VIEW_CONTROLLER_CELL_ADD_TWEAKS"), String.localized("APP_SIGNING_VIEW_CONTROLLER_CELL_MODIFY_DYLIBS"), String.localized("APP_SIGNING_VIEW_CONTROLLER_CELL_PROPERTIES")].contains(cellText) {
                cell.accessoryType = .disclosureIndicator
            }
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let itemTapped = tableData[indexPath.section][indexPath.row]
        switch itemTapped {
        case "AppIcon":
            importAppIconFile()
        case String.localized("APPS_INFORMATION_TITLE_NAME"),
             String.localized("APPS_INFORMATION_TITLE_IDENTIFIER"),
             String.localized("APPS_INFORMATION_TITLE_VERSION"):
            let initialValue = itemTapped == String.localized("APPS_INFORMATION_TITLE_NAME") ? (mainOptions.mainOptions.name ?? bundle?.name)! :
                               itemTapped == String.localized("APPS_INFORMATION_TITLE_IDENTIFIER") ? (mainOptions.mainOptions.bundleId ?? bundle?.bundleId)! :
                               (mainOptions.mainOptions.version ?? bundle?.version)!
            let l = SigningsInputViewController(parentView: self, initialValue: initialValue, valueToSaveTo: indexPath.row)
            navigationController?.pushViewController(l, animated: true)
        case String.localized("APP_SIGNING_VIEW_CONTROLLER_CELL_ADD_TWEAKS"):
            let l = SigningsTweakViewController(signingDataWrapper: signingDataWrapper)
            navigationController?.pushViewController(l, animated: true)
        case String.localized("APP_SIGNING_VIEW_CONTROLLER_CELL_MODIFY_DYLIBS"):
            let l = SigningsDylibViewController(mainOptions: mainOptions, app: getFilesForDownloadedApps(app: application as! DownloadedApps, getuuidonly: false))
            navigationController?.pushViewController(l, animated: true)
        case String.localized("APP_SIGNING_VIEW_CONTROLLER_CELL_PROPERTIES"):
            let l = SigningsAdvancedViewController(signingDataWrapper: signingDataWrapper, mainOptions: mainOptions)
            navigationController?.pushViewController(l, animated: true)
        default:
            break
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - Helper Methods

extension SigningsViewController {
    public func getFilesForDownloadedApps(app: DownloadedApps, getuuidonly: Bool) -> URL {
        return CoreDataManager.shared.getFilesForDownloadedApps(for: app, getuuidonly: getuuidonly)
    }
    
    private func getIconURL(for app: DownloadedApps) -> URL? {
        guard let iconURLString = app.value(forKey: "iconURL") as? String,
              let iconURL = URL(string: iconURLString) else {
            return nil
        }
        
        let filesURL = getFilesForDownloadedApps(app: app, getuuidonly: false)
        return filesURL.appendingPathComponent(iconURL.lastPathComponent)
    }
}
