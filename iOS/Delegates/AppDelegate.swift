//
//  AppDelegate.swift
//  feather
//
//  Created by Samara on 5/17/24.
//  Copyright (c) 2024 Samara M (khcrysalis)
//

import BackgroundTasks
import CoreData
import Foundation
import Nuke
import SwiftUI
import UIKit
import UIOnboarding

var downloadTaskManager = DownloadTaskManager.shared

class AppDelegate: UIResponder, UIApplicationDelegate, UIOnboardingViewControllerDelegate {
    static let isSideloaded = Bundle.main.bundleIdentifier != "com.bdg.backdoor"
    var window: UIWindow?
    var loaderAlert = presentLoader()

    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let userDefaults = UserDefaults.standard
        
        // Set the current app version
        if let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            userDefaults.set(currentVersion, forKey: "currentVersion")
        } else {
            Debug.shared.log(message: "Failed to retrieve app version", type: .error)
        }

        // Initialize signing data if not present
        if userDefaults.data(forKey: UserDefaults.signingDataKey) == nil {
            userDefaults.signingOptions = UserDefaults.defaultSigningData
        }

        setupApplication()
        return true
    }

    private func setupApplication() {
        createSourcesDirectory()
        addDefaultRepos()
        addAdditionalRepos()  // Add additional repositories
        giveUserDefaultSSLCerts()
        imagePipline()
        setupLogFile()
        cleanTmp()
    }

    fileprivate func addDefaultRepos() {
        guard !Preferences.defaultRepos else { return }

        CoreDataManager.shared.saveSource(
            name: "Backdoor Repository",
            id: "com.bdg.backdoor-repo",
            iconURL: URL(string: "https://raw.githubusercontent.com/814bdg/App/refs/heads/main/Wing3x.png?raw=true"),
            url: "https://raw.githubusercontent.com/814bdg/App/c56e7beebe634db3065b8cf763c6e4a049ca73c1/App-repo.json"
        ) { _ in
            Debug.shared.log(message: "Added default repos!")
            Preferences.defaultRepos = true
        }
    }

    fileprivate func addAdditionalRepos() {
        let additionalRepos = [
            ("AppTesters Repository", "repository.apptesters.org"),
            ("Arctic Signer", "https://raw.githubusercontent.com/usearcticsigner/Arctic-Repo/refs/heads/main/repo.json"),
            ("CelestialRepo", "https://raw.githubusercontent.com/RealBlackAstronaut/CelestialRepo/main/CelestialRepo.json"),
            ("Chromium iOS", "https://raw.githubusercontent.com/TheNightmanCodeth/chromium-ios/master/altstore-source.json"),
            ("Cypwn", "https://ipa.cypwn.xyz/cypwn.json"),
            ("Cypwn TS", "https://ipa.cypwn.xyz/cypwn_ts.json"),
            ("Feather App Repo", "https://github.com/khcrysalis/Feather/raw/main/app-repo.json"),
            ("Flycast Builds", "https://flyinghead.github.io/flycast-builds/altstore.json"),
            ("NabzClan", "https://apps.nabzclan.vip/repos/altstore.php"),
            ("TrollStore IPAs", "https://raw.githubusercontent.com/Neoncat-OG/TrollStore-IPAs/main/apps_esign.json"),
            ("OatmealDome AltStore", "https://altstore.oatmealdome.me/"),
            ("AltStoreRus", "https://raw.githubusercontent.com/vizunchik/AltStoreRus/master/apps.json"),
            ("Pokemmo", "https://pokemmo.com/altstore/"),
            ("Provenance Emulator", "https://provenance-emu.com/apps.json"),
            ("QNBlackCat", "https://qnblackcat.github.io/AltStore/apps.json"),
            ("RandomBlock", "https://randomblock1.com/altstore/apps.json"),
            ("SideStore Community", "https://community-apps.sidestore.io/sidecommunity.json"),
            ("SpotC", "https://tiny.one/SpotC"),
            ("TaurineStore", "https://taurine.app/altstore/taurinestore.json"),
            ("Wuxu Complete", "https://wuxu1.github.io/wuxu-complete.json"),
            ("Wuxu Complete Plus", "https://wuxu1.github.io/wuxu-complete-plus.json"),
            ("YTLitePlusAltstore", "https://raw.githubusercontent.com/Balackburn/YTLitePlusAltstore/main/apps.json"),
            ("ArichornloverAlt", "https://raw.githubusercontent.com/arichornloverALT/arichornloveralt.github.io/main/apps2.json"),
            ("Arichornlover", "https://raw.githubusercontent.com/arichornlover/arichornlover.github.io/main/apps2.json"),
            ("AIO Repo", "https://aio.yippee.rip/repo.json"),
            ("Binnichtaktiv", "https://binnichtaktiv.signapp.me/repo/esign.json"),
            ("Drifty Winds AltStore", "https://driftywinds.github.io/AltStore/apps.json"),
            ("Drifty Winds eSign", "https://driftywinds.github.io/repos/esign.json"),
            ("Sultanmods", "https://repo.sultanmods.fyi"),
            ("iSH", "https://ish.app/altstore.json"),
            ("iTorrent", "https://xitrix.github.io/iTorrent/AltStore.json"),
            ("Winston AltStore", "https://raw.githubusercontent.com/lo-cafe/winston-altstore/main/apps.json"),
            ("ArichornloverAlt", "https://raw.githubusercontent.com/arichornloveralt/arichornloveralt.github.io/main/apps.json"),
            ("eSign Yue", "https://esign.yyyue.xyz/app.json")
        ]

        for (name, url) in additionalRepos {
            let id = url.replacingOccurrences(of: "https://", with: "").replacingOccurrences(of: "/", with: "-")
            CoreDataManager.shared.saveSource(
                name: name,
                id: id,
                iconURL: nil,
                url: url
            ) { error in
                if let error = error {
                    Debug.shared.log(message: "Failed to add \(name): \(error)", type: .error)
                } else {
                    Debug.shared.log(message: "Successfully added \(name)!", type: .success)
                }
            }
        }
    }
}