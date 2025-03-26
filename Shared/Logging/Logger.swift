import Foundation
import OSLog
import AlertKit
import UIKit

public enum LogType {
    /// Default log level for general notices
    case notice
    /// Captures information that may be helpful, but isn’t essential, for troubleshooting
    case info
    /// Debug-level messages for use in a development environment while actively debugging
    case debug
    /// Equivalent of debug, for detailed tracing
    case trace
    /// Warning-level messages for reporting unexpected non-fatal failures
    case warning
    /// Error-level messages for reporting critical errors and failures
    case error
    /// Fault-level messages for capturing system-level or multi-process errors
    case fault
    /// Functional equivalent of fault, for critical issues
    case critical
    /// Success messages for positive outcomes
    case success
}

// MARK: - Logger (Primary Implementation)
public final class Logger {
    public static let shared = Logger()
    private let subsystem = Bundle.main.bundleIdentifier ?? "com.default.subsystem"
    private let enableUIAlerts: Bool
    
    private var logFilePath: URL {
        return getDocumentsDirectory().appendingPathComponent("logs.txt")
    }
    
    private init(enableUIAlerts: Bool = true) {
        self.enableUIAlerts = enableUIAlerts
    }
    
    private func appendLogToFile(_ message: String) {
        do {
            if FileManager.default.fileExists(atPath: logFilePath.path) {
                let fileHandle = try FileHandle(forUpdating: logFilePath)
                fileHandle.seekToEndOfFile()
                if let data = message.data(using: .utf8) {
                    fileHandle.write(data)
                }
                fileHandle.closeFile()
            } else {
                try message.write(to: logFilePath, atomically: true, encoding: .utf8)
            }
        } catch let writeError {
            log(message: "Error writing to logs.txt: \(writeError.localizedDescription)", type: .error)
        }
    }
    
    // Fixed syntax error and removed erroneous static declarations
    public func log(message: String, type: LogType? = nil, function: String = #function, file: String = #file, line: Int = #line) {
        let logger = OSLog(subsystem: subsystem, category: "\(file) -> \(function)")
        var emoji: String
        
        switch type {
        case .success:
            emoji = "✅"
            os_log("%{public}@", log: logger, type: .info, message)
            if enableUIAlerts {
                showSuccessAlert(with: String.localized("ALERT_SUCCESS"), subtitle: message)
            }
        case .info:
            emoji = "ℹ️"
            os_log("%{public}@", log: logger, type: .info, message)
        case .debug:
            emoji = "🐛"
            os_log("%{public}@", log: logger, type: .debug, message)
        case .trace:
            emoji = "🔍"
            os_log("%{public}@", log: logger, type: .debug, message)
            if enableUIAlerts {
                showErrorUIAlert(with: String.localized("ALERT_TRACE"), subtitle: message)
            }
        case .warning:
            emoji = "⚠️"
            os_log("%{public}@", log: logger, type: .default, message)
            if enableUIAlerts {
                showErrorAlert(with: String.localized("ALERT_ERROR"), subtitle: message)
            }
        case .error:
            emoji = "❌"
            os_log("%{public}@", log: logger, type: .error, message)
            if enableUIAlerts {
                showErrorAlert(with: String.localized("ALERT_ERROR"), subtitle: message)
            }
        case .critical:
            emoji = "🔥"
            os_log("%{public}@", log: logger, type: .fault, message)
            if enableUIAlerts {
                showErrorUIAlert(with: String.localized("ALERT_CRITICAL"), subtitle: message)
            }
        case .fault:
            emoji = "💥"
            os_log("%{public}@", log: logger, type: .fault, message)
        case .notice:
            emoji = "📢"
            os_log("%{public}@", log: logger, type: .default, message)
        case nil:
            emoji = "📝"
            os_log("%{public}@", log: logger, type: .default, message)
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
        let timeString = dateFormatter.string(from: Date())
        let logMessage = "[\(timeString)] \(emoji) \(message)\n"
        appendLogToFile(logMessage)
    }
    
    // Static convenience method
    public static func log(message: String, type: LogType? = nil, function: String = #function, file: String = #file, line: Int = #line) {
        Logger.shared.log(message: message, type: type, function: function, file: file, line: line)
    }
    
    // MARK: - UI Alert Methods
    private func showSuccessAlert(with title: String, subtitle: String) {
        DispatchQueue.main.async {
            let alertView = AlertAppleMusic17View(title: title, subtitle: subtitle, icon: .done)
            let keyWindow = UIApplication.shared.connectedScenes.compactMap { ($0 as? UIWindowScene)?.keyWindow }.last
            if let viewController = keyWindow?.rootViewController {
                alertView.present(on: viewController.view)
            }
            #if os(iOS)
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            #endif
        }
    }
    
    private func showErrorAlert(with title: String, subtitle: String) {
        DispatchQueue.main.async {
            let alertView = AlertAppleMusic17View(title: title, subtitle: subtitle, icon: .error)
            let keyWindow = UIApplication.shared.connectedScenes.compactMap { ($0 as? UIWindowScene)?.keyWindow }.last
            if let viewController = keyWindow?.rootViewController {
                alertView.present(on: viewController.view)
            }
            #if os(iOS)
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
            #endif
        }
    }
    
    private func showErrorUIAlert(with title: String, subtitle: String) {
        DispatchQueue.main.async {
            let keyWindow = UIApplication.shared.connectedScenes.compactMap { ($0 as? UIWindowScene)?.keyWindow }.last
            if let rootViewController = keyWindow?.rootViewController {
                let alert = UIAlertController.error(title: title, message: subtitle, actions: [])
                rootViewController.present(alert, animated: true)
            }
            #if os(iOS)
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
            #endif
        }
    }
}

// MARK: - Debug (Compatibility Wrapper)
public final class Debug {
    public static let shared = Debug()
    
    private init() {}
    
    public func log(message: String, type: LogType? = nil, function: String = #function, file: String = #file, line: Int = #line) {
        Logger.shared.log(message: message, type: type, function: function, file: file, line: line)
    }
}

// MARK: - Helper Functions
private func getDocumentsDirectory() -> URL {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    return paths[0]
}

// MARK: - UIAlertController Extension
extension UIAlertController {
    static func error(title: String, message: String, actions: [UIAlertAction]) -> UIAlertController {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: String.localized("OK"), style: .cancel) { _ in
            alertController.dismiss(animated: true)
        })
        for action in actions {
            alertController.addAction(action)
        }
        #if os(iOS)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
        #endif
        return alertController
    }
}