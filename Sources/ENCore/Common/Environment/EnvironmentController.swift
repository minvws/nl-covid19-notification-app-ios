/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

/// @mockable
protocol EnvironmentControlling {
    var isiOS137orHigher: Bool { get }
    var isiOS136orHigher: Bool { get }
    var appVersion: String? { get }
}

class EnvironmentController: EnvironmentControlling {
    var isiOS137orHigher: Bool {
        if #available(iOS 13.7, *) {
            return true
        } else {
            return false
        }
    }

    var isiOS136orHigher: Bool {
        if #available(iOS 13.6, *) {
            return true
        } else {
            return false
        }
    }

    var appVersion: String? {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    }
}
