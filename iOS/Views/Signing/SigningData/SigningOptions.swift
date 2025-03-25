//
//  SigningOptions.swift
//  feather
//
//  Created by samara on 25.10.2024.
//

import Foundation
import UIKit

struct MainSigningOptions {
    var name: String?
    var version: String?
    var bundleId: String?
    var iconURL: UIImage?
    var uuid: String?
    var removeInjectPaths: [String] = []
    let forceMinimumVersionString = ["Automatic", "15.0", "14.0", "13.0"]
    let forceLightDarkAppearenceString = ["Automatic", "Light", "Dark"]
    var certificate: Certificate? // Kept here as it’s not Codable
}

extension UserDefaults {
    static let signingDataKey = "defaultSigningData"
    
    static let defaultSigningData = SigningOptions()
    
    var signingOptions: SigningOptions {
        get {
            if let data = data(forKey: UserDefaults.signingDataKey),
               let options = try? JSONDecoder().decode(SigningOptions.self, from: data) {
                return options
            }
            return UserDefaults.defaultSigningData
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                set(data, forKey: UserDefaults.signingDataKey)
            }
        }
    }
    
    func resetSigningOptions() {
        signingOptions = UserDefaults.defaultSigningData
    }
}