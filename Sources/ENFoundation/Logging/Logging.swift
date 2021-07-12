/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import CocoaLumberjackSwift
import Foundation

public protocol Logging {
    var loggingCategory: String { get }

    func logDebug(_ message: String, function: StaticString, file: StaticString, line: UInt)
    func logInfo(_ message: String, function: StaticString, file: StaticString, line: UInt)
    func logWarning(_ message: String, function: StaticString, file: StaticString, line: UInt)
    func logError(_ message: String, function: StaticString, file: StaticString, line: UInt)
}

public extension Logging {

    /// The category with which the class that conforms to the `Logging`-protocol is logging.
    var loggingCategory: String {
        return "default"
    }

    func logDebug(_ message: String, function: StaticString = #function, file: StaticString = #file, line: UInt = #line) {
        DDLogDebug(message, file: file, function: function, line: line, tag: loggingCategory)
    }

    func logInfo(_ message: String, function: StaticString = #function, file: StaticString = #file, line: UInt = #line) {
        DDLogInfo(message, file: file, function: function, line: line, tag: loggingCategory)
    }

    func logWarning(_ message: String, function: StaticString = #function, file: StaticString = #file, line: UInt = #line) {
        DDLogWarn(message, file: file, function: function, line: line, tag: loggingCategory)
    }

    func logError(_ message: String, function: StaticString = #function, file: StaticString = #file, line: UInt = #line) {
        DDLogError(message, file: file, function: function, line: line, tag: loggingCategory)
    }
    
    func logTrace(function: StaticString = #function, file: StaticString = #file, line: UInt = #line) {
        DDLogDebug("Trace: \(file):\(function):\(line)")
    }
}

public final class LogHandler: Logging {

    public static var isSetup = false

    /// Can be called multiple times, will only setup once
    public static func setup() {
        guard !isSetup else {
            DDLogDebug("🐞 Logging has already been setup before", file: #file, function: #function, line: #line, tag: "default")

            return
        }

        isSetup = true

        let level = "debug" // Bundle.main.infoDictionary?["LOG_LEVEL"] as? String ?? "debug"

        switch level {
        case "debug":
            dynamicLogLevel = .debug
        case "info":
            dynamicLogLevel = .info
        case "warn":
            dynamicLogLevel = .warning
        case "error":
            dynamicLogLevel = .error
        case "none":
            dynamicLogLevel = .off
        default:
            dynamicLogLevel = .off
        }

        let osLogger = DDOSLogger.sharedInstance
        osLogger.logFormatter = LogFormatter(showPrefix: false)
        DDLog.add(osLogger) // Uses os_log

        let fileLogger: DDFileLogger = DDFileLogger() // File Logger
        fileLogger.rollingFrequency = 60 * 60 * 24 // 24 hours
        fileLogger.logFileManager.maximumNumberOfLogFiles = 7
        fileLogger.logFormatter = LogFormatter(showPrefix: true)
        DDLog.add(fileLogger)

        DDLogDebug("🐞 Logging has been setup", file: #file, function: #function, line: #line, tag: "default")
    }

    public static func logFiles() -> [URL] {
        guard let fileLogger = DDLog.allLoggers.filter({ $0 is DDFileLogger }).first as? DDFileLogger else {
            #if DEBUG
                assertionFailure("File Logger Not Found")
            #endif
            print("File Logger not Found")
            return []
        }
        return fileLogger.logFileManager.sortedLogFilePaths.compactMap { URL(fileURLWithPath: $0) }
    }
}
