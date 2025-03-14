//
//  Logger.swift
//  feather
//
//  Created by Samara on 7/29/24.
//  Copyright (c) 2024 Samara M (khcrysalis)
//

import AlertKit
import Foundation
import OSLog

public enum LogType {
    case notice
    case info
    case debug
    case trace
    case warning
    case error
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
            log(message: "Error writing to logs.txt: \(error)", type: .error)
        }
    }

    func log(message: String, type: LogType = .notice, function: String = #function, file: String = #file, line: Int = #line) {
        let logger = Logger(subsystem: subsystem, category: "\(file)->\(function)")

        // Prepare the emoji based on the log type
        let (emoji, logFunc): (String, (String) -> Void) = {
            switch type {
            case .success:
                return ("✅", logger.info)
            case .info:
                return ("ℹ️", logger.info)
            case .debug:
                return ("🐛", logger.debug)
            case .trace:
                showErrorUIAlert(with: String.localized("ALERT_TRACE"), subtitle: message)
                return ("🔍", logger.trace)
            case .warning:
                showErrorAlert(with: String.localized("ALERT_ERROR"), subtitle: message)
                return ("⚠️", logger.warning)
            case .error:
                showErrorAlert(with: String.localized("ALERT_ERROR"), subtitle: message)
                return ("❌", logger.error)
            case .critical:
                showErrorUIAlert(with: String.localized("ALERT_CRITICAL"), subtitle: message)
                return ("🔥", logger.critical)
            default:
                return ("📝", logger.log)
            }
        }()

        logFunc(message)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
        let timeString = dateFormatter.string(from: Date())

        let logMessage = "[\(timeString)] \(emoji) \(message)\n"
        appendLogToFile(logMessage)
    }

    private func showAlert(with title: String, subtitle: String, icon: AlertIcon) {
        DispatchQueue.main.async {
            let alertView = AlertAppleMusic17View(title: title, subtitle: subtitle, icon: icon)
            if let keyWindow = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first?.windows.first(where: \.isKeyWindow),
               let viewController = keyWindow.rootViewController {
                alertView.present(on: viewController.view)
            }
            #if os(iOS)
            UINotificationFeedbackGenerator().notificationOccurred(icon == .done ? .success : .error)
            #endif
        }
    }

    func showSuccessAlert(with title: String, subtitle: String) {
        showAlert(with: title, subtitle: subtitle, icon: .done)
    }

    func showErrorAlert(with title: String, subtitle: String) {
        showAlert(with: title, subtitle: subtitle, icon: .error)
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
        
        alertController.addAction(UIAlertAction(title: String.localized("OK"), style: .cancel))
        actions.forEach { alertController.addAction($0) }

        return alertController
    }
    
    static func coolAlert(title: String, message: String, actions: [UIAlertAction]) -> UIAlertController {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        actions.forEach { alertController.addAction($0) }
        return alertController
    }
}