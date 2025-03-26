import Foundation

class BundleIdChecker {
    static func shouldModifyBundleId(originalBundleId: String) async -> Bool {
        do {
            let exists = try await iTunesLookup.checkBundleId(originalBundleId)
            Logger.shared.log(message: "Dynamic Protection: Bundle ID \(originalBundleId) exists on App Store: \(exists)", type: .info)
            return exists
        } catch {
            Logger.shared.log(message: "Dynamic Protection: Failed to check bundle ID \(originalBundleId), applying protection as precaution: \(error.localizedDescription)", type: .error)
            return true
        }
    }
}