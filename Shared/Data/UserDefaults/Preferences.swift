import Foundation
import UIKit

// Assuming Certificate is a custom type; adjust if it’s Codable elsewhere
struct Certificate {
    // Placeholder; define properties as needed
    var name: String
    var expirationDate: Date
    // Add other properties...
}

struct SigningOptions: Codable, CustomStringConvertible {
    var ppqCheckProtection: Bool = false
    var dynamicProtection: Bool = false
    var installAfterSigned: Bool = false
    var immediatelyInstallFromSource: Bool = false
    var removePlugins: Bool = false
    var forceFileSharing: Bool = false
    var removeSupportedDevices: Bool = false
    var removeURLScheme: Bool = false
    var forceProMotion: Bool = false
    var forceGameMode: Bool = false
    var forceForceFullScreen: Bool = false
    var forceiTunesFileSharing: Bool = false
    var forceTryToLocalize: Bool = false
    var removeProvisioningFile: Bool = false
    var removeWatchPlaceHolder: Bool = false
    var bundleIdConfig: [String: String] = [:]
    var displayNameConfig: [String: String] = [:]
    var toInject: [String] = [] // Added back from original SigningOptions.swift
    var forceMinimumVersion: String = "Automatic"
    var forceLightDarkAppearence: String = "Automatic"
    var certificate: Certificate? // Custom handling for non-Codable type

    var description: String {
        """
        PPQ Check: \(ppqCheckProtection), Dynamic: \(dynamicProtection), Install After Signed: \(installAfterSigned),
        Immediately Install: \(immediatelyInstallFromSource), Remove Plugins: \(removePlugins),
        Force File Sharing: \(forceFileSharing), Remove Supported Devices: \(removeSupportedDevices),
        Remove URL Scheme: \(removeURLScheme), Force ProMotion: \(forceProMotion),
        Force Game Mode: \(forceGameMode), Force Fullscreen: \(forceForceFullScreen),
        Force iTunes Sharing: \(forceiTunesFileSharing), Force Localize: \(forceTryToLocalize),
        Remove Provisioning: \(removeProvisioningFile), Remove Watch Placeholder: \(removeWatchPlaceHolder)
        """
    }

    // Custom Codable conformance to exclude Certificate
    enum CodingKeys: String, CodingKey {
        case ppqCheckProtection, dynamicProtection, installAfterSigned, immediatelyInstallFromSource
        case removePlugins, forceFileSharing, removeSupportedDevices, removeURLScheme
        case forceProMotion, forceGameMode, forceForceFullScreen, forceiTunesFileSharing
        case forceTryToLocalize, removeProvisioningFile, removeWatchPlaceHolder
        case bundleIdConfig, displayNameConfig, toInject, forceMinimumVersion, forceLightDarkAppearence
        // Omit certificate
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        ppqCheckProtection = try container.decode(Bool.self, forKey: .ppqCheckProtection)
        dynamicProtection = try container.decode(Bool.self, forKey: .dynamicProtection)
        installAfterSigned = try container.decode(Bool.self, forKey: .installAfterSigned)
        immediatelyInstallFromSource = try container.decode(Bool.self, forKey: .immediatelyInstallFromSource)
        removePlugins = try container.decode(Bool.self, forKey: .removePlugins)
        forceFileSharing = try container.decode(Bool.self, forKey: .forceFileSharing)
        removeSupportedDevices = try container.decode(Bool.self, forKey: .removeSupportedDevices)
        removeURLScheme = try container.decode(Bool.self, forKey: .removeURLScheme)
        forceProMotion = try container.decode(Bool.self, forKey: .forceProMotion)
        forceGameMode = try container.decode(Bool.self, forKey: .forceGameMode)
        forceForceFullScreen = try container.decode(Bool.self, forKey: .forceForceFullScreen)
        forceiTunesFileSharing = try container.decode(Bool.self, forKey: .forceiTunesFileSharing)
        forceTryToLocalize = try container.decode(Bool.self, forKey: .forceTryToLocalize)
        removeProvisioningFile = try container.decode(Bool.self, forKey: .removeProvisioningFile)
        removeWatchPlaceHolder = try container.decode(Bool.self, forKey: .removeWatchPlaceHolder)
        bundleIdConfig = try container.decode([String: String].self, forKey: .bundleIdConfig)
        displayNameConfig = try container.decode([String: String].self, forKey: .displayNameConfig)
        toInject = try container.decode([String].self, forKey: .toInject)
        forceMinimumVersion = try container.decode(String.self, forKey: .forceMinimumVersion)
        forceLightDarkAppearence = try container.decode(String.self, forKey: .forceLightDarkAppearence)
        certificate = nil // Not decoded; handle separately if needed
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(ppqCheckProtection, forKey: .ppqCheckProtection)
        try container.encode(dynamicProtection, forKey: .dynamicProtection)
        try container.encode(installAfterSigned, forKey: .installAfterSigned)
        try container.encode(immediatelyInstallFromSource, forKey: .immediatelyInstallFromSource)
        try container.encode(removePlugins, forKey: .removePlugins)
        try container.encode(forceFileSharing, forKey: .forceFileSharing)
        try container.encode(removeSupportedDevices, forKey: .removeSupportedDevices)
        try container.encode(removeURLScheme, forKey: .removeURLScheme)
        try container.encode(forceProMotion, forKey: .forceProMotion)
        try container.encode(forceGameMode, forKey: .forceGameMode)
        try container.encode(forceForceFullScreen, forKey: .forceForceFullScreen)
        try container.encode(forceiTunesFileSharing, forKey: .forceiTunesFileSharing)
        try container.encode(forceTryToLocalize, forKey: .forceTryToLocalize)
        try container.encode(removeProvisioningFile, forKey: .removeProvisioningFile)
        try container.encode(removeWatchPlaceHolder, forKey: .removeWatchPlaceHolder)
        try container.encode(bundleIdConfig, forKey: .bundleIdConfig)
        try container.encode(displayNameConfig, forKey: .displayNameConfig)
        try container.encode(toInject, forKey: .toInject)
        try container.encode(forceMinimumVersion, forKey: .forceMinimumVersion)
        try container.encode(forceLightDarkAppearence, forKey: .forceLightDarkAppearence)
        // certificate is not encoded
    }
}

