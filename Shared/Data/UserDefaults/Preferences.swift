1| import Foundation
2| import UIKit
3| 
4| struct SigningOptions: Codable, CustomStringConvertible {
5|     var ppqCheckProtection: Bool = false
6|     var dynamicProtection: Bool = false
7|     var installAfterSigned: Bool = false
8|     var immediatelyInstallFromSource: Bool = false
9|     var removePlugins: Bool = false
10|     var forceFileSharing: Bool = false
11|     var removeSupportedDevices: Bool = false
12|     var removeURLScheme: Bool = false
13|     var forceProMotion: Bool = false
14|     var forceGameMode: Bool = false
15|     var forceForceFullScreen: Bool = false
16|     var forceiTunesFileSharing: Bool = false
17|     var forceTryToLocalize: Bool = false
18|     var removeProvisioningFile: Bool = false
19|     var removeWatchPlaceHolder: Bool = false
20|     var bundleIdConfig: [String: String] = [:]
21|     var displayNameConfig: [String: String] = [:]
22|     var forceMinimumVersion: String = "Automatic"
23|     var forceLightDarkAppearence: String = "Automatic"
24|     var toInject: [String] = [] // Added back from original SigningOptions.swift
25| 
26|     var description: String {
27|         """
28|         PPQ Check: \(ppqCheckProtection), Dynamic: \(dynamicProtection), Install After Signed: \(installAfterSigned),
29|         Immediately Install: \(immediatelyInstallFromSource), Remove Plugins: \(removePlugins),
30|         Force File Sharing: \(forceFileSharing), Remove Supported Devices: \(removeSupportedDevices),
31|         Remove URL Scheme: \(removeURLScheme), Force ProMotion: \(forceProMotion),
32|         Force Game Mode: \(forceGameMode), Force Fullscreen: \(forceForceFullScreen),
33|         Force iTunes Sharing: \(forceiTunesFileSharing), Force Localize: \(forceTryToLocalize),
34|         Remove Provisioning: \(removeProvisioningFile), Remove Watch Placeholder: \(removeWatchPlaceHolder)
35|         """
36|     }
37| }
38| 
39| enum Preferences {
40|     static var installPathChangedCallback: ((String?) -> Void)?
41|     static let defaultInstallPath: String = "https://api.palera.in"
42| 
43|     @UserDefaultsStorage(key: "Feather.UserSpecifiedOnlinePath", defaultValue: defaultInstallPath)
44|     static var onlinePath: String? { didSet { installPathChangedCallback?(onlinePath) } }
45| 
46|     @UserDefaultsStorage(key: "Feather.UserSelectedServer", defaultValue: false)
47|     static var userSelectedServer: Bool
48| 
49|     @UserDefaultsStorage(key: "Feather.DefaultRepos", defaultValue: true)
50|     static var defaultRepos: Bool
51| 
52|     @UserDefaultsStorage(key: "Feather.AppUpdates", defaultValue: true)
53|     static var appUpdates: Bool
54| 
55|     @UserDefaultsStorage(key: "Feather.GotSSLCerts", defaultValue: false)
56|     static var gotSSLCerts: Bool
57| 
58|     @UserDefaultsStorage(key: "Feather.BDefaultRepos", defaultValue: false)
59|     static var bDefaultRepos: Bool
60| 
61|     @UserDefaultsStorage(key: "Feather.PreferredInterfaceStyle", defaultValue: UIUserInterfaceStyle.unspecified.rawValue)
62|     static var preferredInterfaceStyle: Int
63| 
64|     @UserDefaultsStorage(key: "Feather.AppTintColor", defaultValue: CodableColor(.systemBlue))
65|     static var appTintColor: CodableColor
66| 
67|     @UserDefaultsStorage(key: "Feather.IsOnboardingActive", defaultValue: true)
68|     static var isOnboardingActive: Bool
69| 
70|     @UserDefaultsStorage(key: "Feather.SelectedCert", defaultValue: 0)
71|     static var selectedCert: Int
72| 
73|     @UserDefaultsStorage(key: "Feather.PPQCheckString", defaultValue: "")
74|     static var pPQCheckString: String
75| 
76|     @UserDefaultsStorage(key: "Feather.CertificateTitleAppIDtoTeamID", defaultValue: false)
77|     static var certificateTitleAppIDtoTeamID: Bool
78| 
79|     @UserDefaultsStorage(key: "Feather.AppDescriptionAppearence", defaultValue: 0)
80|     static var appDescriptionAppearence: Int
81| 
82|     @UserDefaultsStorage(key: "UserPreferredLanguageCode", defaultValue: nil, callback: preferredLangChangedCallback)
83|     static var preferredLanguageCode: String?
84| 
85|     @UserDefaultsStorage(key: "Feather.Beta", defaultValue: false)
86|     static var beta: Bool
87| 
88|     @CodableUserDefaultsStorage(key: "Feather.SigningOptions", defaultValue: SigningOptions())
89|     static var signingOptions: SigningOptions
90| 
91|     @CodableUserDefaultsStorage(key: "SortOption", defaultValue: SortOption.default)
92|     static var currentSortOption: SortOption
93| 
94|     @UserDefaultsStorage(key: "SortOptionAscending", defaultValue: true)
95|     static var currentSortOptionAscending: Bool
96| }
97| 
98| fileprivate extension Preferences {
99|     static func preferredLangChangedCallback(newValue: String?) {
100|         Bundle.preferredLocalizationBundle = .makeLocalizationBundle(preferredLanguageCode: newValue)
101|     }
102| }
103| 
104| struct CodableColor: Codable {
105|     let uiColor: UIColor
106| 
107|     init(_ color: UIColor) { self.uiColor = color }
108| 
109|     enum CodingKeys: String, CodingKey {
110|         case red, green, blue, alpha
111|     }
112| 
113|     init(from decoder: Decoder) throws {
114|         let container = try decoder.container(keyedBy: CodingKeys.self)
115|         let r = try container.decode(CGFloat.self, forKey: .red)
116|         let g = try container.decode(CGFloat.self, forKey: .green)
117|         let b = try container.decode(CGFloat.self, forKey: .blue)
118|         let a = try container.decode(CGFloat.self, forKey: .alpha)
119|         self.uiColor = UIColor(red: r, green: g, blue: b, alpha: a)
120|     }
121| 
122|     func encode(to encoder: Encoder) throws {
123|         var container = encoder.container(keyedBy: CodingKeys.self)
124|         var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
125|         uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
126|         try container.encode(r, forKey: .red)
127|         try container.encode(g, forKey: .green)
128|         try container.encode(b, forKey: .blue)
129|         try container.encode(a, forKey: .alpha)
130|     }
131| }