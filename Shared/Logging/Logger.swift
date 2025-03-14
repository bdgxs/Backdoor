//
//  Logger.swift
//  feather
//
//  Created by samara on 7/29/24.
//  Copyright (c) 2024 Samara M (khcrysalis)
//

import AlertKit
import Foundation
import OSLog

public enum LogType {
    /// Default
    case notice
    /// Call this function to capture information that may be helpful, but isn’t essential, for troubleshooting.
    case info
    /// Debug-level messages to use in a development environment while actively debugging.
    case debug
    /// Equivalent of the debug method.
    case trace
    /// Warning-level messages for reporting unexpected non-fatal failures.
    case warning
    /// Error-level messages for reporting critical errors and failures.
    case error
    /// Fault-level messages for capturing system-level or multi-process errors only.
    case fault
    /// Functional equivalent of the fault method.
    case critical
    
    case success
}

final class Debug {
    static let shared = Debug()
    private let subsystem = Bundle.main.bundleIdentifier!
    
    private var logFilePath: URL {
        return getDocumentsDirectory().appendingPathComponent("logs.txt")
    }
    
    private func appendLogToFile(_ message: String) {
        do {
            if FileManager.default.fileExists(atPath: logFilePath.path) {
                let fileHandle = try FileHandle(forUpdating: logFilePath)
                defer { fileHandle.closeFile() }
                fileHandle.seekToEndOfFile()
                if let data = message.data(using: .utf8) {
                    fileHandle.write(data)
                }
            } else {
                try message.write(to: logFilePath, atomically: true, encoding: .utf8)
            }
        } catch {
            self.log(message: "Error writing to logs.txt: \(error)", type: .error)
        }
    }
    
    func log(message: String, type: LogType = .notice, function: String = #function, file: String = #file, line: Int = #line) {
        let logger = Logger(subsystem: subsystem, category: "\(file)->\(function)")

        // Prepare the emoji based on the log type
        let emoji: String
        switch type {
        case .success:
            emoji = "✅"
            logger.info("\(message)")
            showSuccessAlert(with: String.localized("ALERT_SUCCESS"), subtitle: message)
        case .info:
            emoji = "ℹ️"
            logger.info("\(message)")
        case .debug:
            emoji = "🐛"
            logger.debug("\(message)")
        case .trace:
            emoji = "🔍"
            logger.trace("\(message)")
            showErrorUIAlert(with: String.localized("ALERT_TRACE"), subtitle: message)
        case .warning:
            emoji = "⚠️"
            logger.warning("\(message)")
            showErrorAlert(with: String.localized("ALERT_ERROR"), subtitle: message)
        case .error:
            emoji = "❌"
            logger.error("\(message)")
            showErrorAlert(with: String.localized("ALERT_ERROR"), subtitle: message)
        case .critical:
            emoji = "🔥"
            logger.critical("\(message)")
            showErrorUIAlert(with: String.localized("ALERT_CRITICAL"), subtitle: message)
        default:
            emoji = "📝"
            logger.log("\(message)")
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
        let timeString = dateFormatter.string(from: Date())
        
        let logMessage = "[\(timeString)] \(emoji) \(message)\n"
        appendLogToFile(logMessage)
    }

    func showSuccessAlert(with title: String, subtitle: String) {
        DispatchQueue.main.async {
            let alertView = AlertAppleMusic17View(title: title, subtitle: subtitle, icon: .done)
            if let keyWindow = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first?.windows.first(where: \.isKeyWindow) {
                if let viewController = keyWindow.rootViewController {
                    alertView.present(on: viewController.view)
                }
            }
            #if os(iOS)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            #endif
        }
    }
    
    func showErrorAlert(with title: String, subtitle: String) {
        DispatchQueue.main.async {
            let alertView = AlertAppleMusic17View(title: title, subtitle: subtitle, icon: .error)
            if let keyWindow = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first?.windows.first(where: \.isKeyWindow) {
                if let viewController = keyWindow.rootViewController {
                    alertView.present(on: viewController.view)
                }
            }
            #if os(iOS)
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            #endif
        }
    }
    
    func showErrorUIAlert(with title: String, subtitle: String) {
        DispatchQueue.main.async {
            if let keyWindow = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first?.windows.first(where: \.isKeyWindow),
               let rootViewController = keyWindow.rootViewController {
                let alert = UIAlertController.error(title: title, message: subtitle, actions: [])
                rootViewController.present(alert, animated: true)
            }
            
            #if os(iOS)
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            #endif
        }
    }
    
    private func getDocumentsDirectory() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}

extension UIAlertController {
    static func error(title: String, message: String, actions: [UIAlertAction]) -> UIAlertController {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: String.localized("OK"), style: .cancel) { _ in
            alertController.dismiss(animated: true)
        })

        actions.forEach { alertController.addAction($0) }
        #if os(iOS)
        UINotificationFeedbackGenerator().notificationOccurred(.error)
        #endif
        return alertController
    }
    
    static func coolAlert(title: String, message: String, actions: [UIAlertAction]) -> UIAlertController {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)

        actions.forEach { alertController.addAction($0) }
        #if os(iOS)
        UINotificationFeedbackGenerator().notificationOccurred(.error)
        #endif
        return alertController
    }
}