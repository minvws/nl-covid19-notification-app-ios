/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import Foundation
import ExposureNotification

enum ExposureManagerStatus {
    case notAvailable
    case updateOS
    case active
}
/// @mockable
protocol ExposureManaging {
    
}

@available(iOS 13.5, *)
class ExposureManager: ExposureManaging {
    
    private let manager = ENManager()

    init() {
        manager.activate { _ in
            if ENManager.authorizationStatus == .authorized && !self.manager.exposureNotificationEnabled {
                self.manager.setExposureNotificationEnabled(true) { _ in
                    // No error handling for attempts to enable on launch
                }
            }
        }
    }
}
