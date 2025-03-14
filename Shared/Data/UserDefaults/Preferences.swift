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
    // Default repo is from the repository
    static var defaultRepos: Bool
    
    @Storage(key: "Feather.AppUpdates", defaultValue: false)
    // Default repo is from the repository
    static var appUpdates: Bool
    
    @Storage(key: "Feather.gotSSLCerts", defaultValue: false)
    static var gotSSLCerts: Bool
    
    @Storage(key: "Feather.BDefaultRepos", defaultValue: false)
    // Default beta repo is from the repository
    static var bDefaultRepos: Bool
    
    @Storage(key: "Feather.userIntefacerStyle", defaultValue: UIUserInterfaceStyle.unspecified.rawValue)
    static var preferredInterfaceStyle: Int
    
    @CodableStorage(key: "Feather.AppTintColor", defaultValue: CodableColor(UIColor(hex: "848ef9")))
    static var appTintColor: CodableColor
    
    // Added this for direct UIColor access in DisplayViewController
    static var currentTintColor: UIColor {
        get { return appTintColor.uiColor }
        set { appTintColor = CodableColor(newValue) }
    }

    @Storage(key: "Feather.OnboardingActive", defaultValue: true)
    static var isOnboardingActive: Bool
    
    @Storage(key: "Feather.selectedCert", defaultValue: 0)
    static var selectedCert: Int
    
    @Storage(key: "Feather.ppqcheckBypass", defaultValue: "")
    // random string
    static var pPQCheckString: String
    
    @Storage(key: "Feather.CertificateTitleAppIDtoTeamID", defaultValue: false)
    static var certificateTitleAppIDtoTeamID: Bool
    
    @Storage(key: "Feather.AppDescriptionAppearence", defaultValue: 0)
    // 0 == Default appearance
    // 1 == Replace subtitle with localizedDescription
    // 2 == Move localizedDescription below app icon, and above screenshots
    static var appDescriptionAppearence: Int
    
    @Storage(key: "UserPreferredLanguageCode", defaultValue: nil, callback: preferredLangChangedCallback)
    /// Preferred language
    static var preferredLanguageCode: String?
    
    @Storage(key: "Feather.Beta", defaultValue: false)
    //
    static var beta: Bool
    
    @CodableStorage(key: "SortOption", defaultValue: SortOption.default)
    static var currentSortOption: SortOption
    
    @Storage(key: "SortOptionAscending", defaultValue: true)
    static var currentSortOptionAscending: Bool
    
    // New method to load all preferences
    static func load() {
        // Since you're using custom @Storage and @CodableStorage properties, 
        // these are automatically managed, but we can still ensure they're loaded:
        
        // Forcing a read for each property will ensure it's loaded from storage if it hasn't been yet.
        _ = onlinePath
        _ = userSelectedServer
        _ = defaultRepos
        _ = appUpdates
        _ = gotSSLCerts
        _ = bDefaultRepos
        _ = preferredInterfaceStyle
        _ = appTintColor
        _ = isOnboardingActive
        _ = selectedCert
        _ = pPQCheckString
        _ = certificateTitleAppIDtoTeamID
        _ = appDescriptionAppearence
        _ = preferredLanguageCode
        _ = beta
        _ = currentSortOption
        _ = currentSortOptionAscending
        
        // If you want to manually check and set values (not needed if @Storage works correctly):
        // let userDefaults = UserDefaults.standard
        // if let storedTintColor = userDefaults.data(forKey: "Feather.AppTintColor") {
        //     do {
        //         let color = try JSONDecoder().decode(CodableColor.self, from: storedTintColor)
        //         appTintColor = color
        //     } catch {
        //         print("Failed to decode tint color: \(error)")
        //     }
        // }
        // And so on for each property...
    }
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