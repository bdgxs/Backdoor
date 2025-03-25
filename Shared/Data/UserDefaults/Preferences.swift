import Foundation
import UIKit

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

    var description: String {
        return """
        PPQ Check: \(ppqCheckProtection), Dynamic: \(dynamicProtection), Install After Signed: \(installAfterSigned),
        Immediately Install: \(immediatelyInstallFromSource), Remove Plugins: \(removePlugins),
        Force File Sharing: \(forceFileSharing), Remove Supported Devices: \(removeSupportedDevices),
        Remove URL Scheme: \(removeURLScheme), Force ProMotion: \(forceProMotion),
        Force Game Mode: \(forceGameMode), Force Fullscreen: \(forceForceFullScreen),
        Force iTunes Sharing: \(forceiTunesFileSharing), Force Localize: \(forceTryToLocalize),
        Remove Provisioning: \(removeProvisioningFile), Remove Watch Placeholder: \(removeWatchPlaceHolder)
        """
    }
}

enum Preferences {
    static var installPathChangedCallback: ((String?) -> Void)?
    static let defaultInstallPath: String = "https://api.palera.in"

    @Storage(key: "Feather.UserSpecifiedOnlinePath", defaultValue: defaultInstallPath)
    static var onlinePath: String? { didSet { installPathChangedCallback?(onlinePath) } }

    @Storage(key: "Feather.UserSelectedServer", defaultValue: false)
    static var userSelectedServer: Bool

    @Storage(key: "Feather.DefaultRepos", defaultValue: true)
    static var defaultRepos: Bool

    @Storage(key: "Feather.AppUpdates", defaultValue: true)
    static var appUpdates: Bool

    @Storage(key: "Feather.GotSSLCerts", defaultValue: false)
    static var gotSSLCerts: Bool

    @Storage(key: "Feather.BDefaultRepos", defaultValue: false)
    static var bDefaultRepos: Bool

    @Storage(key: "Feather.PreferredInterfaceStyle", defaultValue: UIUserInterfaceStyle.unspecified.rawValue)
    static var preferredInterfaceStyle: Int

    @Storage(key: "Feather.AppTintColor", defaultValue: CodableColor(.systemBlue))
    static var appTintColor: CodableColor

    @Storage(key: "Feather.IsOnboardingActive", defaultValue: true)
    static var isOnboardingActive: Bool

    @Storage(key: "Feather.SelectedCert", defaultValue: 0)
    static var selectedCert: Int

    @Storage(key: "Feather.PPQCheckString", defaultValue: "")
    static var pPQCheckString: String

    @Storage(key: "Feather.CertificateTitleAppIDtoTeamID", defaultValue: false)
    static var certificateTitleAppIDtoTeamID: Bool

    @Storage(key: "Feather.AppDescriptionAppearence", defaultValue: 0)
    static var appDescriptionAppearence: Int

    @Storage(key: "UserPreferredLanguageCode", defaultValue: nil, callback: preferredLangChangedCallback)
    static var preferredLanguageCode: String?

    @Storage(key: "Feather.Beta", defaultValue: false)
    static var beta: Bool

    @CodableStorage(key: "Feather.SigningOptions", defaultValue: SigningOptions())
    static var signingOptions: SigningOptions

    @CodableStorage(key: "SortOption", defaultValue: SortOption.default)
    static var currentSortOption: SortOption

    @Storage(key: "SortOptionAscending", defaultValue: true)
    static var currentSortOptionAscending: Bool
}

// MARK: - Callbacks
fileprivate extension Preferences {
    static func preferredLangChangedCallback(newValue: String?) {
        Bundle.preferredLocalizationBundle = .makeLocalizationBundle(preferredLanguageCode: newValue)
    }
}

// Storage Property Wrapper
@propertyWrapper
struct Storage<T> {
    private let key: String
    private let defaultValue: T
    private let callback: ((T) -> Void)?

    init(key: String, defaultValue: T, callback: ((T) -> Void)? = nil) {
        self.key = key
        self.defaultValue = defaultValue
        self.callback = callback
    }

    var wrappedValue: T {
        get { UserDefaults.standard.object(forKey: key) as? T ?? defaultValue }
        set {
            UserDefaults.standard.set(newValue, forKey: key)
            callback?(newValue)
        }
    }
}

// Codable Storage Property Wrapper
@propertyWrapper
struct CodableStorage<T: Codable> {
    private let key: String
    private let defaultValue: T

    init(key: String, defaultValue: T) {
        self.key = key
        self.defaultValue = defaultValue
    }

    var wrappedValue: T {
        get {
            guard let data = UserDefaults.standard.data(forKey: key),
                  let value = try? JSONDecoder().decode(T.self, from: data) else {
                return defaultValue
            }
            return value
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: key)
            }
        }
    }
}

struct CodableColor: Codable {
    let uiColor: UIColor

    init(_ color: UIColor) {
        self.uiColor = color
    }

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

// Assuming SortOption is defined elsewhere; if not, here’s a placeholder
enum SortOption: Codable {
    case `default` // Adjust based on your actual SortOption definition
}