//
//  Logging.swift
//  EN
//
//  Created by Cameron Mc Gorian on 01/07/2020.
//

import Foundation
import CocoaLumberjackSwift

protocol Logging {
    var loggingCategory: String { get }

    func logDebug(_ message: String, function: StaticString, file: StaticString, line: UInt)
    func logInfo(_ message: String, function: StaticString, file: StaticString, line: UInt)
    func logWarning(_ message: String, function: StaticString, file: StaticString, line: UInt)
    func logError(_ message: String, function: StaticString, file: StaticString, line: UInt)
}

extension Logging {

    /// The category with which the class that conforms to the `Logging`-protocol is logging.
    var loggingCategory: String {
        return "default"
    }

    func logDebug(_ message: String, function: StaticString = #function, file: StaticString = #file, line: UInt = #line) {
        DDLogDebug("🐞 \(message)", file: file, function: function, line: line, tag: loggingCategory)
    }
    
    func logInfo(_ message: String, function: StaticString = #function, file: StaticString = #file, line: UInt = #line) {
        DDLogInfo("📋 \(message)", file: file, function: function, line: line, tag: loggingCategory)
    }
    
    func logWarning(_ message: String, function: StaticString = #function, file: StaticString = #file, line: UInt = #line) {
        DDLogWarn("❗️ \(message)", file: file, function: function, line: line, tag: loggingCategory)
    }
    
    func logError(_ message: String, function: StaticString = #function, file: StaticString = #file, line: UInt = #line) {
        DDLogError("🔥 \(message)", file: file, function: function, line: line, tag: loggingCategory)
    }
}

final class LogHandler: Logging {
    
    static func setup() {
        dynamicLogLevel = .debug
        
        DDLog.add(DDOSLogger.sharedInstance) // Uses os_log

        let fileLogger: DDFileLogger = DDFileLogger() // File Logger
        fileLogger.rollingFrequency = 60 * 60 * 24 // 24 hours
        fileLogger.logFileManager.maximumNumberOfLogFiles = 7
        DDLog.add(fileLogger)
    }
    
    static func logFiles() -> [URL] {
        guard let fileLogger = DDLog.allLoggers.filter({ $0 is DDFileLogger }).first as? DDFileLogger else {
            print("File Logger not Found")
            return []
        }
        return fileLogger.logFileManager.sortedLogFilePaths.compactMap({ URL(fileURLWithPath: $0) })
    }
}
