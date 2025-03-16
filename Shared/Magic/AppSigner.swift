import Foundation
import UIKit
import AlertKit
import CoreData

func signInitialApp(bundle: BundleOptions, mainOptions: SigningMainDataWrapper, signingOptions: SigningDataWrapper, appPath: URL, completion: @escaping (Result<(URL, NSManagedObject), Error>) -> Void) {
    UIApplication.shared.isIdleTimerDisabled = true
    DispatchQueue(label: "Signing").async {
        let fileManager = FileManager.default
        let tmpDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let tmpDirApp = tmpDir.appendingPathComponent(appPath.lastPathComponent)
        var iconURL = ""
        
        do {
            Debug.shared.log(message: "============================================")
            Debug.shared.log(message: "\(mainOptions.mainOptions)")
            Debug.shared.log(message: "============================================")
            Debug.shared.log(message: "\(signingOptions.signingOptions)")
            Debug.shared.log(message: "============================================")
            try fileManager.createDirectory(at: tmpDir, withIntermediateDirectories: true)
            try fileManager.copyItem(at: appPath, to: tmpDirApp)
            
            if let info = NSDictionary(contentsOf: tmpDirApp.appendingPathComponent("Info.plist"))!.mutableCopy() as? NSMutableDictionary {
                try updateInfoPlist(infoDict: info, main: mainOptions, options: signingOptions, icon: mainOptions.mainOptions.iconURL, app: tmpDirApp)
                
                if let iconsDict = info["CFBundleIcons"] as? [String: Any],
                   let primaryIconsDict = iconsDict["CFBundlePrimaryIcon"] as? [String: Any],
                   let iconFiles = primaryIconsDict["CFBundleIconFiles"] as? [String],
                   let iconFileName = iconFiles.first {
                    iconURL = iconFileName
                }
            }
            
            let handler = TweakHandler(urls: signingOptions.signingOptions.toInject, app: tmpDirApp)
            try handler.getInputFiles()
            
            if !mainOptions.mainOptions.removeInjectPaths.isEmpty {
                if let appexe = try? TweakHandler.findExecutable(at: tmpDirApp) {
                    _ = uninstallDylibs(filePath: appexe.path, dylibPaths: mainOptions.mainOptions.removeInjectPaths)
                }
            }
            
            try updatePlugIns(options: signingOptions, app: tmpDirApp)
            try removeDumbAssPlaceHolderExtension(options: signingOptions, app: tmpDirApp)
            try updateMobileProvision(app: tmpDirApp)
            
            let certPath = try CoreDataManager.shared.getCertifcatePath(source: mainOptions.mainOptions.certificate)
            let provisionPath = certPath.appendingPathComponent("\(mainOptions.mainOptions.certificate?.provisionPath ?? "")").path
            let p12Path = certPath.appendingPathComponent("\(mainOptions.mainOptions.certificate?.p12Path ?? "")").path
            
            Debug.shared.log(message: "🦋 Start Signing 🦋")
            
            try signAppWithZSign(tmpDirApp: tmpDirApp, certPaths: (provisionPath, p12Path), password: mainOptions.mainOptions.certificate?.password ?? "", main: mainOptions, options: signingOptions)
            
            Debug.shared.log(message: "🦋 End Signing 🦋")
            
            let signedUUID = UUID().uuidString
            try fileManager.createDirectory(at: getDocumentsDirectory().appendingPathComponent("Apps/Signed"), withIntermediateDirectories: true)
            let signedPath = getDocumentsDirectory().appendingPathComponent("Apps/Signed").appendingPathComponent(signedUUID)
            try fileManager.moveItem(at: tmpDir, to: signedPath)
            
            DispatchQueue.main.async {
                var signedAppObject: NSManagedObject? = nil
                
                CoreDataManager.shared.addToSignedApps(
                    version: (mainOptions.mainOptions.version ?? bundle.version)!,
                    name: (mainOptions.mainOptions.name ?? bundle.name)!,
                    bundleidentifier: (mainOptions.mainOptions.bundleId ?? bundle.bundleId)!,
                    iconURL: iconURL,
                    uuid: signedUUID,
                    appPath: appPath.lastPathComponent,
                    timeToLive: mainOptions.mainOptions.certificate?.certData?.expirationDate ?? Date(),
                    teamName: mainOptions.mainOptions.certificate?.certData?.name ?? "",
                    originalSourceURL: bundle.sourceURL
                ) { result in
                    
                    switch result {
                    case .success(let signedApp):
                        signedAppObject = signedApp
                    case .failure(let error):
                        Debug.shared.log(message: "signApp: \(error)", type: .error)
                        completion(.failure(error))
                    }
                }
                
                Debug.shared.log(message: String.localized("SUCCESS_SIGNED", arguments: "\((mainOptions.mainOptions.name ?? bundle.name) ?? String.localized("UNKNOWN"))"), type: .success)
                Debug.shared.log(message: "============================================")
                
                UIApplication.shared.isIdleTimerDisabled = false
                completion(.success((signedPath, signedAppObject!)))
            }
        } catch {
            DispatchQueue.main.async {
                UIApplication.shared.isIdleTimerDisabled = false
                Debug.shared.log(message: "signApp: \(error)", type: .critical)
                completion(.failure(error))
            }
        }
    }
}

