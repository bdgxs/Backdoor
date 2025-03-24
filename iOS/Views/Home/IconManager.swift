import UIKit

class IconManager {
    static let shared = IconManager()
    private let fileManager = FileManager.default
    private let iconBundleURL = Bundle.main.url(forResource: "Icons", withExtension: "bundle")!
    
    func loadIcon(for name: String) -> UIImage? {
        let iconPath = iconBundleURL.appendingPathComponent("\(name).png")
        return UIImage(contentsOfFile: iconPath.path)
    }
    
    func registerCustomIcons() {
        // Ensure icons are bundled; these can be generated via image generation tool
        let iconNames = ["iconText", "iconPlist", "iconIPA", "iconZip", "iconPDF", "iconGeneric"]
        for name in iconNames {
            if loadIcon(for: name) == nil {
                print("Warning: Icon \(name) not found in bundle.")
            }
        }
    }
}