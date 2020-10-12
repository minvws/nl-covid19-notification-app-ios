/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

class FeatureFlags {

    struct FeatureFlag {
        let description: String
        var enabled: Bool
    }

    static var exposureNotificationExplanation = FeatureFlag(description: "iOS 13.7+ EN setting instructions screen", enabled: false)
}