func updateInfoPlist(infoDict: NSMutableDictionary, main: SigningMainDataWrapper, options: SigningDataWrapper, icon: UIImage?, app: URL) throws {
    if let iconURL = main.mainOptions.iconURL {
        
        let iconSizes = [60, 76, 120, 152]
        var cfBundleIconFiles = [String]()
        
        for size in iconSizes {
            let fileName = "AppIcon\(size)x\(size).png"
            let resizedImage = iconURL.resize(size, size)
            let imageData = resizedImage.pngData()
            let fileURL = app.appendingPathComponent(fileName)
            
            do {
                try imageData?.write(to: fileURL)
                Debug.shared.log(message: "Saved image to: \(fileURL)")
                cfBundleIconFiles.append(fileName)
            } catch {
                Debug.shared.log(message: "Failed to save image: \(fileName), error: \(error)")
                throw error
            }
        }
        
        let cfBundleIcons: [String: Any] = [
            "CFBundlePrimaryIcon": [
                "CFBundleIconFiles": cfBundleIconFiles,
                "CFBundleIconName": "AppIcon"
            ]
        ]
        
        infoDict["CFBundleIcons"] = cfBundleIcons
    } else {
        Debug.shared.log(message: "updateInfoPlist.updateicon: Does not include an icon, skipping!")
    }
    
    if options.signingOptions.forceTryToLocalize && (main.mainOptions.name != nil) {
        if let displayName = infoDict.value(forKey: "CFBundleDisplayName") as? String {
            if displayName != main.mainOptions.name {
                updateLocalizedInfoPlist(in: app, newDisplayName: main.mainOptions.name!)
            }
        } else {
            Debug.shared.log(message: "updateInfoPlist.displayName: CFBundleDisplayName not found, skipping!")
        }
    }
    
    if options.signingOptions.forceFileSharing { infoDict.setObject(true, forKey: "UISupportsDocumentBrowser" as NSCopying) }
    if options.signingOptions.forceiTunesFileSharing { infoDict.setObject(true, forKey: "UIFileSharingEnabled" as NSCopying) }
    if options.signingOptions.removeSupportedDevices { infoDict.removeObject(forKey: "UISupportedDevices") }
    if options.signingOptions.removeURLScheme { infoDict.removeObject(forKey: "CFBundleURLTypes") }
    if options.signingOptions.forceProMotion { infoDict.setObject(true, forKey: "CADisableMinimumFrameDurationOnPhone" as NSCopying) }
    if options.signingOptions.forceGameMode { infoDict.setObject(true, forKey: "GCSupportsGameMode" as NSCopying) }
    if options.signingOptions.forceForceFullScreen { infoDict.setObject(true, forKey: "UIRequiresFullScreen" as NSCopying) }
    if options.signingOptions.forceMinimumVersion != "Automatic" { infoDict.setObject(options.signingOptions.forceMinimumVersion, forKey: "MinimumOSVersion" as NSCopying) }
    if options.signingOptions.forceLightDarkAppearence != "Automatic" { infoDict.setObject(options.signingOptions.forceLightDarkAppearence, forKey: "UIUserInterfaceStyle" as NSCopying) }
    try infoDict.write(to: app.appendingPathComponent("Info.plist"))
}