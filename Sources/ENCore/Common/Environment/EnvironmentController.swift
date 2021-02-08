/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

/// @mockable
protocol EnvironmentControlling {
    var isiOS12: Bool { get }
    var isiOS13orHigher: Bool { get }
    var isiOS137orHigher: Bool { get }
    var gaenRateLimitingType: GAENRateLimitingType { get }
    var appVersion: String? { get }
    var supportsExposureNotification: Bool { get }
    var appSupportsiOSversion: Bool { get }
}

enum GAENRateLimitingType {

    // The GAEN API has a limit of 15 calls to the `detectExposure` function
    case dailyLimit

    // The GAEN API has a limit of 15 processed keyset files per day
    case fileLimit
}

enum SupportedENAPIVersion {
    case version2
    case version1
    case unsupported
}

class EnvironmentController: EnvironmentControlling {

    var appSupportsiOSversion: Bool {
        if #available(iOS 13.7, *) {
            return true
        } else if #available(iOS 13, *) {
            return false
        } else if #available(iOS 12.5, *) {
            return true
        } else {
            return false
        }
    }

    var supportsExposureNotification: Bool {
        return maximumSupportedExposureNotificationVersion != .unsupported
    }

    var isiOS12: Bool {
        return !isiOS13orHigher
    }

    var isiOS13orHigher: Bool {
        if #available(iOS 13, *) {
            return true
        } else {
            return false
        }
    }

    var isiOS137orHigher: Bool {
        if #available(iOS 13.7, *) {
            return true
        } else {
            return false
        }
    }

    var gaenRateLimitingType: GAENRateLimitingType {
        if maximumSupportedExposureNotificationVersion == .version1 {
            return .fileLimit
        }

        return .dailyLimit
    }

    var appVersion: String? {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    }

    private var maximumSupportedExposureNotificationVersion: SupportedENAPIVersion {
        if #available(iOS 13.7, *) {
            return .version2
        } else if #available(iOS 13.5, *) {
            return .version1
        } else if ENManagerIsAvailable() {
            return .version2
        } else {
            return .unsupported
        }
    }

    fileprivate func ENManagerIsAvailable() -> Bool {
        return NSClassFromString("ENManager") != nil
    }
}