enum Preferences {
    static var installPathChangedCallback: ((String?) -> Void)?
    static let defaultInstallPath: String = "https://api.palera.in"

    @UserDefaultsStorage(key: "Feather.UserSpecifiedOnlinePath", defaultValue: defaultInstallPath)
    static var onlinePath: String? { didSet { installPathChangedCallback?(onlinePath) } }

    @UserDefaultsStorage(key: "Feather.UserSelectedServer", defaultValue: false)
    static var userSelectedServer: Bool

    @UserDefaultsStorage(key: "Feather.DefaultRepos", defaultValue: true)
    static var defaultRepos: Bool

    @UserDefaultsStorage(key: "Feather.AppUpdates", defaultValue: true)
    static var appUpdates: Bool

    @UserDefaultsStorage(key: "Feather.GotSSLCerts", defaultValue: false)
    static var gotSSLCerts: Bool

    @UserDefaultsStorage(key: "Feather.BDefaultRepos", defaultValue: false)
    static var bDefaultRepos: Bool

    @UserDefaultsStorage(key: "Feather.PreferredInterfaceStyle", defaultValue: UIUserInterfaceStyle.unspecified.rawValue)
    static var preferredInterfaceStyle: Int

    @UserDefaultsStorage(key: "Feather.AppTintColor", defaultValue: CodableColor(.systemBlue))
    static var appTintColor: CodableColor

    @UserDefaultsStorage(key: "Feather.IsOnboardingActive", defaultValue: true)
    static var isOnboardingActive: Bool

    @UserDefaultsStorage(key: "Feather.SelectedCert", defaultValue: 0)
    static var selectedCert: Int

    @UserDefaultsStorage(key: "Feather.PPQCheckString", defaultValue: "")
    static var pPQCheckString: String

    @UserDefaultsStorage(key: "Feather.CertificateTitleAppIDtoTeamID", defaultValue: false)
    static var certificateTitleAppIDtoTeamID: Bool

    @UserDefaultsStorage(key: "Feather.AppDescriptionAppearence", defaultValue: 0)
    static var appDescriptionAppearence: Int

    @UserDefaultsStorage(key: "UserPreferredLanguageCode", defaultValue: nil, callback: preferredLangChangedCallback)
    static var preferredLanguageCode: String?

    @UserDefaultsStorage(key: "Feather.Beta", defaultValue: false)
    static var beta: Bool

    @CodableUserDefaultsStorage(key: "Feather.SigningOptions", defaultValue: SigningOptions())
    static var signingOptions: SigningOptions

    @CodableUserDefaultsStorage(key: "SortOption", defaultValue: SortOption.default)
    static var currentSortOption: SortOption

    @UserDefaultsStorage(key: "SortOptionAscending", defaultValue: true)
    static var currentSortOptionAscending: Bool
}

fileprivate extension Preferences {
    static func preferredLangChangedCallback(newValue: String?) {
        Bundle.preferredLocalizationBundle = .makeLocalizationBundle(preferredLanguageCode: newValue)
    }
}

struct CodableColor: Codable {
    let uiColor: UIColor

    init(_ color: UIColor) { self.uiColor = color }

    enum CodingKeys: String, CodingKey {
        case red, green, blue, alpha
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let r = try container.decode(CGFloat.self, forKey: .red)
        let g = try container.decode(CGFloat.self, forKey: .green)
        let b = try container.decode(CGFloat.self, forKey: .blue)
        let a = try container.decode(CGFloat.self, forKey: .alpha)
        self.uiColor = UIColor(red: r, green: g, blue: b, alpha: a)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        try container.encode(r, forKey: .red)
        try container.encode(g, forKey: .green)
        try container.encode(b, forKey: .blue)
        try container.encode(a, forKey: .alpha)
    }
}

enum SortOption: String, Codable {
    case `default`
    case name
    case date
}