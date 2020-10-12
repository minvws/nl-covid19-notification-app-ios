/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

/// @mockable
protocol EnvironmentControlling {
    var isExtendedENSettingsAvailable: Bool { get }
}

class EnvironmentController: EnvironmentControlling {
    var isExtendedENSettingsAvailable: Bool {
        if #available(iOS 13.7, *) {
            return true
        } else {
            return false
        }
    }
}
