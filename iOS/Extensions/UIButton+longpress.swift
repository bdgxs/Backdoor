import Foundation
import UIKit

extension UIButton {
    private struct AssociatedKeys {
        static var longPressGestureRecognizer = "longPressGestureRecognizer"
    }
    
    var longPressGestureRecognizer: UILongPressGestureRecognizer? {
        get {
            withUnsafePointer(to: AssociatedKeys.longPressGestureRecognizer) {
                return objc_getAssociatedObject(self, $0) as? UILongPressGestureRecognizer
            }
        }
        set {
            withUnsafePointer(to: AssociatedKeys.longPressGestureRecognizer) {
                objc_setAssociatedObject(self, $0, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }
    }
    
    /// Adds a long press gesture recognizer to the button.
    /// - Parameter action: The action to perform when the long press is recognized.
    func addLongPressGestureRecognizer(action: Selector) {
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: action)
        self.addGestureRecognizer(longPressGesture)
        self.longPressGestureRecognizer = longPressGesture
    }
    
    /// Removes the long press gesture recognizer from the button if it exists.
    func removeLongPressGestureRecognizer() {
        if let gesture = self.longPressGestureRecognizer {
            self.removeGestureRecognizer(gesture)
            self.longPressGestureRecognizer = nil
        }
    }
    
    /// Updates the button's content insets based on the iOS version.
    /// - Parameters:
    ///   - top: Top inset.
    ///   - leading: Leading inset for iOS 11+ or left for earlier versions.
    ///   - bottom: Bottom inset.
    ///   - trailing: Trailing inset for iOS 11+ or right for earlier versions.
    func updateContentInsets(top: CGFloat, leading: CGFloat, bottom: CGFloat, trailing: CGFloat) {
        if #available(iOS 15.0, *) {
            var config = self.configuration ?? UIButton.Configuration.plain()
            config.contentInsets = NSDirectionalEdgeInsets(top: top, leading: leading, bottom: bottom, trailing: trailing)
            self.configuration = config
        } else {
            self.contentEdgeInsets = UIEdgeInsets(top: top, left: leading, bottom: bottom, right: trailing)
        }
    }
}