import Foundation
import OSLog

public enum LogType {
    case notice
    case info
    case debug
    case trace
    case warning
    case error
    case fault
    case critical
    case success
}

public final class Logger {
    public static let shared = Logger()
    private let subsystem = Bundle.main.bundleIdentifier ?? "com.default.subsystem" // Fallback for safety
    
    private var logFilePath: URL {
        return getDocumentsDirectory().appendingPathComponent("logs.txt")
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
                // Create the file if it doesn’t exist
                try message.write(to: logFilePath, atomically: true, encoding: .utf8)
            }
        } catch let writeError {
            log(message: "Error writing to logs.txt: \(writeError.localizedDescription)", type: .error)
        }
    }
    
    public func log(message: String, type: LogType? = nil, function: String = #function, file: String = #file, line: Int = #line) {
        let logger = OSLog(subsystem: subsystem, category: "\(file) -> \(function)")
        
        var emoji: String
        switch type {
        case .success:
            emoji = "✅"
            os_log("%{public}@", log: logger, type: .info, message)
        case .info:
            emoji = "ℹ️"
            os_log("%{public}@", log: logger, type: .info, message)
        case .debug:
            emoji = "🐛"
            os_log("%{public}@", log: logger, type: .debug, message)
        case .trace:
            emoji = "🔍"
            os_log("%{public}@", log: logger, type: .debug, message)
        case .warning:
            emoji = "⚠️"
            os_log("%{public}@", log: logger, type: .default, message)
        case .error:
            emoji = "❌"
            os_log("%{public}@", log: logger, type: .error, message)
        case .critical:
            emoji = "🔥"
            os_log("%{public}@", log: logger, type: .fault, message)
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
}

// MARK: - Helper Function
private func getDocumentsDirectory() -> URL {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    return paths[0]
}