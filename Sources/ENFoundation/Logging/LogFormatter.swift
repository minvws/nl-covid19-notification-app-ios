/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import CocoaLumberjack
import Foundation

public class LogFormatter: NSObject, DDLogFormatter {

    private let dateFormatter = DateFormatter()
    private let showPrefix: Bool

    init(showPrefix: Bool) {
        self.showPrefix = showPrefix

        super.init()

        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss:SSS"
    }

    // MARK: - DDLogFormatter

    public func format(message logMessage: DDLogMessage) -> String? {

        let logIcon: String
        switch logMessage.flag {
        case DDLogFlag.error:
            logIcon = "🔥"
        case DDLogFlag.warning:
            logIcon = "❗️"
        case DDLogFlag.info:
            logIcon = "📋"
        case DDLogFlag.debug:
            logIcon = "🐞"
        default:
            logIcon = ""
        }

        if showPrefix {
            let dateTime = dateFormatter.string(from: logMessage.timestamp)
            return "\(dateTime) \(logIcon) \(logMessage.message)"
        } else {
            return "\(logIcon) \(logMessage.message)"
        }
    }
}
