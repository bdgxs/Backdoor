//
//  Preferences.swift
//  feather
//
//  Created by samara on 5/17/24.
//  Copyright (c) 2024 Samara M (khcrysalis)
//

import Foundation
import UIKit

enum Preferences {
    static var installPathChangedCallback: ((String?) -> Void)?
    static let defaultInstallPath: String = "https://api.palera.in"
    
    @Storage(key: "Feather.UserSpecifiedOnlinePath", defaultValue: defaultInstallPath)
    static var onlinePath: String? { didSet { installPathChangedCallback?(onlinePath) } }
    
    @Storage(key: "Feather.UserSelectedServer", defaultValue: false)
    static var userSelectedServer: Bool
    
    @Storage(key: "Feather.DefaultRepos", defaultValue: false)
    static var defaultRepos: Bool
    
    @Storage(key: "Feather.AppUpdates", defaultValue: false)
    static var appUpdates: Bool
    
    @Storage(key: "Feather.gotSSLCerts", defaultValue: false)
    static var gotSSLCerts: Bool
    
    @Storage(key: "Feather.BDefaultRepos", defaultValue: false)
    static var bDefaultRepos: Bool
    
    @Storage(key: "Feather.userIntefacerStyle", defaultValue: UIUserInterfaceStyle.unspecified.rawValue)
    static var preferredInterfaceStyle: Int
    
    @CodableStorage(key: "Feather.AppTintColor", defaultValue: CodableColor(UIColor(hex: "848ef9")))
    static var appTintColor: CodableColor
    
    @Storage(key: "Feather.OnboardingActive", defaultValue: true)
    static var isOnboardingActive: Bool
    
    @Storage(key: "Feather.selectedCert", defaultValue: 0)
    static var selectedCert: Int
    
    @Storage(key: "Feather.ppqcheckBypass", defaultValue: "")
    static var pPQCheckString: String
    
    @Storage(key: "Feather.CertificateTitleAppIDtoTeamID", defaultValue: false)
    static var certificateTitleAppIDtoTeamID: Bool
    
    @Storage(key: "Feather.AppDescriptionAppearence", defaultValue: 0)
    static var appDescriptionAppearence: Int
    
    @Storage(key: "UserPreferredLanguageCode", defaultValue: nil, callback: preferredLangChangedCallback)
    static var preferredLanguageCode: String?
    
    @Storage(key: "Feather.Beta", defaultValue: false)
    static var beta: Bool
    
    @CodableStorage(key: "SortOption", defaultValue: SortOption.default)
    static var currentSortOption: SortOption
    
    @Storage(key: "SortOptionAscending", defaultValue: true)
    static var currentSortOptionAscending: Bool
    
    @CodableStorage(key: "customTintColor", defaultValue: CodableColor(UIColor(hex: "848ef9")))
    static var customTintColor: CodableColor
}

// MARK: - Callbacks
fileprivate extension Preferences {
    static func preferredLangChangedCallback(newValue: String?) {
        Bundle.preferredLocalizationBundle = .makeLocalizationBundle(preferredLanguageCode: newValue)
    }
}

// MARK: - Color

struct CodableColor: Codable {
    let red: CGFloat
    let green: CGFloat
    let blue: CGFloat
    let alpha: CGFloat
    
    var uiColor: UIColor {
        return UIColor(red: self.red, green: self.green, blue: self.blue, alpha: self.alpha)
    }
    
    init(_ color: UIColor) {
        var _red: CGFloat = 0, _green: CGFloat = 0, _blue: CGFloat = 0, _alpha: CGFloat = 0
        
        color.getRed(&_red, green: &_green, blue: &_blue, alpha: &_alpha)
        
        self.red = _red
        self.blue = _blue
        self.green = _green
        self.alpha = _alpha
    }
}

// Helper extension for UIColor to initialize with hex string
extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt64()
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
}